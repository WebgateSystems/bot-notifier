# frozen_string_literal: true

require "bot/tasks/notifier"
require "capistrano/dsl"
require "rake"

module Bot
  module Capistrano
    extend ::Capistrano::DSL

    def self.load_into(config)
      configure_defaults(config)
      register_tasks(config)
      register_hooks
    end

    def self.configure_defaults(config)
      config.set_if_empty :bn_messenger, :slack
      config.set_if_empty :bn_emoji, ":rocket:"
      config.set_if_empty :bn_username, -> { ENV.fetch("USER", nil) }
      config.set_if_empty :bn_color, true
      config.set_if_empty :bn_destination, -> { config.fetch(:stage, "staging").to_s }
      config.set_if_empty :deployer, -> { ENV.fetch("USER", nil)&.capitalize }

      # Ensure required variables are set
      config.set(:bn_webhook_url) { raise "Please set bn_webhook_url in your deploy.rb" }
    end

    def self.register_tasks(config)
      config.instance_eval do
        Rake::Task.define_task("bot:starting") do
          Bot::Tasks::Notifier.notify_deploy_starting
        end

        Rake::Task.define_task("bot:finished") do
          Bot::Tasks::Notifier.notify_deploy_finished
        end

        Rake::Task.define_task("bot:failed") do
          Bot::Tasks::Notifier.notify_deploy_failed
        end
      end
    end

    def self.register_hooks
      before "deploy:starting", "bot:starting"
      after "deploy:finished", "bot:finished"
      after "deploy:failed", "bot:failed"
    end
  end
end
