# frozen_string_literal: true

require "capistrano/plugin"
require "bot/notifier"

# Only load Capistrano tasks if we're in a Capistrano context
load File.expand_path("tasks/bot_notifier.rake", __dir__) if defined?(Capistrano::Application)
