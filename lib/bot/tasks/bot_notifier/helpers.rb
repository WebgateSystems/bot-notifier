# frozen_string_literal: true

module Bot
  module Tasks
    module NotifierHelpers
      module_function

      def notification_fields
        [
          { title: "App", value: Bot::Tasks::Notifier.send(:fetch, :bn_app_name), short: true },
          { title: "Environment", value: Bot::Tasks::Notifier.send(:fetch, :bn_destination), short: true },
          { title: "Branch", value: Bot::Tasks::Notifier.send(:fetch, :branch), short: true },
          { title: "Deployer", value: Bot::Tasks::Notifier.send(:fetch, :deployer), short: true }
        ]
      end

      def deployer
        Bot::Tasks::Notifier.send(:fetch, :deployer)
      end

      def app_name
        Bot::Tasks::Notifier.send(:fetch, :bn_app_name)
      end

      def destination
        Bot::Tasks::Notifier.send(:fetch, :bn_destination)
      end
    end
  end
end
