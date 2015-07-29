Waterpig
========

A collection of helpers for Rails integration testing with Capybara, RSpec,
RSpec-Steps, and DatabaseCleaner collected over several years by Logical
Reality Design.

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

# Database Cleaning

Because database cleaning is sich a tricky problem, Waterpig tries to handle it
in the best way possible. There are several configuration knobs to adjust if
needed.

## Transactions

Most test types, Waterpig leans on rspec-rails's transactional fixtures, so
there's a BEGIN at the beginning of a test and ROLLBACK at the end. This is
almost always what you want - it's fast and correct.

## Resets

For feature specs (i.e. when you're pointing Capybara at a test server) and
other kinds of tests, transactional fixtures doesn't do the job: the test
server and the test itself run in different threads, so they have different
connections to the database and therefore don't see "inside" each other's
transactions. If you try to change the database using browser actions and then
check the database in the tests, you're going to have a (mysteriously) bad
time.

To cope with this case, as well as situations where you really do want to test
whole-database changes, Waterpig provides tools to "reset" the database to a
pristine state.


The first thing to know is how to turn on resets for a set of tests. The
easiest is to hook into RSpec's existing metadata. Most spec groups are marked
with a :type field (it used to be automatic, but there remain features of
rspec-rails that depend on the type of the tests)

Simply add this to your RSpec.configuration block (in e.g. `spec_helper.rb`)
```
config.waterpig_reset_types = [:feature]
```
That's actually the default, so in most projects you won't even have to change
anything.

Waterpig actually uses one of two methods to do DB resets, "truncation" or
"refresh." They each have their tradeoffs, so it's worth discussing them.

### Truncation

The simplest cleaning strategy is this: truncate all the tables in the database
between tests. It's okay for speed, but the real hangup is when you've got a
complex seeds.rb - if, for instance, you need to ingest a ZIP code database.
Apart from being slow, truncation is really reliable

### Refresh

If you're using PostgreSQL, Waterpig has an alternative method for doing resets
that can bemuch faster called "refresh." You need to configure a new
ActiveRecord database configuration, exactly like your existing `:test` config,
called `:test_template.` It needs its own database name. Then add the name of
the `:test_template` database to your `:test` config under a key called
`template.` In the end, the things you've added to `database.yml` should look
something like:

```yaml
test:
  adapter: postgresql
  database: my_app_test
  template: my_app_test_template

test_template:
  adapter: postgresql
  database: my_app_test_template
```

Then, in `spec_helper.rb` add:
```ruby
RSpec.configure do |config|
  config.waterpig_reset_method = :refresh
end
```

Here's how reset works: Waterpig will make sure that the `test_template`
database exists, and if it needs to be migrated then it will be migrated and
seeded. Then, before tests that need to be `reset` it'll drop the test database
and recreate it, using test_template as the PostgreSQL template database - the
schema and data from a migrated and seeded database. This happens very quickly.

One big warning here: Waterpig will create `test_template` if it's missing or
recreate it if its migrations are behind, but not if it isn't up to date on
`db/seeds.rb`. If you change seeds, you'll need to
```
> RAILS_ENV=test_template bundle exec rake db:drop
```
or your specs will fail mysteriously. It's this
shortcoming that prevents us making `:refresh` the default reset method.

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

If you need to change the database config names, you can:
```ruby
RSpec.configure do |config|
  config.waterpig_test_database_config = :just_checking
  config.waterpig_test_template_database_config = :just_checking_like_this
end
```

## Do What I Say

If you need to set up tests so that they don't get cleaned, you can put their
type into `config.waterpig_skip_cleaning_types` which is an Array.

If you want to force a single example or group of examples not to be cleaned,
you can do like:

```ruby
RSpec.describe "these tests should not be cleaned", :manual_database_cleaning do
  #...
end
```

If you want to force a particular cleaning method:
```ruby
RSpec.describe "these tests have weird requirements", :clean_with => :reset do
  #...
end
```

The metadata keys above are configurable at
`config.waterpig_exclude_cleaning_key` and
`config.waterpig_explicit_cleaning_method_key`


## Config Reference

Config Name                                   | Purpose                                                                             | Values                                                 | Default Value
---:                                          | :----                                                                               | :----
config.waterpig_exclude_cleaning_key          | The name of the metadata key to mark test that should not be cleaned                | Boolean                                                | :manual_database_cleaning
config.waterpig_explicit_cleaning_method_key  | The name of the metadata key to force a particular cleaning method                  | :reset, :refresh, :truncate, :transaction, :dont_clean | :clean_with
config.waterpig_database_reset_method         | How "reset" cleaning is performed                                                   | :refresh, :truncate                                    | :truncation
config.waterpig_reset_types                   | RSpec test types that should be reset (truncated or refreshed)                      | Array | [:feature]
config.waterpig_skip_cleaning_types           | RSpec test types that shouldn't be cleaned                                          | Array                                                  | []
config.waterpig_exclude_seeds_types           | RSpec test types where db seeds shouldn't be loaded after truncating                | Array                                                  | []
config.waterpig_truncation_types              | RSpec test types that should be truncated (deprecated, prefer waterpig_reset_types) | Array | [:feature]
config.waterpig_database_truncation_config    | DatabaseCleaner configuration for truncating                                        | Hash                                                   | {:except => %w[spatial_ref_sys]}
config.waterpig_db_seeds                      | Path to the db_seeds file to use when truncating                                    | String | 'db/seeds.rb'
config.waterpig_test_database_config          | The name of the test database config for refreshing                                 | Symbol                                                 | :test
config.waterpig_test_template_database_config | The name of the template test database config for refreshing                        | Symbol                                                 | :test_template


# Experimental Features

These are features of Waterpig that are being used in real projects, but for
which the interfaces in Waterpig haven't been designed yet.

## Mobile browser emulation

Currently in bleeding edge beta are registered drivers for Capybara: mobile_chrome_ios and mobile_chrome_android. Try them against your codebase with

```
CAPYBARA_DRIVER=mobile_chrome_android CAPYBARA_JS_DRIVER=mobile_chrome_android rspec spec
```


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
