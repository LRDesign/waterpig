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
        #self.<<("table JSON:")
        #self.<<("\n-------------------------\n")
        #self.<<(entry['value'])
        #self.<<("\n-------------------------\n")
        emit_table(entry['value'])
      else
        self.<<(entry['value'].to_s + "\n\n")
      end
    end

    # tables are either a simple hash, or a hash of hashes.
    #
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
    #
    #
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
    def emit_table(hash)
      if hash.values.any?{ |val| val.is_a?(Hash) }
        emit_complex_table(hash)
      else
        emit_simple_table(hash)
      end
    end

    def emit_simple_table(hash)
      table      = Text::Table.new
      table.head = [ "index", "values" ]
      hash.each do | key, val |
        table.rows << [ key, val ]
      end
      self.<<(table.to_s + "\n\n")
    end

    def emit_complex_table(hash)
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

        config.after(:each,:type => proc{|value|
          config.waterpig_log_types && config.waterpig_log_types.include?(value)
        }) do |example|
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
