Waterpig
========

A collection of helpers for Capybara, collected over several years by Logical Reality Design.

Selecting A Browser Driver
--------------------------

You can set JS and non-JS capybara drivers with either environment variables or your rspec config.  The
two currently supported drivers are poltergeist_debug (Poltergeist with remote debugging enabled)
and selenium_chrome.  If none is specified, waterpig will try to configure poltergeist_debug by default.

Mostly one cares about drivers when `:js => true` in capybara specs, in which
case `capybara_js_driver` is the setting you care about.

At the command line:
```
CAPYBARA_JS_DRIVER=poltergeist_debug rspec spec/features/my_cool_spec.rb
CAPYBARA_JS_DRIVER=selenium_chrome rspec spec/features/my_cool_spec.rb
```

In your rspec config

```ruby
RSpec.configure do |config|
  config.capybara_js_driver = :selenium_chrome
end
```

Browser Snapshotting
--------------------

If you are also using the rspec-steps gem and poltergeist, Waterpig's Autosnap feature can generate screenshots
of the browser at the beginning of each step, to give you intelligence on the test in the middle of a user story.
To use it simply set the environment variable WATERPIG_AUTOSNAP, for example:

```
WATERPIG_AUTOSNAP=true rspec spec/features/my_cool_spec.rb
```

Or set `config.waterpig_autosnap?` to true in your RSpec config.

Screenshots will be emitted into `tmp/`, with a subdirectory named for each
spec and a numbered file for each step.

Browser Console Logging
-----------------------

The Waterpig::BrowserConsoleLogger class can execute a remote call to console.history() in your browser to retrieve
the contents of the browser console, and log it to file.  This is extremely useful for debugging front-end issues
during integration specs.

For browser console logging to work, the console.history() method must have already been defined in your browser.
This must be handled separately, see the console history injector in Xing for an example.

To turn on browser console logging:

At the command line:
```
LOG_BROWSER_CONSOLE=true rspec spec/features/my_cool_spec.rb
```

In your rspec config
```ruby
RSpec.configure do |config|
  config.waterpig_log_browser_console = true
end
```

# Experimental Features

These are features of Waterpig that are being used in real projects, but for
which the interfaces in Waterpig haven't been designed yet.

## Blocking Spec Cleanup For Browser Requests

Much suffering is caused when rspec and Capybara clean up after a spec while a request is still being
processed. Typically, the database fixtures are reset by DatabaseCleaner because rspec thinks the example
is complete, but then something fails in Rails when an expected database record is absent.  This can cause
mysterious intermittant, timing-related failures in specs.

To fix this, install `RequestWaitMiddleware` as a middleware and configure your
end-to-end tests to block on `Waterpig::RequestWaitMiddleware.wait_for_idle()`,
as follows:

In config/environments/test.rb
```
Rails.application.configure do
  config.middleware.unshift Waterpig::RequestWaitMiddleware
end
```

In your rspec config, wrap your (e.g.) database cleanup command in a call to
`wait_for_idle()`.  Assuming all your end-to-end tests have the metadata `:type
=> :feature`, you could:

```ruby
RSpec.configure do |config|

  config.before(:all, :type => :feature) do
    Waterpig::RequestWaitMiddleware.wait_for_idle do
      DatabaseCleaner.clean(:truncation)
    end
  end
end
```


## Rebuilding the Test Database from a Template

If you are using DatabaseCleaner or other truncation method, cleaning your database between tests can be slow,
particularly if your database has a lot of setup in seeds.rb.  Waterpig's solution is to use a second, test
template database, that contains a cleaned and seeded database, and to leverage PostgreSQL's database
template feature to re-initialize the test database from that template.

In your database.yml, configure the test database with a template: setting, and  an additional template DB.

```yaml
test:
  adapter: postgresql
  database: my_app_test
  template: my_app_test_template

test_template:
  adapter: postgresql
  database: my_app_test_template
```

That's it! Waterpig will create the template database if it doesn't exist.

NOTE:  the test template maintainer code can detect new migrations, but cannot detect changes to db/seeds.rb. If
you have changed your seeds file without adding a new migration, your test template will not have the new seeds
until you drop and rebuild it.  You can do that with:

```
> RAILS_ENV=test_template bundle exec rake db:drop
```

Or, you can add a this to `lib/tasks/databases.rb` (possibly a new file) in
your Rails project:

```ruby
namespace :db do
  task :seed do
    ActiveRecord::DatabaseTasks.drop_current(:test_template)
    ActiveRecord::DatabaseTasks.create_current(:test_template)
  end
end
```

which will automate the process whenever you db:seed development.


## How to Use

The intention is to have Waterpig set this all up when requested. There are
some challenges around when to do which thing however, and we wanted to roll
this out.

For the moment, you can do this:

```ruby
require 'waterpig/template-refresh'
require 'waterpig/request-wait-middleware'

RSpec.configure do |config|
  config.waterpig_skip_cleaning_types = [:feature]

  config.prepend_before(:suite) do
    Waterpig::TemplateRefresh.load_if_pending!(:test_template)
    Waterpig::TemplateRefresh.commandeer_database(:test)
  end

  rebuild_types = ["feature"]

  last_type = nil

  config.after(:all) do
    last_type = self.class.metadata[:type].to_s
  end

  config.before(:all, :type => proc{|type| rebuild_types.include?(type.to_s)}) do
    Waterpig::RequestWaitMiddleware.wait_for_idle do
      Waterpig::TemplateRefresh.refresh_database(:test)
    end
  end

  config.before(:all, :type => proc{|type| !rebuild_types.include?(type.to_s)}) do
    if rebuild_types.include?(last_type)
      Waterpig::TemplateRefresh.refresh_database(:test)
    end
  end
end
```
