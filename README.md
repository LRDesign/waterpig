Waterpig
========

A collection of helpers for Capybara, collected over several years by Logical Reality Design.

Selecting A Browser Driver
--------------------------

You can JS and non-JS capybara drivers with either environment variables or your rspec config.  The
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

The Waterpig::BrowserConsoleLogger class can execute a remote call to console.history() in your browser at the end of  
