module Waterpig
  class BrowserConsoleLogger
    require 'singleton'
    include Singleton

    require 'text-table'
    attr_writer :file
    attr_accessor :path

    def file
      @file ||= File.new(path, "w")
    end

    def emit_header(string)
      file.write("#{bold(string)}\n")
    end

    def emit_log(entry)
      file.write( entry['time'] + "\n")
      if entry['type'] == 'table'
        emit_table(entry['value'])
      else
        file.write(entry['value'].to_s + "\n\n")
      end
    end

    # Tables are either a simple hash, or a hash of hashes.  See documentation
    # on emit_simple_table and emit_complex_table.
    def emit_table(hash)
      table      = Text::Table.new
      if hash.values.any?{ |val| val.is_a?(Hash) }
        emit_complex_table(hash, table)
      else
        emit_simple_table(hash, table)
      end
      @file.write(table.to_s + "\n\n")
    end

    # Simple hashes emit as a two-column table, with keys making up the index
    # column:
    #   { a: 1, b: 4, c: 'foo'}
    #
    # Will render as:
    #
    #  +-------+--------+
    #  | index | Values |
    #  +-------+--------+
    #  |   a   |   1    |
    #  +-------+--------+
    #  |   b   |   4    |
    #  +-------+--------+
    #  |   c   | 'foo'  |
    #  +-------+--------+
    def emit_simple_table(hash, table)
      table.head = [ "index", "values" ]
      hash.each do | key, val |
        table.rows << [ key, val ]
      end
    end

    # When they are a hash of hashes, used as follows:
    #  * The keys of the top-level hashes will be the leftmost column, "index".
    #  * The merged keys of the inner hashes will be the column headers
    #  * The values of the inner hashes will fill the table cells.
    #
    #  So for example:
    #    { foo: { a: 1, b: 2 },
    #      bar: { a: 5, c: 3 }}
    #
    #  Will render as:
    #  +-------+---+---+---+
    #  | index | a | b | c |
    #  +-------+---+---+---+
    #  |  foo  | 1 | 2 |   |
    #  +-------+---+---+---+
    #  |  bar  | 5 |   | 3 |
    #  +-------+---+---+---+
    def emit_complex_table(hash, table)
      keys = hash.reduce([]){ |memo, arr| memo + arr[1].keys }.uniq
      table.head = [ "index" ] + keys
      hash.each do |name, row|
        table.rows << [ name ] + keys.map{ |key| row.fetch(key, nil)}
      end
    end

    def bold(string)
      "\e[1m#{string}\e[0m"
    end

    class << self
      def configure(config)
        config.add_setting :waterpig_browser_console_log_path, :default => nil
        config.add_setting :waterpig_log_browser_console, :default => ENV['LOG_BROWSER_CONSOLE']

        config.before(:suite) do
          if config.waterpig_log_browser_console
            config.waterpig_browser_console_log_path ||=  Rails.root.join("log/#{Rails.env}_browser_console.log")
            config.waterpig_clearable_logs << 'test_browser_console'
          end
        end

        config.after(:each,:type => proc{|value|
          config.waterpig_log_types && config.waterpig_log_types.include?(value)
        }) do |example|
          if config.waterpig_log_browser_console
            logger = Waterpig::BrowserConsoleLogger.instance
            logger.path = config.waterpig_browser_console_log_path
            logger.emit_header "Browser console for #{example.full_description}"
            console_entries = page.evaluate_script("console.history");
            console_entries.each do |entry|
              logger.emit_log(entry)
            end
          end
        end
      end
    end
  end


end
