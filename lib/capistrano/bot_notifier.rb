# frozen_string_literal: true

require "capistrano/plugin"
require "bot/notifier"

load File.expand_path("tasks/bot_notifier.rake", __dir__)
