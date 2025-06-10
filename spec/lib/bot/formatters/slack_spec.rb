# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bot::Formatters::Slack do
  let(:config) { {} }
  let(:formatter) { described_class.new(config) }

  describe "#format" do
    context "with string message" do
      it "formats basic text message" do
        result = formatter.format("Hello World")
        expect(result).to include(
          text: "Hello World",
          username: "Bot Notifier",
          icon_emoji: ":robot_face:"
        )
      end

      it "respects emoji option" do
        result = formatter.format("Hello World", emoji: ":tada:")
        expect(result[:text]).to eq(":tada: Hello World")
      end

      it "respects channel override" do
        result = formatter.format("Hello", channel: "#custom")
        expect(result[:channel]).to eq("#custom")
      end

      it "respects slack_destination override" do
        result = formatter.format("Hello", slack_destination: "#override")
        expect(result[:channel]).to eq("#override")
      end

      it "respects slack_app_name override" do
        result = formatter.format("Hello", slack_app_name: "Custom Bot")
        expect(result[:username]).to eq("Custom Bot")
      end
    end

    context "with hash message" do
      let(:message) do
        {
          text: "Hello World",
          fields: [
            { title: "Status", value: "OK", short: true },
            { title: "Environment", value: "Production", short: true }
          ]
        }
      end

      it "formats message with fields" do
        result = formatter.format(message)
        expect(result[:attachments].first).to include(
          color: "#36a64f",
          text: "Hello World",
          fields: [
            { title: "Status", value: "OK", short: true },
            { title: "Environment", value: "Production", short: true }
          ]
        )
      end

      it "respects color override" do
        result = formatter.format(message, color: "#ff0000")
        expect(result[:attachments].first[:color]).to eq("#ff0000")
      end
    end

    context "with attachments" do
      let(:message) do
        {
          text: "Main message",
          attachments: [
            {
              fallback: "Required plain-text summary",
              color: "#ff0000",
              pretext: "Optional text above the attachment",
              text: "Optional text that appears within the attachment"
            }
          ]
        }
      end

      it "preserves original attachments" do
        result = formatter.format(message)
        expect(result[:attachments]).to eq(message[:attachments])
      end
    end

    context "with empty or nil values" do
      it "removes nil values" do
        result = formatter.format({ text: nil })
        expect(result.keys).not_to include(:text)
      end

      it "removes empty text" do
        result = formatter.format({ text: "" })
        expect(result.keys).not_to include(:text)
      end
    end
  end
end
