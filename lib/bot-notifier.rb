# frozen_string_literal: true

# Core functionality
require_relative "bot/version"
require_relative "bot/notifier"
require_relative "bot/formatters/base"
require_relative "bot/formatters/slack"
require_relative "bot/formatters/teams"
require_relative "bot/formatters/mattermost"
require_relative "bot/tasks/notifier"

# Load deployment integrations
require_relative "bot/capistrano" if defined?(Capistrano::Configuration)
require_relative "bot/mina" if defined?(Mina)

module Bot
  class Error < StandardError; end
end
