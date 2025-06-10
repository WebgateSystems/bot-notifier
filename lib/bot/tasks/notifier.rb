# frozen_string_literal: true

require "bot/notifier"

module Bot
  module Tasks
    # Rake task notifier
    class Notifier
      class << self
        def notify(message, options = {})
          notifier = Bot::Notifier.new(
            webhook_url: fetch(:bn_webhook_url),
            messenger: fetch(:bn_messenger),
            room: fetch(:bn_room),
            username: fetch(:bn_username),
            emoji: fetch(:bn_emoji)
          )

          notifier.notify(message, options)
        end

        private

        def fetch(key)
          if defined?(Rake) && Rake.application.respond_to?(:fetch)
            value = Rake.application.fetch(key.to_s)
            return value if value

            # Try to get from instance variables if fetch returns nil
            values = Rake.application.instance_variable_get(:@values) || {}
            values[key.to_s]
          elsif defined?(Capistrano::Configuration)
            value = Capistrano::Configuration.env.fetch(key)
            value.respond_to?(:call) ? value.call : value
          end
        end
      end
    end
  end
end
