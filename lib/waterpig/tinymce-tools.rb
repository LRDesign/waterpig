module Waterpig
  module TinyMCETools
    def fill_in_tinymce(id, options = {})
      content =
        case options
        when Hash
          content = options.fetch(:with)
        when String
          options
        else
          raise "Must pass a string or a hash containing 'with'"
        end

      case page.driver
      when Capybara::Selenium::Driver
        page.execute_script("$('##{id}').tinymce().setContent('#{content}')")
      when Capybara::Poltergeist::Driver
        within_frame("#{id}_ifr") do
          element = find("body")
          element.native.send_keys(content)
        end
      else
        raise "fill_in_tinymce called with unrecognized page.driver: #{page.driver.class.name}"
      end
    end
  end
end
