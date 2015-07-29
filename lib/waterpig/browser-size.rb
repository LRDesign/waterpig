module Waterpig
  module BrowserSize
    def self.included(group)
      group.before(:each) do |example|
        sizes = RSpec.configuration.waterpig_browser_sizes
        BrowserSize.resize_browser_window(sizes[BrowserSize.current_size(example)])
      end
    end

    #empirically determined - there's an issue on Chrome somewhere, but I can't
    #find it at the moment. The upshot is: if you resize Chrome on Linux below
    #this width, the content area collapses to 0 height. Tests pass anyway, is
    #the worst part.
    MIN_WIDTH = 348

    @@warned_about_size = false

    def self.resize_browser_window(size)
      driver = Capybara.current_session.driver
      window = driver.current_window_handle
      width = size.fetch(:width)
      if width < MIN_WIDTH
        unless @@warned_about_size
          warn "Requested browser size #{size.inspect} - but minimum width is #{MIN_WIDTH}. Adjusting."
          warn "You might consider setting up mobile browser emulation. Try running with"
          warn "CAPYBARA_DRIVER=mobile_chrome_android CAPYBARA_JS_DRIVER=mobile_chrome_android"
          @@warned_about_size = true
        end
        width = MIN_WIDTH
      end

      req_size = [width, size.fetch(:height)]
      driver.resize_window_to(window, *req_size)
    end

    def self.current_size(example)
      (example.metadata[:size] || ENV['BROWSER_SIZE'] || :desktop).to_sym
    end
  end
end
