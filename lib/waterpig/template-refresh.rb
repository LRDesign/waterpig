module Waterpig


  # Tool to handle migrations and rebuilds on a test template database.  For
  # explanation of what the test templated DB is and how it's used, see the
  # README.
  #
  # This should auto detect any needed migrations in that database. However, it
  # does not detect changes to db/seeds.rb, so if you have changed seeds
  # without adding a DB migration, you will need to drop and rebuild the
  # test_template.
  module TemplateRefresh
    extend self

    def load_config
      ActiveRecord::Base.configurations       = ActiveRecord::Tasks::DatabaseTasks.database_configuration || {}
      ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths
    end

    def purge_env(env)
      ActiveRecord::Tasks::DatabaseTasks.purge(config_for(env))
    end

    def with_temporary_connection(env)
      begin
        should_reconnect = ActiveRecord::Base.connection_pool.active_connection?

        yield
      ensure
        if should_reconnect
          ActiveRecord::Base.establish_connection(config_for(ActiveRecord::Tasks::DatabaseTasks.env))
        end
      end
    end

    #Assumes schema_format == ruby
    def load_schema(env)
      ActiveRecord::Schema.verbose = false
      ActiveRecord::Tasks::DatabaseTasks.load_schema_for config_for(env), :ruby, ENV['SCHEMA']
    end

    def load_seed
      ActiveRecord::Tasks::DatabaseTasks.load_seed
      # load('spec/test_seeds.rb')
    end

    Base = ActiveRecord::Base

    def config_for(env)
      ActiveRecord::Base.configurations.fetch(env.to_s)
    end

    def connection_for(env)
      ActiveRecord::Base.establish_connection(env).connection
    end

    def if_needs_migration(env)
      if ActiveRecord::Migrator.needs_migration?(connection_for(env))
        begin
          current_config = Base.connection_config
          Base.clear_all_connections!

          yield

        ensure
          Base.establish_connection(current_config)

          ActiveRecord::Migration.check_pending!
        end
      end
    end

    def ensure_created(env)
      ActiveRecord::Base.establish_connection(env).connection
    rescue ActiveRecord::NoDatabaseError
      ActiveRecord::Tasks::DatabaseTasks.create(config_for(env))
    end


    def load_if_pending!(env)
      ensure_created(env)
      if_needs_migration(env) do
        puts "Refreshing unmigrated test env: #{env}"
        purge_env(env)
        with_temporary_connection(env) do
          load_schema(env)
          load_seed
        end
      end
    end

    def commandeer_database(env)
      config = config_for(env)
      connection_for(env).select_all(
        "select pid, pg_terminate_backend(pid) " +
        "from pg_stat_activity where datname='#{config['database']}' AND state='idle';")
    end

    def refresh_database(env)
      Rails.logger.fatal("Resetting test DB...")
      config = config_for(env)

      tasks = ActiveRecord::Tasks::PostgreSQLDatabaseTasks.new(config)

      start = Time.now
      Rails.logger.fatal("Dropping")
      begin
        tasks.drop
      end
      Rails.logger.fatal("Creating")
      begin
        tasks.create
      end
      message = "Test database recopied in #{Time.now - start}s"
      #puts message
      Rails.logger.fatal(message)
    end
  end
end
