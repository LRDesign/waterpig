module Waterpig
  module BrowserSize
    RSpec.configure do |config|
      config.before(:each) do
        sizes = RSpec.configuration.waterpig_browser_sizes
        BrowserSize.resize_browser_window(sizes[BrowserSize.current_size])
      end
    end

    def self.resize_browser_window(size)
      Capybara.current_session.driver.browser.manage.window.resize_to(size[:width], size[:height])
    end

    def self.current_size
      (RSpec.current_example.metadata[:size] || ENV['BROWSER_SIZE'] || :desktop).to_sym
    end

  end
end
