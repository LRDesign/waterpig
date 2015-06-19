module Waterpig
  module BrowserSize
    def self.included(group)
      group.before(:each) do |example|
        sizes = RSpec.configuration.waterpig_browser_sizes
        BrowserSize.resize_browser_window(sizes[BrowserSize.current_size(example)])
      end
    end

    def self.resize_browser_window(size)
      driver = Capybara.current_session.driver
      window = driver.current_window_handle
      req_size = [size.fetch(:width), size.fetch(:height)]
      driver.resize_window_to(window, *req_size)
    end

    def self.current_size(example)
      (example.metadata[:size] || ENV['BROWSER_SIZE'] || :desktop).to_sym
    end
  end
end
