# This file is present to use in difficult RSpec cases.
#
# Essentially, an at_exit block will fail for some reason. The symptom is that
# RSpec doesn't exit, or exits with the wrong status code. To determine where
# the issue might be, run
#
# rspec -r waterpig/at_exit_duck_punch spec
#
# which will then report all the at_exit blocks as they're declared and when
# they're run
module Kernel
  alias original_at_exit at_exit

  def at_exit(&block)
    installing_pid = Process.pid
    install_point = caller[0]
    $stderr.puts "at_exit installed at #{install_point}"

    original_at_exit do
      $stderr.puts "START: at_exit block by pid: #{installing_pid} run in #{Process.pid} from #{install_point}"
      if $!
        $stderr.puts "current $!: #{$!.inspect}"
      end

      block.call

      $stderr.puts "FINISH: at_exit block from #{install_point}"
      if $!
        $stderr.puts "current $!: #{$!.inspect}"
      end
    end
  end
end
