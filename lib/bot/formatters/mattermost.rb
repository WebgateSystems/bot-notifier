# frozen_string_literal: true

require_relative "base"

module Bot
  module Formatters
    class Mattermost < Base
      DEFAULT_CONFIG = {
        username: "Bot Notifier",
        icon_url: nil
      }.freeze

      def format(message, options = {})
        opts = merge_options(options)

        {
          text: format_text(message, opts),
          channel: opts[:channel],
          username: opts[:username] || DEFAULT_CONFIG[:username],
          icon_url: opts[:icon_url] || DEFAULT_CONFIG[:icon_url],
          props: format_props(message, opts)
        }.compact
      end

      private

      def format_text(message, opts)
        text = message.is_a?(String) ? message : message[:text]
        return nil if text.nil? || text.empty?

        text = "#{opts[:emoji]} #{text}" if opts[:emoji]
        format_markdown(text, opts)
      end

      def format_markdown(text, opts)
        return text unless opts[:format_markdown]

        # Convert basic formatting
        text = text.gsub("**", "**") # Bold stays the same
                   .gsub("_", "_")      # Italic stays the same
                   .gsub("~", "~~")     # Strikethrough uses double tilde
                   .gsub("`", "`")      # Code stays the same

        # Add headers if specified
        text = "### #{text}" if opts[:header]
        text
      end

      def format_props(message, opts)
        props = {}

        card = extract_card_content(message, opts)
        props[:card] = format_markdown(card, opts) if card

        attachments = extract_attachments(message)
        props[:attachments] = attachments if attachments

        props.empty? ? nil : props
      end

      def extract_card_content(message, opts)
        return message[:card] if message.is_a?(Hash) && message[:card]
        return opts[:card] if opts[:card]
        return format_fields_as_card(message[:fields]) if message.is_a?(Hash) && message[:fields]

        nil
      end

      def extract_attachments(message)
        message.is_a?(Hash) && message[:attachments] ? message[:attachments] : nil
      end

      def format_fields_as_card(fields)
        return nil if fields.nil? || fields.empty?

        fields.map do |field|
          "**#{field[:title]}**: #{field[:value]}"
        end.join("\n")
      end
    end
  end
end
