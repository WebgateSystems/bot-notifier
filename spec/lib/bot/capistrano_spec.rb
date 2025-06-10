# frozen_string_literal: true

require "spec_helper"
DeploymentHelpers.require_capistrano
require_relative "../../../lib/bot/capistrano"

RSpec.describe Bot::Capistrano do
  include Capistrano::DSL

  let(:stage) { :staging }
  let(:application) { "test-app" }
  let(:deploy_to) { "/tmp/capistrano/test" }
  let(:hooks) { [] }
  let(:registered_hooks) { [] }

  before do
    # Reset Capistrano configuration for each test
    Capistrano::Configuration.reset!

    # Set up basic configuration
    set :stage, stage
    set :application, application
    set :deploy_to, deploy_to

    # Track task registration and hook registration
    original_define_task = Rake::Task.method(:define_task)
    allow(Rake::Task).to receive(:define_task) do |task_name, *args, &block|
      hooks << task_name.to_s if task_name.to_s.start_with?("bot:")
      original_define_task.call(task_name, *args, &block)
    end

    # Track hook registration
    Rake::Task.instance_method(:enhance)
    allow(Rake::Task).to receive(:new).and_wrap_original do |method, *args|
      task = method.call(*args)
      allow(task).to receive(:enhance) do |prerequisites = nil, &block|
        registered_hooks << "before:#{task.name}" if prerequisites
        registered_hooks << "after:#{task.name}" if block

        # Call original enhance functionality
        task.prerequisites.concat(Array(prerequisites)) if prerequisites
        task.actions << block if block
        task
      end
      task
    end

    # Define Capistrano deployment tasks
    Rake::Task.define_task("deploy:starting")
    Rake::Task.define_task("deploy:finished")
    Rake::Task.define_task("deploy:failed")

    # Mock the notifier
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_starting)
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_finished)
    allow(Bot::Tasks::Notifier).to receive(:notify_deploy_failed)

    # Load our tasks
    described_class.load_into(Capistrano::Configuration.env)
  end

  describe "default settings" do
    it "sets default messenger to slack" do
      expect(fetch(:bn_messenger)).to eq(:slack)
    end

    it "sets default emoji" do
      expect(fetch(:bn_emoji)).to eq(":rocket:")
    end

    it "sets default username from ENV" do
      value = fetch(:bn_username)
      value = value.call if value.respond_to?(:call)
      expect(value).to eq(ENV.fetch("USER", nil))
    end

    it "sets default color to true" do
      expect(fetch(:bn_color)).to be true
    end

    it "sets default destination to staging" do
      value = fetch(:bn_destination)
      value = value.call if value.respond_to?(:call)
      expect(value).to eq("staging")
    end

    it "sets default deployer from ENV" do
      value = fetch(:deployer)
      value = value.call if value.respond_to?(:call)
      expect(value).to eq(ENV.fetch("USER", nil)&.capitalize)
    end
  end

  describe "required settings" do
    it "requires bn_webhook_url to be set" do
      expect { fetch(:bn_webhook_url) }.to raise_error(RuntimeError, /Please set bn_webhook_url/)
    end
  end

  describe "overriding settings" do
    before do
      set :bn_webhook_url, "https://example.com/webhook"
      set :bn_messenger, :mattermost
      set :bn_room, "#deploy"
      set :bn_username, "DeployBot"
      set :bn_emoji, ":ship:"
      set :bn_app_name, "my-app"
      set :bn_color, false
      set :bn_destination, "production"
      set :deployer, "John"
    end

    it "allows overriding webhook url" do
      expect(fetch(:bn_webhook_url)).to eq("https://example.com/webhook")
    end

    it "allows overriding messenger" do
      expect(fetch(:bn_messenger)).to eq(:mattermost)
    end

    it "allows overriding room" do
      expect(fetch(:bn_room)).to eq("#deploy")
    end

    it "allows overriding username" do
      expect(fetch(:bn_username)).to eq("DeployBot")
    end

    it "allows overriding emoji" do
      expect(fetch(:bn_emoji)).to eq(":ship:")
    end

    it "allows overriding app name" do
      expect(fetch(:bn_app_name)).to eq("my-app")
    end

    it "allows overriding color" do
      expect(fetch(:bn_color)).to be false
    end

    it "allows overriding destination" do
      expect(fetch(:bn_destination)).to eq("production")
    end

    it "allows overriding deployer" do
      expect(fetch(:deployer)).to eq("John")
    end
  end

  describe "hooks" do
    it "registers bot:starting task" do
      expect(hooks).to include("bot:starting")
    end

    it "registers bot:finished task" do
      expect(hooks).to include("bot:finished")
    end

    it "registers bot:failed task" do
      expect(hooks).to include("bot:failed")
    end

    it "registers hooks for deployment events" do
      expect(registered_hooks).to include("before:deploy:starting")
      expect(registered_hooks).to include("after:deploy:finished")
      expect(registered_hooks).to include("after:deploy:failed")
    end

    describe "when hooks are triggered" do
      before do
        # Set up configuration values
        set :bn_webhook_url, "https://example.com/webhook"
        set :bn_app_name, "my-app"
        set :bn_destination, "production"
        set :deployer, "John"
        set :branch, "main"

        # Reset hooks tracking for this context
        hooks.clear

        # Define the tasks again to ensure they exist
        Rake::Task.define_task("bot:starting")
        Rake::Task.define_task("bot:finished")
        Rake::Task.define_task("bot:failed")

        # Set up Rake environment values
        values = {
          "bn_webhook_url" => "https://example.com/webhook",
          "bn_app_name" => "my-app",
          "bn_destination" => "production",
          "deployer" => "John",
          "branch" => "main"
        }
        Rake.application.instance_variable_set(:@values, values)

        # Mock the fetch method in Bot::Tasks::Notifier to use Capistrano values
        allow(Bot::Tasks::Notifier).to receive(:fetch).and_wrap_original do |_original_method, *args|
          key = args.first
          Capistrano::Configuration.env.fetch(key)
        end
      end

      it "sends starting notification" do
        Rake::Task["bot:starting"].invoke
        expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_starting)
      end

      it "sends finished notification" do
        Rake::Task["bot:finished"].invoke
        expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_finished)
      end

      it "sends failed notification" do
        Rake::Task["bot:failed"].invoke
        expect(Bot::Tasks::Notifier).to have_received(:notify_deploy_failed)
      end
    end
  end
end
