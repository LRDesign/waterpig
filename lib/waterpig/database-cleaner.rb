require 'database_cleaner'

RSpec.configure do |config|
  #config.use_transactional_fixtures = false
  DatabaseCleaner.strategy = :transaction

  config.add_setting :waterpig_truncation_types, :default => [:feature]
  config.add_setting :waterpig_exclude_seeds_types, :default => []
  config.add_setting :waterpig_database_truncation_config, :default => {:except => %w[spatial_ref_sys]}
  config.add_setting :waterpig_db_seeds, :default => 'db/seeds.rb'

  config.before :all, :type => proc{ |value| config.waterpig_truncation_types.include?(value)} do
    Rails.application.config.action_dispatch.show_exceptions = true
    DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
    unless config.waterpig_exclude_seeds_types.include?(self.class.metadata[:type])
      if config.waterpig_db_seeds?
        load config.waterpig_db_seeds
      end
    end
  end

  config.after :all, :type => proc{ |value| config.waterpig_truncation_types.include?(value)} do
    DatabaseCleaner.clean_with :truncation, config.waterpig_database_truncation_config
    if config.waterpig_db_seeds?
      load config.waterpig_db_seeds
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
