# frozen_string_literal: true

require "http_client"
require "json"
require_relative "formatters/base"
require_relative "formatters/slack"
require_relative "formatters/teams"
require_relative "formatters/mattermost"

module Bot
  class Notifier
    attr_reader :webhook_url, :default_options

    def initialize(webhook_url, default_options = {})
      @webhook_url = webhook_url
      @default_options = default_options
    end

    def notify(payload, options = {})
      opts = default_options.merge(options)
      formatted_payload = format_payload(payload, opts)

      response = client.post(
        headers: { "Content-Type" => "application/json" },
        body: formatted_payload.is_a?(String) ? formatted_payload : formatted_payload.to_json
      )

      handle_response(response)
    end

    private

    def client
      @client ||= WS::HttpClient::Connection.new(webhook_url)
    end

    def handle_response(response)
      case response.status
      when 200..299
        { success: true, status: response.status, body: response.body }
      else
        { success: false, status: response.status, error: response.body }
      end
    end

    def format_payload(payload, options)
      return payload if payload.is_a?(String)

      formatter = detect_formatter(options)
      formatter.format(payload, options)
    end

    def detect_formatter(options)
      klass = case options[:platform]&.to_s&.downcase
              when "teams"
                Formatters::Teams
              when "mattermost"
                Formatters::Mattermost
              else # Use Slack as default for both "slack" and nil cases
                Formatters::Slack
              end

      klass.new(default_options)
    end
  end
end
