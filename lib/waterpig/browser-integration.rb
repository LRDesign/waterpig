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
require 'waterpig/snap-step'

RSpec.configure do |config|
  config.add_setting :waterpig_browser_types, :default => [:feature]
  config.add_setting :waterpig_autosnap, :default => true
  config.add_setting :waterpig_driver, :default => ENV['CAPYBARA_DRIVER']
  config.add_setting :waterpig_js_driver, :default => ENV['CAPYBARA_JS_DRIVER']


  config.before(:suite) do
    Capybara.default_driver = (config.waterpig_driver || :poltergeist_debug).to_sym
    Capybara.javascript_driver = (config.waterpig_js_driver || :poltergeist_debug).to_sym
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
end
