# frozen_string_literal: true

require "bot/tasks/notifier"
require_relative "bot_notifier/helpers"
require_relative "bot_notifier/deploy_tasks"

namespace :bot do
  include Bot::Tasks::NotifierHelpers
  Bot::Tasks::DeployTasks.register_tasks

  desc "Send notification about starting deployment"
  task :starting do
    Bot::Tasks::Notifier.notify(
      "#{deployer} is deploying #{app_name} to #{destination}",
      fields: notification_fields
    )
  end

  desc "Send notification about finished deployment"
  task :finished do
    Bot::Tasks::Notifier.notify(
      "#{deployer} finished deploying #{app_name} to #{destination}",
      fields: notification_fields
    )
  end

  desc "Send notification about failed deployment"
  task :failed do
    Bot::Tasks::Notifier.notify(
      "Failed to deploy #{app_name} to #{destination}",
      color: "#ff0000",
      fields: notification_fields
    )
  end

  desc "Send test notification"
  task :test do
    Bot::Tasks::Notifier.notify(
      "Test notification from #{app_name}",
      fields: notification_fields
    )
  end
end
