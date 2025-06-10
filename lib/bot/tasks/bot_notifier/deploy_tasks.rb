# frozen_string_literal: true

module Bot
  module Tasks
    module DeployTasks
      extend NotifierHelpers

      def self.register_tasks
        Rake::Task.define_task("bot:starting") do
          Bot::Tasks::Notifier.notify(
            "#{deployer} is deploying #{app_name} to #{destination}",
            fields: notification_fields
          )
        end

        Rake::Task.define_task("bot:finished") do
          Bot::Tasks::Notifier.notify(
            "#{deployer} finished deploying #{app_name} to #{destination}",
            fields: notification_fields
          )
        end

        Rake::Task.define_task("bot:failed") do
          Bot::Tasks::Notifier.notify(
            "Failed to deploy #{app_name} to #{destination}",
            color: "#ff0000",
            fields: notification_fields
          )
        end

        Rake::Task.define_task("bot:test") do
          Bot::Tasks::Notifier.notify(
            "Test notification from #{app_name}",
            fields: notification_fields
          )
        end
      end
    end
  end
end
