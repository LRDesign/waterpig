require 'thread'

module Waterpig
  class RequestWaitMiddleware
    @@idle_mutex = Mutex.new

    @@waiting_requests = {}
    @@block_requests = false

    # This is the only method one would normally call: wrap calls that e.g. drop
    # the test database in wait_for_idle{ <code> } in order to be sure that
    # outstanding requests are complete
    def self.wait_for_idle
      @@block_requests = true

      @@idle_mutex.synchronize do
        yield
      end

      @@block_requests = false
    end

    def block_requests?
      @@block_requests
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      increment_active_requests(env)
      if block_requests?
        block_request
      else
        @app.call(env)
      end
    ensure
      decrement_active_requests(env)
    end

    BLOCKED = [503, {}, ["Test is over - server no longer available"]].freeze

    def block_request
      BLOCKED
    end

    def increment_active_requests(env)
      @@idle_mutex.lock unless @@idle_mutex.owned?
      @@waiting_requests[env.object_id] = true
    end

    def decrement_active_requests(env)
      @@waiting_requests.delete(env.object_id)
      if @@waiting_requests.empty?
        @@idle_mutex.unlock
      end
    end
  end
end
