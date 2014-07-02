
begin
  require 'capybara/poltergeist'
  module Capybara::Poltergeist
    class Client
      private
      def redirect_stdout
        prev = STDOUT.dup
        prev.autoclose = false
        $stdout = @write_io
        STDOUT.reopen(@write_io)

        prev = STDERR.dup
        prev.autoclose = false
        $stderr = @write_io
        STDERR.reopen(@write_io)
        yield
      ensure
        STDOUT.reopen(prev)
        $stdout = STDOUT
        STDERR.reopen(prev)
        $stderr = STDERR
      end
    end
  end

  Capybara.register_driver :poltergeist_debug do |app|
    Capybara::Poltergeist::Driver.new(app, :inspector => true, phantomjs_logger: Waterpig::WarningSuppressor)
  end
rescue LoadError
end
