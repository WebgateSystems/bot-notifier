# frozen_string_literal: true

# Monkey patch to selectively silence warnings
module Warning
  class << self
    def warn(message)
      if message.include?("circular require considered harmful")
        # Skip circular dependency warnings
        return
      end

      super
    end
  end
end
