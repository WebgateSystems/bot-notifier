# frozen_string_literal: true

# Filter out circular dependency warnings from Capistrano and Airbrussh
Warning.module_eval do
  def self.warn(message)
    if message.include?("warning: loading in progress, circular require considered harmful") && (message.include?("capistrano") || message.include?("airbrussh"))
      return
    end

    super
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundler/setup"

# Load Rake first
require "rake"

# Load SSHKit
require "sshkit"
require "sshkit/dsl"

module DeploymentHelpers
  def self.require_capistrano
    # Load our test Capfile which handles all Capistrano setup
    require_relative "support/capfile"
  end

  def self.require_mina
    require "mina"
  end
end

# Load our gem
require "bot-notifier"

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
