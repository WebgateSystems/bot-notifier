# frozen_string_literal: true

require "bundler/setup"
require "bot-notifier"
require "rake"

# Only require deployment gems when needed
module DeploymentHelpers
  def self.require_capistrano
    # First load SSHKit to avoid circular requires with airbrussh
    require "sshkit"
    # Then load capistrano core without airbrussh
    require "capistrano/all"
    # Now load our capistrano integration
    require "bot/capistrano"
  end

  def self.require_mina
    require "mina"
    require "bot/mina"
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before do
    # Reset Rake application for each test
    Rake.application = Rake::Application.new
    # Include Rake DSL
    include Rake::DSL if defined?(Rake::DSL)
    # Reset Capistrano configuration before each test
    Capistrano::Configuration.reset! if defined?(Capistrano::Configuration)
  end
end
