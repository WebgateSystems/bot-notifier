# frozen_string_literal: true

require_relative "base"

module Bot
  module Formatters
    class Slack < Base
      DEFAULT_CONFIG = {
        username: "Bot Notifier",
        icon_emoji: ":robot_face:",
        color: "#36a64f"
      }.freeze

      def format(message, options = {})
        opts = merge_options(options)

        {
          text: format_text(message, opts),
          channel: opts[:channel] || opts[:slack_destination],
          username: opts[:slack_app_name] || opts[:username] || DEFAULT_CONFIG[:username],
          icon_emoji: opts[:icon_emoji] || DEFAULT_CONFIG[:icon_emoji],
          attachments: format_attachments(message, opts)
        }.compact
      end

      private

      def format_text(message, opts)
        text = message.is_a?(String) ? message : message[:text]
        return nil if text.nil? || text.empty?

        text = "#{opts[:emoji]} #{text}" if opts[:emoji]
        text
      end

      def format_attachments(message, opts)
        return nil if message.is_a?(String)
        return message[:attachments] if message[:attachments]

        [{
          fallback: format_text(message, opts),
          color: opts[:color] || DEFAULT_CONFIG[:color],
          text: format_text(message, opts),
          fields: format_fields(message, opts)
        }.compact]
      end

      def format_fields(message, _opts)
        return nil unless message.is_a?(Hash) && message[:fields]

        message[:fields].map do |field|
          {
            title: field[:title],
            value: field[:value],
            short: field[:short]
          }.compact
        end
      end
    end
  end
end
