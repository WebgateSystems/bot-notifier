# frozen_string_literal: true

module Bot
  module Formatters
    class Base
      attr_reader :config

      def initialize(config = {})
        @config = config
      end

      def format(message, options = {})
        raise NotImplementedError, "Subclasses must implement format method"
      end

      protected

      def merge_options(options)
        config.merge(options)
      end
    end
  end
end
