module Waterpig
  module BrowserTools
    def accept_alert
      if poltergeist?
        # do nothing ... really?
        # https://github.com/jonleighton/poltergeist/issues/50
        # Poltergeist's behavior is to return true to window.alert
        # Does mean it's a challenge to test cancelling e.g. deletes, or
        # confirming that an alert happens even
      else
        alert = page.driver.browser.switch_to.alert
        alert.accept
      end
    end

    def wait_for_animation
      sleep(1) if poltergeist?
    end

    def poltergeist?
      Capybara.javascript_driver.to_s =~ /poltergeist/
    end

    def self.warnings
      @warnings ||= {}
    end

    def self.warn(general, specific=nil)
      warnings.fetch(general) do
        warnings[general] = true
        puts "Warning: #{general}#{specific ? ": #{specific}" : ""}"
      end
    end

    #renders the xpath to properly match a css class (or other space separated
    #attribute)
    #Use like: div[#{attr_includes("class", "findme")}]
    #
    def attr_includes(attr, value)
      "contains(concat(' ', normalize-space(@#{attr}), ' '), ' #{value} ')"
    end

    def class_includes(value)
      attr_includes("class", value)
    end

    def frame_index(dir)
      @frame_dirs ||= Hash.new do |h,k|
        FileUtils.rm_rf(k)
        FileUtils.mkdir_p(k)
        h[k] = 0
      end
      @frame_dirs[dir] += 1
    end

    def save_snapshot(dir, name)
      require 'fileutils'

      dir = "tmp/#{dir}"

      path = "#{dir}/#{"%03i" % frame_index(dir)}-#{name}.png"
      begin
        page.driver.save_screenshot(path, :full => true)
      rescue Capybara::NotSupportedByDriverError => nsbde
        BrowserTools.warn("Can't use snapshot", nsbde.inspect)
      rescue Object => ex
        BrowserTools.warn("Error attempted snapshot", ex.inspect)
      end

      yield path if block_given?
    end

    def snapshot(dir)
      save_snapshot(dir, "debug") do |path|
        msg = "Saved screenshot: #{path} (from: #{caller[0].sub(/^#{Dir.pwd}/,'')})"
        puts msg
        Rails.logger.info(msg)
      end
    end
  end
end
