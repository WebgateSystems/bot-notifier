# frozen_string_literal: true

require "bot/notifier"

module Bot
  module Tasks
    module Notifier
      extend self

      def notify_deploy_starting
        notify("#{fetch(:deployer)} is deploying #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
               fields: build_notification_fields)
      end

      def notify_deploy_finished
        notify("#{fetch(:deployer)} finished deploying #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
               fields: build_notification_fields)
      end

      def notify_deploy_failed
        notify("Failed to deploy #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
               color: "#ff0000",
               fields: build_notification_fields)
      end

      def notify(message, options = {})
        notifier = Bot::Notifier.new(
          fetch(:bn_webhook_url),
          {
            platform: fetch(:bn_messenger),
            room: fetch(:bn_room),
            username: fetch(:bn_username),
            emoji: fetch(:bn_emoji),
            color: fetch(:bn_color)
          }
        )
        notifier.notify(message, options)
      end

      private

      def build_notification_fields
        [
          { title: "App", value: fetch(:bn_app_name), short: true },
          { title: "Environment", value: fetch(:bn_destination), short: true },
          { title: "Branch", value: fetch(:branch), short: true },
          { title: "Deployer", value: fetch(:deployer), short: true }
        ]
      end

      def fetch(key)
        if defined?(Rake) && Rake.application.respond_to?(:fetch)
          Rake.application.fetch(key)
        elsif defined?(Capistrano)
          Capistrano::Configuration.env.fetch(key)
        else
          raise "No configuration context available"
        end
      end
    end
  end
end
