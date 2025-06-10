# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bot::Notifier do
  let(:test_data) do
    {
      webhook_url: "https://hooks.example.com/webhook",
      json: { text: "Test message" },
      raw: '{"text": "Raw message"}',
      response: {
        success: { status: 200, body: '{"ok": true}' },
        failure: { status: 400, body: '{"ok": false, "error": "invalid_payload"}' }
      },
      notifier: described_class.new("https://hooks.example.com/webhook"),
      options: {
        default: { username: "Custom Bot", emoji: ":tada:" },
        override: { username: "Override Bot" }
      }
    }
  end
  let(:http_client) { instance_double(WS::HttpClient::Connection) }
  let(:http_response) { instance_double(WS::HttpClient::Response) }
  let(:notifier) { test_data[:notifier] }

  before do
    allow(WS::HttpClient::Connection).to receive(:new).and_return(http_client)
    allow(http_response).to receive_messages(
      status: test_data[:response][:success][:status],
      body: test_data[:response][:success][:body]
    )
  end

  describe "#notify" do
    context "when sending raw string payload" do
      before do
        allow(http_client).to receive(:post).with(
          headers: { "Content-Type" => "application/json" },
          body: test_data[:raw]
        ).and_return(http_response)
      end

      it "sends the raw string without formatting" do
        response = notifier.notify(test_data[:raw])
        expect(response[:success]).to be true
        expect(http_client).to have_received(:post).with(
          headers: { "Content-Type" => "application/json" },
          body: test_data[:raw]
        )
      end
    end

    context "with platform configuration" do
      before do
        allow(http_client).to receive(:post).and_return(http_response)
      end

      it "uses Slack formatter by default" do
        notifier.notify(test_data[:json])
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("username" => "Bot Notifier")
          expect(payload).to include("icon_emoji" => ":robot_face:")
        end
      end

      it "uses Slack formatter when specified" do
        notifier.notify(test_data[:json], platform: :slack)
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("username" => "Bot Notifier")
          expect(payload).to include("icon_emoji" => ":robot_face:")
        end
      end

      it "uses Teams formatter when specified" do
        notifier.notify(test_data[:json], platform: :teams)
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("@type" => "MessageCard")
          expect(payload).to include("@context" => "http://schema.org/extensions")
        end
      end

      it "uses Mattermost formatter when specified" do
        notifier.notify(test_data[:json], platform: :mattermost)
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("username" => "Bot Notifier")
        end
      end
    end

    context "with default options" do
      let(:notifier_with_defaults) do
        described_class.new(test_data[:webhook_url], test_data[:options][:default])
      end

      before do
        allow(http_client).to receive(:post).and_return(http_response)
      end

      it "applies default options to formatted payload" do
        notifier_with_defaults.notify(test_data[:json], platform: :slack)
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("username" => test_data[:options][:default][:username])
          expect(payload["text"]).to include(test_data[:options][:default][:emoji])
        end
      end

      it "allows overriding default options" do
        notifier_with_defaults.notify(
          test_data[:json],
          platform: :slack,
          username: test_data[:options][:override][:username]
        )
        expect(http_client).to have_received(:post) do |args|
          payload = JSON.parse(args[:body])
          expect(payload).to include("username" => test_data[:options][:override][:username])
        end
      end
    end

    context "when the request fails" do
      before do
        allow(http_response).to receive_messages(
          status: test_data[:response][:failure][:status],
          body: test_data[:response][:failure][:body]
        )
        allow(http_client).to receive(:post).and_return(http_response)
      end

      it "returns a failure response" do
        response = notifier.notify(test_data[:json])
        expect(response[:success]).to be false
        expect(response[:status]).to eq(test_data[:response][:failure][:status])
        expect(response[:error]).to eq(test_data[:response][:failure][:body])
      end
    end
  end
end
