# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bot::Formatters::Mattermost do
  let(:config) { {} }
  let(:formatter) { described_class.new(config) }

  describe "#format" do
    context "with string message" do
      it "formats basic text message" do
        result = formatter.format("Hello World")
        expect(result).to include(
          text: "Hello World",
          username: "Bot Notifier"
        )
      end

      it "respects emoji option" do
        result = formatter.format("Hello World", emoji: ":tada:")
        expect(result[:text]).to eq(":tada: Hello World")
      end

      it "respects channel override" do
        result = formatter.format("Hello", channel: "town-square")
        expect(result[:channel]).to eq("town-square")
      end

      it "respects username override" do
        result = formatter.format("Hello", username: "Custom Bot")
        expect(result[:username]).to eq("Custom Bot")
      end

      it "respects icon_url override" do
        result = formatter.format("Hello", icon_url: "https://example.com/icon.png")
        expect(result[:icon_url]).to eq("https://example.com/icon.png")
      end
    end

    context "with markdown formatting" do
      it "preserves markdown when format_markdown is true" do
        result = formatter.format("**Bold** and _italic_", format_markdown: true)
        expect(result[:text]).to eq("**Bold** and _italic_")
      end

      it "adds header when specified" do
        result = formatter.format("Important", format_markdown: true, header: true)
        expect(result[:text]).to eq("### Important")
      end

      it "converts strikethrough syntax" do
        result = formatter.format("~strike~", format_markdown: true)
        expect(result[:text]).to eq("~~strike~~")
      end
    end

    context "with hash message" do
      let(:message) do
        {
          text: "Hello World",
          fields: [
            { title: "Status", value: "OK" },
            { title: "Environment", value: "Production" }
          ]
        }
      end

      it "formats fields as card in props" do
        result = formatter.format(message)
        expected_card = "**Status**: OK\n**Environment**: Production"
        expect(result[:props][:card]).to eq(expected_card)
      end

      it "formats fields with markdown when specified" do
        result = formatter.format(message, format_markdown: true)
        expected_card = "**Status**: OK\n**Environment**: Production"
        expect(result[:props][:card]).to eq(expected_card)
      end
    end

    context "with card" do
      it "includes card in props from message" do
        result = formatter.format({ text: "Hello", card: "Card content" })
        expect(result[:props][:card]).to eq("Card content")
      end

      it "includes card in props from options" do
        result = formatter.format("Hello", card: "Card content")
        expect(result[:props][:card]).to eq("Card content")
      end

      it "formats card with markdown when specified" do
        result = formatter.format({ text: "Hello", card: "**Bold** card" }, format_markdown: true)
        expect(result[:props][:card]).to eq("**Bold** card")
      end
    end

    context "with attachments" do
      let(:attachments) do
        [{
          title: "Attachment",
          text: "Some text"
        }]
      end

      it "preserves attachments in props" do
        result = formatter.format({ text: "Hello", attachments: attachments })
        expect(result[:props][:attachments]).to eq(attachments)
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

      it "removes empty props" do
        result = formatter.format({ text: "Hello", fields: [] })
        expect(result.keys).not_to include(:props)
      end
    end
  end
end
