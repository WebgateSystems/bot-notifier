# frozen_string_literal: true

module Bot
  module Tasks
    module CapistranoHooks
      def self.register_hooks
        return unless defined?(::Capistrano::Configuration)

        # Register hooks for deployment events
        before "deploy:starting", "bot:starting"
        after "deploy:finished", "bot:finished"
        after "deploy:failed", "bot:failed"
      end

      def self.before(task_name, hook_task)
        return unless defined?(::Capistrano::Configuration)

        Rake::Task[task_name].enhance(Array(hook_task))
      end

      def self.after(task_name, hook_task)
        return unless defined?(::Capistrano::Configuration)

        task = Rake::Task[task_name]
        task.enhance do
          Rake::Task[hook_task].invoke
        end
      end
    end
  end
end
