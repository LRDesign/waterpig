module Waterpig
  class BrowserConsoleLogger < Logger
    require 'text-table'

    def initialize(path = nil)
      path ||= Rails.root.join("log/#{Rails.env}_console.log")
      super(path)
    end

    def emit_header(string)
      self.<<("#{bold(string)}\n")
    end

    def emit_log(entry)
      self.<<( entry['time'] + "\n")
      if entry['type'] == 'table'
        emit_table(entry['value'])
      else
        self.<<(entry['value'].to_s + "\n\n")
      end
    end

    def emit_table(hash)
      table      = Text::Table.new
      keys = hash.reduce([]){ |memo, arr| memo + arr[1].keys }.uniq
      table.head = [ "index" ] + keys
      hash.each do |name, row|
        table.rows << [ name ] + keys.map{ |key| row.fetch(key, nil)}
      end
      self.<<(table.to_s + "\n\n")
    end

    def bold(string)
      "\e[1m#{string}\e[0m"
    end

    class << self
      def configure(config)
        config.before :suite do
          config.add_setting :waterpig_console_logger, :default => Waterpig::BrowserConsoleLogger.new
          config.waterpig_clearable_logs << 'test_console'
        end

        config.after :each do |example|
          config.waterpig_console_logger.emit_header "Browser console for #{example.full_description}"
          console_entries = page.evaluate_script("console.history");
          console_entries.each do |entry|
            config.waterpig_console_logger.emit_log(entry)
          end
        end
      end
    end
  end


end
