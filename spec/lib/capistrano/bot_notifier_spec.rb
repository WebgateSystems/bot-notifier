# frozen_string_literal: true

require "spec_helper"
require "capistrano/all"

module Capistrano
  # Ensure Capistrano module is defined for hook registration
end

RSpec.describe Capistrano::BotNotifier do
  describe Capistrano::BotNotifier::DSL do
    include Capistrano::DSL
    include described_class

    let(:webhook_url) { "https://hooks.slack.com/services/xxx/yyy/zzz" }

    before do
      # Set up Capistrano configuration
      set :bn_webhook_url, webhook_url
      set :application, "test-app"
      set :stage, "staging"
      set :deployer, "test-user"

      # Stub HTTP requests
      stub_request(:post, webhook_url)
    end

    after do
      # Clean up Capistrano configuration
      Capistrano::Configuration.reset!
    end

    describe "#post_to_channel" do
      let(:message) { "Test message" }

      context "with Slack messenger (default)" do
        it "sends a notification with Slack attachment format" do
          post_to_channel(:grey, message)

          expected_payload = {
            "channel" => "#platform",
            "username" => "capistrano",
            "icon_emoji" => ":rocket:",
            "attachments" => [{
              "fallback" => message,
              "text" => message,
              "color" => "#CCCCCC",
              "mrkdwn_in" => %w[text]
            }]
          }

          expect(WebMock)
            .to have_requested(:post, webhook_url)
            .with(body: { payload: expected_payload.to_json })
        end

        context "when colors are disabled" do
          before { set :bn_color, false }

          it "sends a notification without attachments" do
            post_to_channel(:grey, message)

            expected_payload = {
              "channel" => "#platform",
              "username" => "capistrano",
              "text" => message,
              "icon_emoji" => ":rocket:",
              "mrkdwn" => true
            }

            expect(WebMock)
              .to have_requested(:post, webhook_url)
              .with(body: { payload: expected_payload.to_json })
          end
        end
      end

      context "with Mattermost messenger" do
        before { set :bn_messenger, :mattermost }

        it "sends a notification with emoji for color" do
          post_to_channel(:grey, message)

          expected_payload = {
            "channel" => "#platform",
            "username" => "capistrano",
            "text" => ":arrow_right: #{message}",
            "icon_url" => nil,
            "type" => "custom_mattermost"
          }

          expect(WebMock)
            .to have_requested(:post, webhook_url)
            .with(body: { payload: expected_payload.to_json })
        end

        context "when colors are disabled" do
          before { set :bn_color, false }

          it "sends a notification with default emoji" do
            post_to_channel(:grey, message)

            expected_payload = {
              "channel" => "#platform",
              "username" => "capistrano",
              "text" => ":rocket: #{message}",
              "icon_url" => nil,
              "type" => "custom_mattermost"
            }

            expect(WebMock)
              .to have_requested(:post, webhook_url)
              .with(body: { payload: expected_payload.to_json })
          end
        end

        it "uses appropriate emojis for different colors" do
          {
            green: ":white_check_mark:",
            red: ":x:",
            blue: ":information_source:",
            grey: ":arrow_right:"
          }.each do |color, emoji|
            post_to_channel(color, message)

            expected_payload = {
              "channel" => "#platform",
              "username" => "capistrano",
              "text" => "#{emoji} #{message}",
              "icon_url" => nil,
              "type" => "custom_mattermost"
            }

            expect(WebMock)
              .to have_requested(:post, webhook_url)
              .with(body: { payload: expected_payload.to_json })
          end
        end
      end

      context "with Teams messenger" do
        before { set :bn_messenger, :teams }

        it "sends a notification with Teams format" do
          post_to_channel(:grey, message)

          expected_payload = {
            "title" => "capistrano",
            "text" => message,
            "themeColor" => "#CCCCCC"
          }

          expect(WebMock)
            .to have_requested(:post, webhook_url)
            .with(body: { payload: expected_payload.to_json })
        end

        context "when colors are disabled" do
          before { set :bn_color, false }

          it "sends a notification without theme color" do
            post_to_channel(:grey, message)

            expected_payload = {
              "title" => "capistrano",
              "text" => message,
              "themeColor" => nil
            }

            expect(WebMock)
              .to have_requested(:post, webhook_url)
              .with(body: { payload: expected_payload.to_json })
          end
        end
      end
    end

    describe "tasks" do
      let(:env) { Capistrano::Configuration.env }

      before do
        # Reset Rake tasks
        Rake.application = Rake::Application.new

        # Set up Capistrano configuration
        env.set_if_empty :application, "test-app"
        env.set_if_empty :stage, "staging"
        env.set_if_empty :deployer, "test-user"
        env.set_if_empty :bn_webhook_url, webhook_url

        # Define base Capistrano tasks that our tasks hook into
        %w[starting finishing failed reverting rollback].each do |task|
          Rake::Task.define_task("deploy:#{task}")
        end

        # Load our tasks
        load "capistrano/tasks/bot_notifier.rake"
      end

      describe "task definitions" do
        %w[starting finished failed reverted rolled_back].each do |task|
          it "defines bn:#{task}" do
            expect(Rake::Task["bn:#{task}"]).to be_instance_of(Rake::Task)
          end
        end
      end

      describe "hooks" do
        let(:hooks) do
          {
            "deploy:starting" => "bn:starting",
            "deploy:finishing" => "bn:finished",
            "deploy:failed" => "bn:failed",
            "deploy:reverting" => "bn:reverted",
            "deploy:rollback" => "bn:rolled_back"
          }
        end

        it "sends notifications when deploy tasks are invoked" do
          hooks.each_key do |trigger|
            # Reset the request history before each task invocation
            WebMock.reset_executed_requests!

            # Invoke the task
            Rake::Task[trigger].invoke

            # Verify that at least one webhook request was made
            expect(WebMock).to have_requested(:post, webhook_url).at_least_once
          end
        end
      end

      describe "default configuration" do
        before do
          Rake::Task.define_task("load:defaults")
          Rake::Task["load:defaults"].invoke
        end

        let(:expected_defaults) do
          {
            bn_room: "#platform",
            bn_username: "capistrano",
            bn_emoji: ":rocket:"
          }
        end

        it "sets default values" do
          expected_defaults.each do |key, value|
            expect(fetch(key)).to eq(value)
          end
        end
      end
    end
  end
end
