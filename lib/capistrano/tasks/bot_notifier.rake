# frozen_string_literal: true

namespace :load do
  desc "Default settings definition"
  task :defaults do
    set :bn_color, true
    set :bn_messenger, :slack
    set :bn_room, "#platform"
    set :bn_username, "capistrano"
    set :bn_emoji, ":rocket:"
  end
end

namespace :bn do
  include Capistrano::BotNotifier::DSL

  desc "Notify team messenger that the deploy has started"
  task :starting do
    run_locally do
      post_to_channel(:grey, "#{deployer} is deploying #{deploy_target} to #{destination}")
      set(:start_time, Time.now)
    end
  end

  desc "Notify team messenger that the deploy has completed successfully"
  task :finished do
    run_locally do
      msg = "#{deployer} deployed #{deploy_target} to #{destination} *successfully*"

      msg << if (start_time = fetch(:start_time, nil))
               " in #{Time.now.to_i - start_time.to_i} seconds."
             else
               "."
             end

      post_to_channel(:green, msg)
    end
  end

  desc "Notify team messenger that the deploy failed"
  task :failed do
    run_locally do
      post_to_channel(:red, "#{deployer} *failed* to deploy #{deploy_target} to #{destination}")
    end
  end

  desc "Notify team messenger that the deploy was reverted"
  task :reverted do
    run_locally do
      post_to_channel(:red, "#{deployer} has rolled back #{deploy_target}")
    end
  end

  desc "Notify team messenger that the deploy was rolled back"
  task :rolled_back do
    run_locally do
      post_to_channel(:red, "#{deployer} has rolled back #{deploy_target}")
    end
  end
end

# Register hooks if we're in a Capistrano environment
if defined?(Capistrano)
  after "deploy:starting", "bn:starting"
  after "deploy:finishing", "bn:finished"
  after "deploy:failed", "bn:failed"
  after "deploy:reverting", "bn:reverted"
  after "deploy:rollback", "bn:rolled_back"
end
