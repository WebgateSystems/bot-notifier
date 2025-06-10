# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bot::Formatters::Base do
  let(:config) { { key: "value" } }
  let(:formatter) { described_class.new(config) }

  describe "#initialize" do
    it "stores the config" do
      expect(formatter.config).to eq(config)
    end

    it "defaults to empty hash when no config provided" do
      expect(described_class.new.config).to eq({})
    end
  end

  describe "#format" do
    it "raises NotImplementedError" do
      expect { formatter.format("message") }.to raise_error(NotImplementedError, "Subclasses must implement format method")
    end
  end

  describe "#merge_options" do
    let(:options) { { another_key: "another_value" } }

    it "merges config with provided options" do
      result = formatter.send(:merge_options, options)
      expect(result).to eq(config.merge(options))
    end

    it "does not modify the original config" do
      formatter.send(:merge_options, options)
      expect(formatter.config).to eq(config)
    end
  end
end
