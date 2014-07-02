begin
  require 'selenium-webdriver'
  Capybara.register_driver(:selenium_chrome) do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end

rescue LoadError
end
