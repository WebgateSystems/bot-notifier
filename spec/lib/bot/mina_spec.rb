# frozen_string_literal: true

require "spec_helper"
DeploymentHelpers.require_mina

RSpec.describe Bot::Mina do
  let(:notifier) { instance_double(Bot::Notifier) }
  let(:config) { {} }

  before do
    # Mock Mina::Configuration
    stub_const("Mina::Configuration", Class.new do
      def self.instance
        @instance ||= new
      end

      def fetch(key)
        @config ||= {}
        @config[key]
      end

      def set(key, value)
        @config ||= {}
        @config[key] = value
      end
    end)

    # Mock Mina::Hooks
    stub_const("Mina::Hooks", Module.new do
      class << self
        attr_accessor :hooks

        def before_hook(task_name, _hook_name = nil, &block)
          self.hooks ||= { before: {}, after: {}, error: {} }
          hooks[:before][task_name] = block
        end

        def after_hook(task_name, _hook_name = nil, &block)
          self.hooks ||= { before: {}, after: {}, error: {} }
          hooks[:after][task_name] = block
        end

        def error_hook(task_name, _hook_name = nil, &block)
          self.hooks ||= { before: {}, after: {}, error: {} }
          hooks[:error][task_name] = block
        end

        def trigger_before(task_name)
          return unless hooks&.dig(:before, task_name)

          instance_eval(&hooks[:before][task_name])
        end

        def trigger_after(task_name)
          return unless hooks&.dig(:after, task_name)

          instance_eval(&hooks[:after][task_name])
        end

        def trigger_error(task_name)
          return unless hooks&.dig(:error, task_name)

          instance_eval(&hooks[:error][task_name])
        end

        def before_hooks
          hooks&.dig(:before) || {}
        end

        def after_hooks
          hooks&.dig(:after) || {}
        end

        def error_hooks
          hooks&.dig(:error) || {}
        end

        def fetch(key)
          Mina::Configuration.instance.fetch(key)
        end
      end
    end)

    allow(Bot::Notifier).to receive(:new).and_return(notifier)
    allow(notifier).to receive(:notify)

    # Set up configuration
    Mina::Configuration.instance.set(:bn_webhook_url, "https://example.com/webhook")
    Mina::Configuration.instance.set(:bn_messenger, :mattermost)
    Mina::Configuration.instance.set(:bn_room, "#deploy")
    Mina::Configuration.instance.set(:bn_username, "DeployBot")
    Mina::Configuration.instance.set(:bn_emoji, ":rocket:")
    Mina::Configuration.instance.set(:bn_app_name, "my-app")
    Mina::Configuration.instance.set(:bn_color, true)
    Mina::Configuration.instance.set(:bn_destination, "production")
    Mina::Configuration.instance.set(:deployer, "John")
    Mina::Configuration.instance.set(:branch, "main")
  end

  describe ".setup!" do
    before do
      described_class.setup!
    end

    it "registers before deploy hook" do
      expect(Mina::Hooks.before_hooks).to have_key("deploy")
    end

    it "registers after deploy hook" do
      expect(Mina::Hooks.after_hooks).to have_key("deploy")
    end

    it "registers error deploy hook" do
      expect(Mina::Hooks.error_hooks).to have_key("deploy")
    end

    describe "when hooks are triggered" do
      it "sends starting notification when before hook is triggered" do
        Mina::Hooks.trigger_before("deploy")
        expect(notifier).to have_received(:notify).with(
          "John is deploying my-app to production",
          hash_including(fields: array_including(
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ))
        )
      end

      it "sends finished notification when after hook is triggered" do
        Mina::Hooks.trigger_after("deploy")
        expect(notifier).to have_received(:notify).with(
          "John finished deploying my-app to production",
          hash_including(fields: array_including(
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ))
        )
      end

      it "sends failed notification when error hook is triggered" do
        Mina::Hooks.trigger_error("deploy")
        expect(notifier).to have_received(:notify).with(
          "Failed to deploy my-app to production",
          hash_including(
            color: "#ff0000",
            fields: array_including(
              { title: "App", value: "my-app", short: true },
              { title: "Environment", value: "production", short: true },
              { title: "Branch", value: "main", short: true },
              { title: "Deployer", value: "John", short: true }
            )
          )
        )
      end
    end
  end
end
