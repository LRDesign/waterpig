require 'database_cleaner'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  DatabaseCleaner.strategy = :transaction

  config.add_setting :waterpig_exclude_cleaning_key, :default => :manual_database_cleaning
  config.add_setting :waterpig_truncation_types, :default => [:feature]
  config.add_setting :waterpig_skip_cleaning_types, :default => []
  config.add_setting :waterpig_exclude_seeds_types, :default => []
  config.add_setting :waterpig_database_truncation_config, :default => {:except => %w[spatial_ref_sys]}
  config.add_setting :waterpig_db_seeds, :default => 'db/seeds.rb'

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

  def use_truncate?(config, metadata)
    return false if metadata[config.waterpig_exclude_cleaning_key]
    return false if config.waterpig_skip_cleaning_types.include?(metadata[:type])
    return false unless config.waterpig_truncation_types.include?(metadata[:type])
    return true
  end

  def use_transaction?(config, metadata)
    return false if metadata[config.waterpig_exclude_cleaning_key]
    return false if use_truncate?(config, metadata)
    return false if config.waterpig_skip_cleaning_types.include?(metadata[:type])
    return true
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
      Rails.application.config.action_dispatch.show_detailed_exceptions = true
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
    DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
    if config.waterpig_db_seeds?
      load config.waterpig_db_seeds
    end
  end
end
