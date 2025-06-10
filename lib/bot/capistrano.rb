# frozen_string_literal: true

require "bot-notifier"
require "capistrano/all"

module Bot
  class Capistrano
    def self.load_into(config)
      config.instance_eval do
        # Default settings
        set :bn_messenger, :slack
        set :bn_emoji, ":rocket:"
        set :bn_username, -> { ENV.fetch("USER", nil) }
        set :bn_color, true
        set :bn_destination, -> { fetch(:stage, "staging").to_s }
        set :bn_app_name, -> { fetch(:application) }
        set :deployer, -> { ENV.fetch("USER", nil)&.capitalize }

        # Ensure required variables are set
        %i[bn_webhook_url].each do |var|
          set(var) do
            raise "Please set #{var} in your deploy.rb"
          end
        end

        # Load rake tasks
        load File.expand_path("tasks/bot_notifier.rake", __dir__)
      end
    end
  end
end
