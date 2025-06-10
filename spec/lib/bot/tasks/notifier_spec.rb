# frozen_string_literal: true

require "spec_helper"
require "rake"
require "bot/tasks/notifier"

RSpec.describe Bot::Tasks::Notifier do
  let(:notifier) { instance_double(Bot::Notifier) }
  let(:rake) { Rake::Application.new }

  before do
    # Setup Rake
    Rake.application = rake
    Rake::Task.clear

    allow(Bot::Notifier).to receive(:new).and_return(notifier)
    allow(notifier).to receive(:notify)

    # Set up Rake task values
    values = {
      "bn_webhook_url" => "https://example.com/webhook",
      "bn_messenger" => :mattermost,
      "bn_room" => "#deploy",
      "bn_username" => "DeployBot",
      "bn_emoji" => ":rocket:",
      "bn_app_name" => "my-app",
      "bn_color" => true,
      "bn_destination" => "production",
      "deployer" => "John",
      "branch" => "main"
    }

    # Initialize values hash
    rake.instance_variable_set(:@values, values)

    # Define fetch method for Rake tasks
    def rake.fetch(key)
      instance_variable_get(:@values)[key.to_s]
    end

    # Load rake tasks
    load "lib/bot/tasks/bot_notifier.rake"
  end

  describe "rake tasks" do
    describe "bot:starting" do
      it "sends starting deployment notification" do
        Rake::Task["bot:starting"].invoke
        expect(notifier).to have_received(:notify).with(
          "John is deploying my-app to production",
          fields: [
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ]
        )
      end
    end

    describe "bot:finished" do
      it "sends finished deployment notification" do
        Rake::Task["bot:finished"].invoke
        expect(notifier).to have_received(:notify).with(
          "John finished deploying my-app to production",
          fields: [
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ]
        )
      end
    end

    describe "bot:failed" do
      it "sends failed deployment notification with red color" do
        Rake::Task["bot:failed"].invoke
        expect(notifier).to have_received(:notify).with(
          "Failed to deploy my-app to production",
          color: "#ff0000",
          fields: [
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ]
        )
      end
    end

    describe "bot:test" do
      it "sends test notification" do
        Rake::Task["bot:test"].invoke
        expect(notifier).to have_received(:notify).with(
          "Test notification from my-app",
          fields: [
            { title: "App", value: "my-app", short: true },
            { title: "Environment", value: "production", short: true },
            { title: "Branch", value: "main", short: true },
            { title: "Deployer", value: "John", short: true }
          ]
        )
      end
    end
  end
end
