module Waterpig
  module CKEditorTools
    def fill_in_ckeditor(id, options = {})
      raise "Must pass a hash containing 'with'" if not options.is_a?(Hash) or not options.has_key?(:with)
      raise "CKEeditor fill-in only works with Selenium driver" unless page.driver.class == Capybara::Selenium::Driver
      browser = page.driver.browser
      browser.execute_script("CKEDITOR.instances['#{id}'].setData('#{options[:with]}');")
    end
  end
end
