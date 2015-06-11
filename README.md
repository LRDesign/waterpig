Waterpig
========

A collection of helpers for Capybara, collected over several years by Logical Reality Design.

Selecting A Browser Driver
--------------------------

You can set JS and non-JS capybara drivers with either environment variables or your rspec config.  The
two currently supported drivers are poltergeist_debug (Poltergeist with remote debugging enabled) 
and selenium_chrome.  If none is specified, waterpig will try to configure poltergeist_debug by default.

Mostly one cares about drivers when :js => true in capybara specs, in which case capybara_js_driver is
the setting you care about.

At the command line:
    CAPYBARA_JS_DRIVER=poltergeist_debug rspec spec/features/my_cool_spec.rb
    CAPYBARA_JS_DRIVER=selenium_chrome rspec spec/features/my_cool_spec.rb

In your rspec config
    RSpec.configure do |config|
      config.capybara_js_driver = :selenium_chrome
    end

Browser Snapshotting
--------------------

If you are also using the rspec-steps gem and poltergeist, Waterpig's Autosnap feature can generate screenshots 
of the browser at the beginning of each step, to give you intelligence on the test in the middle of a user story.  
To use it simply set the environment variable WATERPIG_AUTOSNAP, for example:

    WATERPIG_AUTOSNAP=true rspec spec/features/my_cool_spec.rb

Or set the rspec config waterpig_autosnap? to true in your config.

Screenshots will be emitted into tmp/, with a subdirectory named for each spec and a numbered file for each step.
To change the screenshot destination, set waterpig_
   
Browser Console Logging
-----------------------

The Waterpig::BrowserConsoleLogger class can execute a remote call to console.history() in your browser to retrieve   
the contents of the browser console, and log it to file.  This is extremely useful for debugging front-end issues
during integration specs.  

For browser console logging to work, the console.history() method must have already been defined in your browser.  
This must be handled separately, see the console history injector in Xing for an example.

To turn on browser console logging:


At the command line:
    LOG_BROWSER_CONSOLE=true rspec spec/features/my_cool_spec.rb

In your rspec config
    RSpec.configure do |config|
      config.waterpig_log_browser_console = true
    end


Blocking Spec Cleanup For Browser Requests
------------------------------------------

Much suffering is caused when rspec and Capybara clean up after a spec while a request is still being
processed. Typically, the database fixtures are reset by DatabaseCleaner because rspec thinks the example
is complete, but then something fails in Rails when an expected database record is absent.  This can cause
mysterious intermittant, timing-related failures in specs.

To fix this, install Waterpig::RackRequestWait as a middleware and configure your end-to-end tests to block 
on Waterpig::RackRequestWait.wait_for_idle(), as follows:

In config/environments/test.rb
    Rails.application.configure do
      config.middleware.unshift Waterpig::RackRequestWait
    end

In your rspec config, wrap your database cleanup command in a call to wait_for_idle().  Assuming all your
end-to-end tests have the metadata :type => :feature, you could:

    RSpec.configure do |config|

      config.before(:all, :type => :feature) do
        Waterpig::RackRequestWait.wait_for_idle do 
          DatabaseCleaner.clean(:truncation)
        end
      end
   

Rebuilding the Test Database from a Template
--------------------------------------------

If you are using DatabaseCleaner or other truncation method, cleaning your database between tests can be slow,
particularly if your database has a lot of setup in seeds.rb.  Waterpig's solution is to use a second, test
template database, that contains a cleaned and seeded database, and to leverage PostgreSQL's database
template feature to re-initialize the test database from that template.

In your database.yml, configure the test database with a template: setting, and  an additional template DB.

    test:
      adapter: postgresql
      database: my_app_test
      template: my_app_test_template

    test_template:
      adapter: postgresql
      database: my_app_test_template

Create the template database at the command line the same as any other Rails DB, treat "test_template" as a 
Rails environment for this purpose:

    > RAILS_ENV=test_template bundle exec rake db:create

NOTE:  the test template maintainer code can detect new migrations, but cannot detect changes to db/seeds.rb. If
you have changed your seeds file without adding a new migration, your test template will not have the new seeds 
until you drop and rebuild it.  You can do that with:


    > RAILS_ENV=test_template bundle exec rake db:drop db:create
