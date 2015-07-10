require 'database_cleaner'

require 'waterpig/template-refresh'
require 'waterpig/request-wait-middleware'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  DatabaseCleaner.strategy = :transaction

  config.add_setting :waterpig_exclude_cleaning_key, :default => :manual_database_cleaning
  config.add_setting :waterpig_explicit_cleaning_method_key, :default => :clean_with

  config.add_setting :waterpig_database_reset_method, :default => :truncation
  config.add_setting :waterpig_truncation_types, :default => [:feature]
  config.add_setting :waterpig_reset_types, :default => [:feature]

  config.add_setting :waterpig_skip_cleaning_types, :default => []
  config.add_setting :waterpig_exclude_seeds_types, :default => []

  config.add_setting :waterpig_database_truncation_config, :default => {:except => %w[spatial_ref_sys]}
  config.add_setting :waterpig_db_seeds, :default => 'db/seeds.rb'

  config.add_setting :waterpig_test_database_config, :default => :test
  config.add_setting :waterpig_test_template_database_config, :default => :test_template

  def with_showing(show, detailed)
    begin
      old_show, old_show_detailed =
        Rails.application.config.action_dispatch.show_exceptions,
        Rails.application.config.action_dispatch.show_detailed_exceptions
      Rails.application.config.action_dispatch.show_exceptions = show
      Rails.application.config.action_dispatch.show_detailed_exceptions = detailed
      yield
    ensure
      Rails.application.config.action_dispatch.show_exceptions = old_show
      Rails.application.config.action_dispatch.show_detailed_exceptions = old_show_detailed
    end
  end

  def cleaning_policy(config, metadata)
    return :no_clean if metadata[config.waterpig_exclude_cleaning_key]
    unless (explicit_method = metadata[config.waterpig_explicit_cleaning_method_key]).nil?
      if explicit_method == :reset
        return config.waterpig_database_reset_method
      else
        return explicit_method
      end
    end

    return :no_clean if config.waterpig_skip_cleaning_types.include?(metadata[:type])

    if config.waterpig_database_reset_method == :truncation
      return :truncate if config.waterpig_truncation_types.include?(metadata[:type])
      return :truncate if config.waterpig_reset_types.include?(metadata[:type])
    else
      return :refresh if config.waterpig_reset_types.include?(metadata[:type])
    end
    return :transaction
  end

  def use_refresh?(config, metadata)
    cleaning_policy(config, metadata) == :refresh
  end

  def use_truncate?(config, metadata)
    cleaning_policy(config, metadata) == :truncate
  end

  def use_transaction?(config, metadata)
    cleaning_policy(config, metadata) == :transaction
  end

  last_type = nil

  config.after(:all) do
    last_type = self.class.metadata[:type].to_s
  end

  config.before(:all, :description => proc{|value, metadata| use_refresh?(config, metadata)}) do
    Waterpig::RequestWaitMiddleware.wait_for_idle do
      Waterpig::TemplateRefresh.refresh_database(config.waterpig_test_database_config)
    end
  end

  #Before the first group following a refresh-group, refresh again.
  #Faster than refreshing before and after all the feature groups
  config.before(:all, :description => proc{|value, metadata| !use_refresh?(config, metadata) }) do
    if config.waterpig_reset_types.include?(last_type)
      Waterpig::TemplateRefresh.refresh_database(config.waterpig_test_database_config)
    end
  end

  config.before :all, :description => proc{ |value, metadata| use_truncate?(config, metadata) } do
    with_showing(true, false) do
      DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
      unless config.waterpig_exclude_seeds_types.include?(self.class.metadata[:type])
        if config.waterpig_db_seeds?
          load config.waterpig_db_seeds
        end
      end
    end
  end

  config.after :all, :description => proc{ |value, metadata| use_truncate?(config, metadata) } do
    with_showing(true, true) do
      DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
      if config.waterpig_db_seeds?
        load config.waterpig_db_seeds
      end
    end
  end

  config.before :each, :description => proc{ |value, metadata| use_transaction?(config, metadata) } do
    DatabaseCleaner.start
  end

  config.after :each, :description => proc{ |value, metadata| use_transaction?(config, metadata) } do
    DatabaseCleaner.clean
  end

  config.before :suite do
    if config.waterpig_database_reset_method == :truncation
      DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
      if config.waterpig_db_seeds?
        load config.waterpig_db_seeds
      end
    elsif config.waterpig_database_reset_method == :refresh
      Waterpig::TemplateRefresh.load_if_pending!(config.waterpig_test_template_database_config)
      Waterpig::TemplateRefresh.commandeer_database(config.waterpig_test_database_config)
      Waterpig::TemplateRefresh.refresh_database(config.waterpig_test_database_config)
    else
      warn "Waterpig: Unknown database reset method: #{config.waterpig_database_reset_method}"
    end
  end
end
