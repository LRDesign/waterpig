module Waterpig
  def self.configure
    yield Configure.instance
  end

  class Configure
    def self.instance
      @instance ||= self.new
    end

    attr_accessor :auto_snap

    def initialize
      @auto_snap = true
    end
  end
end
