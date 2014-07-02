module Waterpig
  class WarningSuppressor
    class << self
      def write(message)
        if message =~ /QFont::setPixelSize: Pixel size <= 0/ || message =~/CoreText performance note:/ then 0 else puts(message);1;end
      end
    end
  end
end
