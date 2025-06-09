# frozen_string_literal: true

require "capistrano/all"
require "active_support"
require "net/http"
require "json"

module Capistrano
  module BotNotifier
    module DSL
      HEX_COLORS = {
        grey: "#CCCCCC",
        red: "#BB0000",
        green: "#7CD197",
        blue: "#103FFB"
      }.freeze

      MESSENGER_TYPES = %i[slack mattermost teams].freeze

      def post_to_channel(color, message)
        payload = case messenger_type
                  when :mattermost
                    mattermost_payload(color, message)
                  when :teams
                    teams_payload(color, message)
                  else # default to slack
                    slack_payload(color, message)
                  end

        call_webhook_api(payload)
      end

      def call_webhook_api(payload)
        uri = URI.parse(fetch(:bn_webhook_url))
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data(payload: payload)
        http.request(request)
      rescue SocketError => e
        warn "#{e.message} or webhook endpoint may be down"
      end

      def slack_payload(color, announcement)
        if use_color?
          {
            "channel" => bn_channel,
            "username" => bn_username,
            "icon_emoji" => bn_emoji,
            "attachments" => [{
              "fallback" => announcement,
              "text" => announcement,
              "color" => HEX_COLORS[color],
              "mrkdwn_in" => %w[text]
            }]
          }.to_json
        else
          {
            "channel" => bn_channel,
            "username" => bn_username,
            "text" => announcement,
            "icon_emoji" => bn_emoji,
            "mrkdwn" => true
          }.to_json
        end
      end

      def mattermost_payload(color, announcement)
        text = if use_color?
                 "#{emoji_for_color(color)} #{announcement}"
               else
                 "#{bn_emoji} #{announcement}"
               end

        {
          "channel" => bn_channel,
          "username" => bn_username,
          "text" => text,
          "icon_url" => fetch(:bn_icon_url, nil),
          "type" => "custom_mattermost"
        }.to_json
      end

      def emoji_for_color(color)
        case color
        when :green
          ":white_check_mark:"
        when :red
          ":x:"
        when :blue
          ":information_source:"
        else
          ":arrow_right:"
        end
      end

      def teams_payload(color, announcement)
        {
          "title" => bn_username,
          "text" => announcement,
          "themeColor" => use_color? ? HEX_COLORS[color] : nil
        }.to_json
      end

      def use_color?
        fetch(:bn_color, true)
      end

      def messenger_type
        type = fetch(:bn_messenger, :slack).to_sym
        MESSENGER_TYPES.include?(type) ? type : :slack
      end

      def bn_channel
        fetch(:bn_room, "#platform")
      end

      def bn_username
        fetch(:bn_username, "capistrano")
      end

      def bn_emoji
        fetch(:bn_emoji, ":rocket:")
      end

      def bn_app_name
        fetch(:bn_app_name, fetch(:application))
      end

      def deployer
        fetch(:deployer, ENV["USER"] || ENV["GIT_AUTHOR_NAME"] || `git config user.name`.chomp)
      end

      def stage
        fetch(:stage, "production")
      end

      def destination
        fetch(:bn_destination, stage)
      end

      def repository
        fetch(:repo_url, "origin")
      end

      def revision_from_branch
        `git ls-remote #{repository} #{branch}`.split.first
      end

      def rev
        @rev ||= if @branch.nil?
                   fetch(:current_revision)
                 else
                   revision_from_branch
                 end
      end

      def branch
        @branch ||= fetch(:branch, nil)
      end

      def bn_app_and_branch
        if branch.nil?
          bn_app_name
        else
          [bn_app_name, branch].join("/")
        end
      end

      def deploy_target
        bn_app_and_branch + (rev ? " (#{rev[0..5]})" : "")
      end
    end
  end
end
