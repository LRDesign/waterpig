require 'database_cleaner'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  DatabaseCleaner.strategy = :transaction

  config.add_setting :waterpig_truncation_types, :default => [:feature]
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

  config.before :all, :type => proc{ |value| config.waterpig_truncation_types.include?(value)} do
    with_showing(true, false) do
      DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
      unless config.waterpig_exclude_seeds_types.include?(self.class.metadata[:type])
        if config.waterpig_db_seeds?
          load config.waterpig_db_seeds
        end
      end
    end
  end

  config.after :all, :type => proc{ |value| config.waterpig_truncation_types.include?(value)} do
    with_showing(true, true) do
      Rails.application.config.action_dispatch.show_detailed_exceptions = true
      DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
      if config.waterpig_db_seeds?
        load config.waterpig_db_seeds
      end
    end
  end

  config.before :each, :type => proc{ |value| !config.waterpig_truncation_types.include?(value) } do
    DatabaseCleaner.start
  end

  config.after :each, :type => proc{ |value| !config.waterpig_truncation_types.include?(value) } do
    DatabaseCleaner.clean
  end

  config.before :suite do
    DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
    if config.waterpig_db_seeds?
      load config.waterpig_db_seeds
    end
  end
end
