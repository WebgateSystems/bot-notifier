# frozen_string_literal: true

require "bot/tasks/notifier"

module Bot
  # Mina integration
  module Mina
    extend self

    def load_defaults
      set :bn_messenger, :slack
      set :bn_emoji, ":rocket:"
      set :bn_username, ENV.fetch("USER", nil)
      set :bn_color, true
      set :bn_destination, -> { fetch(:stage) || fetch(:rails_env, "staging") }
      set :bn_app_name, -> { fetch(:application_name) }
      set :deployer, -> { ENV.fetch("USER", nil)&.capitalize }
    end

    def setup!
      return unless defined?(::Mina)

      # Initialize hook storage if not already initialized
      initialize_hooks
      register_hooks
    end

    def load_into(config)
      config.before_task("deploy") do
        Bot::Tasks::Notifier.notify_deploy_starting
      end

      config.after_task("deploy") do
        Bot::Tasks::Notifier.notify_deploy_finished
      end

      config.on_error_task("deploy") do
        Bot::Tasks::Notifier.notify_deploy_failed
      end
    end

    private

    def initialize_hooks
      return if ::Mina::Hooks.respond_to?(:before_hooks)

      ::Mina::Hooks.module_eval do
        @before_hooks = {}
        @after_hooks = {}
        @error_hooks = {}

        class << self
          attr_accessor :before_hooks, :after_hooks, :error_hooks

          def before_hook(task_name, &block)
            @before_hooks ||= {}
            @before_hooks[task_name] = block
          end

          def after_hook(task_name, &block)
            @after_hooks ||= {}
            @after_hooks[task_name] = block
          end

          def error_hook(task_name, &block)
            @error_hooks ||= {}
            @error_hooks[task_name] = block
          end

          def fetch(key)
            ::Mina::Configuration.instance.fetch(key)
          end
        end
      end
    end

    def register_hooks
      mina = self

      ::Mina::Hooks.before_hook("deploy") do
        notifier = mina.send(:create_notifier)
        fields = mina.send(:default_fields)
        notifier.notify(
          "#{fetch(:deployer)} is deploying #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
          fields: fields
        )
      end

      ::Mina::Hooks.after_hook("deploy") do
        notifier = mina.send(:create_notifier)
        fields = mina.send(:default_fields)
        notifier.notify(
          "#{fetch(:deployer)} finished deploying #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
          fields: fields
        )
      end

      ::Mina::Hooks.error_hook("deploy") do
        notifier = mina.send(:create_notifier)
        fields = mina.send(:default_fields)
        notifier.notify(
          "Failed to deploy #{fetch(:bn_app_name)} to #{fetch(:bn_destination)}",
          color: "#ff0000",
          fields: fields
        )
      end
    end

    def create_notifier
      Bot::Notifier.new(
        webhook_url: fetch(:bn_webhook_url),
        messenger: fetch(:bn_messenger),
        room: fetch(:bn_room),
        username: fetch(:bn_username),
        emoji: fetch(:bn_emoji)
      )
    end

    def default_fields
      [
        { title: "App", value: fetch(:bn_app_name), short: true },
        { title: "Environment", value: fetch(:bn_destination), short: true },
        { title: "Branch", value: fetch(:branch), short: true },
        { title: "Deployer", value: fetch(:deployer), short: true }
      ]
    end

    def set(key, value = nil, &block)
      if defined?(::Mina)
        ::Mina::Configuration.instance.set(key, block || value)
      else
        Rake.application.instance_variable_set(:@top_level_tasks, [])
        Rake.application[key] = block || value
      end
    end

    def fetch(key)
      if defined?(::Mina)
        ::Mina::Configuration.instance.fetch(key)
      else
        value = Rake.application[key]
        if value.nil? && !default.nil?
          default.is_a?(Proc) ? default.call : default
        else
          value
        end
      end
    end
  end
end
