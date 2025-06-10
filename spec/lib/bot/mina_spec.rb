# frozen_string_literal: true

require "spec_helper"
DeploymentHelpers.require_mina
require "bot/mina"

RSpec.describe Bot::Mina do
  let(:hooks_container) do
    Class.new do
      def initialize
        @hooks = {
          before: {},
          after: {},
          error: {}
        }
      end

      def before_task(task_name, &block)
        @hooks[:before][task_name] = block
      end

      def after_task(task_name, &block)
        @hooks[:after][task_name] = block
      end

      def on_error_task(task_name, &block)
        @hooks[:error][task_name] = block
      end

      def run_before_hook(task_name)
        return unless @hooks[:before].key?(task_name)

        instance_eval(&@hooks[:before][task_name])
      end

      def run_after_hook(task_name)
        return unless @hooks[:after].key?(task_name)

        instance_eval(&@hooks[:after][task_name])
      end

      def run_error_hook(task_name)
        return unless @hooks[:error].key?(task_name)

        instance_eval(&@hooks[:error][task_name])
      end

      attr_reader :hooks
    end.new
  end

  let(:mina_config) { hooks_container }

  before do
    # Mock the notifier
    allow(Bot::Tasks::Notifier).to receive(:notify)
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_starting)
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_finished)
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_failed)

    # Load our tasks
    described_class.load_into(mina_config)
  end

  describe "hooks registration" do
    it "registers before deploy hook" do
      expect(mina_config.hooks[:before]).to have_key("deploy")
    end

    it "registers after deploy hook" do
      expect(mina_config.hooks[:after]).to have_key("deploy")
    end

    it "registers error deploy hook" do
      expect(mina_config.hooks[:error]).to have_key("deploy")
    end
  end

  describe "hook execution" do
    it "sends starting notification when before hook is triggered" do
      mina_config.run_before_hook("deploy")
      expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_starting)
    end

    it "sends finished notification when after hook is triggered" do
      mina_config.run_after_hook("deploy")
      expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_finished)
    end

    it "sends failed notification when error hook is triggered" do
      mina_config.run_error_hook("deploy")
      expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_failed)
    end
  end
end
