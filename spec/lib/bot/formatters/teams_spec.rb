# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bot::Formatters::Teams do
  let(:config) { {} }
  let(:formatter) { described_class.new(config) }

  describe "#format" do
    context "with string message" do
      it "formats basic text message" do
        result = formatter.format("Hello World")
        expect(result).to include(
          "@type": "MessageCard",
          "@context": "http://schema.org/extensions",
          themeColor: "0078D7",
          text: "Hello World"
        )
      end

      it "respects emoji option" do
        result = formatter.format("Hello World", emoji: ":tada:")
        expect(result[:text]).to eq(":tada: Hello World")
      end

      it "respects theme_color override" do
        result = formatter.format("Hello", theme_color: "FF0000")
        expect(result[:themeColor]).to eq("FF0000")
      end

      it "respects title option" do
        result = formatter.format("Hello", title: "Custom Title")
        expect(result[:title]).to eq("Custom Title")
      end
    end

    context "with hash message" do
      let(:message) do
        {
          title: "Notification",
          text: "Hello World",
          fields: [
            { title: "Status", value: "OK" },
            { title: "Environment", value: "Production" }
          ]
        }
      end

      it "formats message with fields as facts" do
        result = formatter.format(message)
        expect(result[:sections].first[:facts]).to eq([
                                                        { name: "Status", value: "OK" },
                                                        { name: "Environment", value: "Production" }
                                                      ])
      end

      it "uses message title" do
        result = formatter.format(message)
        expect(result[:title]).to eq("Notification")
      end
    end

    context "with sections" do
      let(:message) do
        {
          text: "Main message",
          sections: [
            {
              activity_title: "Deploy",
              activity_subtitle: "Production",
              facts: [
                { name: "Status", value: "Success" }
              ]
            }
          ]
        }
      end

      it "preserves section structure" do
        result = formatter.format(message)
        expect(result[:sections]).to eq([{
                                          activityTitle: "Deploy",
                                          activitySubtitle: "Production",
                                          facts: [{ name: "Status", value: "Success" }]
                                        }])
      end

      it "handles camelCase section properties" do
        message[:sections][0] = {
          activityTitle: "Deploy",
          activitySubtitle: "Production",
          facts: [{ name: "Status", value: "Success" }]
        }
        result = formatter.format(message)
        expect(result[:sections].first[:activityTitle]).to eq("Deploy")
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

      it "removes empty sections" do
        result = formatter.format({ text: "Hello", fields: [] })
        expect(result.keys).not_to include(:sections)
      end
    end
  end
end
