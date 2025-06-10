# frozen_string_literal: true

require "spec_helper"
DeploymentHelpers.require_capistrano

RSpec.describe Bot::Capistrano do
  include Capistrano::DSL

  let(:stage) { :staging }
  let(:application) { "test-app" }
  let(:deploy_to) { "/tmp/capistrano/test" }

  before do
    # Reset Capistrano configuration for each test
    Capistrano::Configuration.reset!

    # Set up basic configuration
    set :stage, stage
    set :application, application
    set :deploy_to, deploy_to

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
end
