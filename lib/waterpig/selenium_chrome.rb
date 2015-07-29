begin
  require 'selenium-webdriver'
  Capybara.register_driver(:selenium_chrome) do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end

  Capybara.register_driver :mobile_chrome_ios do |app|
    mobile_emulation = { "deviceName" => "Apple iPhone 6" }
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome('chromeOptions' => {'mobileEmulation' => mobile_emulation})
    Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => capabilities)
  end

  Capybara.register_driver :mobile_chrome_android do |app|
    mobile_emulation = { "deviceName" => "Samsung Galaxy S4" }
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome('chromeOptions' => {'mobileEmulation' => mobile_emulation})
    Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => capabilities)
  end

rescue LoadError
end
