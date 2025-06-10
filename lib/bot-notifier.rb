# frozen_string_literal: true

require_relative "bot/notifier"
require_relative "bot/formatters/base"
require_relative "bot/formatters/slack"
require_relative "bot/formatters/teams"
require_relative "bot/formatters/mattermost"
require_relative "bot/capistrano"
require_relative "bot/mina" if defined?(Mina)
