require 'capybara/rspec'
require 'stringio'
require 'rspec-steps'

require 'waterpig/poltergeist'
require 'waterpig/selenium_chrome'
require 'waterpig/warning-suppressor'
require 'waterpig/save-and-open-on-fail'
require 'waterpig/ckeditor-tools'
require 'waterpig/tinymce-tools'
require 'waterpig/browser-tools'
require 'waterpig/browser-size'
require 'waterpig/browser-console-logger'
require 'waterpig/snap-step'

module Waterpig
  def self.pick_capybara_driver(configured)
    return configured.to_sym if configured
    [:poltergeist_debug, :selenium_chrome].each do |candidate|
      return candidate if Capybara.drivers.has_key? candidate
    end
  end

  module ExampleLogger
    def self.included(group)
      group.before :each do |example|
        Rails.logger.fatal do
          "Beginning #{example.full_description} (at #{example.location})"
        end
      end

      group.after :each do |example|
        Rails.logger.fatal do
          "Finished #{example.full_description} (at #{example.location})"
        end
      end

      group.before :step do |example|
        Rails.logger.fatal do
          "Beginning step #{example.full_description} (at #{example.location})"
        end
      end

      group.after :step do |example|
        Rails.logger.fatal do
          "Finished step #{example.full_description} (at #{example.location})"
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.add_setting :waterpig_browser_types, :default => [:feature]
  config.add_setting :waterpig_browser_size_types, :default => [:feature]

  config.add_setting :waterpig_autosnap, :default => ENV['WATERPIG_AUTOSNAP']
  config.add_setting :waterpig_driver, :default => ENV['CAPYBARA_DRIVER']
  config.add_setting :waterpig_js_driver, :default => ENV['CAPYBARA_JS_DRIVER']
  config.add_setting :waterpig_clearable_logs, :default => [ 'test' ]

  config.add_setting :waterpig_browser_sizes, :default => {
    :mobile  => { :width => 320, :height => 480 },
    :small   => { :width => 550, :height => 700 },
    :medium  => { :width => 800, :height => 900 },
    :desktop => { :width => 1024, :height => 1024 }
  }

  if ENV['LOG_BROWSER_CONSOLE']
    Waterpig::BrowserConsoleLogger.configure(config)
  end

  config.before(:suite) do
    Capybara.default_driver = Waterpig.pick_capybara_driver(config.waterpig_driver)
    Capybara.javascript_driver = Waterpig.pick_capybara_driver(config.waterpig_js_driver)
  end

  if defined?(Timecop)
    config.after :all, :type => proc{|value| config.waterpig_browser_types.include?(value)} do
      Timecop.return
    end
  end

  config.include Waterpig::BrowserTools, :type => proc{|value| config.waterpig_browser_types.include?(value) }
  config.include Waterpig::TinyMCETools, :type => proc{|value| config.waterpig_browser_types.include?(value) }

  config.include Waterpig::AutoSnap, :type => proc{|value|
    config.waterpig_autosnap? && config.waterpig_browser_types.include?(value)
  }
  config.include Waterpig::SnapStep, :snapshots_into => proc{|v| v.is_a? String}

  config.include Waterpig::BrowserSize, :type => proc{|value|
    config.waterpig_browser_size_types && config.waterpig_browser_size_types.include?(value)
  }
end

RSpec.configure do |config|
  config.add_setting :waterpig_log_types, :default => [:feature]

  config.include Waterpig::ExampleLogger, :type => proc{|value|
    config.waterpig_log_types && config.waterpig_log_types.include?(value)
  }
end
