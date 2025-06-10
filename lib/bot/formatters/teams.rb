# frozen_string_literal: true

require_relative "base"

module Bot
  module Formatters
    class Teams < Base
      DEFAULT_CONFIG = {
        theme_color: "0078D7",
        context: "http://schema.org/extensions"
      }.freeze

      def format(message, options = {})
        opts = merge_options(options)

        {
          "@type": "MessageCard",
          "@context": opts[:context] || DEFAULT_CONFIG[:context],
          themeColor: opts[:theme_color] || DEFAULT_CONFIG[:theme_color],
          title: format_title(message, opts),
          text: format_text(message, opts),
          sections: format_sections(message)
        }.compact
      end

      private

      def format_title(message, opts)
        return opts[:title] if opts[:title]
        return message[:title] if message.is_a?(Hash) && message[:title]

        nil
      end

      def format_text(message, opts)
        text = message.is_a?(String) ? message : message[:text]
        return nil if text.nil? || text.empty?

        text = "#{opts[:emoji]} #{text}" if opts[:emoji]
        text
      end

      def format_sections(message)
        return nil unless valid_message_for_sections?(message)

        sections = if message[:sections]
                     format_existing_sections(message[:sections])
                   else
                     format_fields_as_sections(message[:fields])
                   end

        sections.nil? || sections.empty? ? nil : sections
      end

      def valid_message_for_sections?(message)
        return false unless message.is_a?(Hash)
        return false unless valid_content?(message)

        true
      end

      def valid_content?(message)
        has_sections = message[:sections] && !message[:sections].empty?
        has_fields = message[:fields] && !message[:fields].empty?
        has_sections || has_fields
      end

      def format_fields_as_sections(fields)
        facts = format_facts(fields)
        facts ? [{ facts: facts }.compact] : nil
      end

      def format_existing_sections(sections)
        return nil if sections.nil? || sections.empty?

        formatted = sections.map do |section|
          format_single_section(section)
        end

        formatted.reject(&:empty?)
      end

      def format_single_section(section)
        {
          activityTitle: section[:activity_title] || section[:activityTitle],
          activitySubtitle: section[:activity_subtitle] || section[:activitySubtitle],
          facts: section[:facts]
        }.compact
      end

      def format_facts(fields)
        return nil if fields.nil? || fields.empty?

        fields.map do |field|
          {
            name: field[:title],
            value: field[:value]
          }
        end
      end
    end
  end
end
