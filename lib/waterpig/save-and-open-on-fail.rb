module Waterpig
  module SaveAndOpenOnFail
    def instance_eval(&block)
      super(&block)
    rescue RSpec::Core::Pending::PendingDeclaredInExample
      raise
    rescue Object => ex
      begin
        wrapper = ex.exception("#{ex.message}\nLast view at: file://#{save_page}")
        wrapper.set_backtrace(ex.backtrace)
        raise wrapper
      rescue
        raise ex
      end
    end
  end
end
