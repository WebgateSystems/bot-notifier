# frozen_string_literal: true

require "rspec"
require "rspec/its"
require "webmock/rspec"
require "rake"
require "sshkit"
require "capistrano"
require "capistrano/dsl"
require "capistrano/setup"
require "capistrano/deploy"
require "bot-notifier"

# Load Capistrano framework tasks
load "capistrano/tasks/framework.rake"

RSpec.configure do |config|
  config.include WebMock::API
  config.include Capistrano::DSL

  config.before(:suite) do
    WebMock.disable_net_connect!
  end

  config.after(:suite) do
    WebMock.allow_net_connect!
  end

  config.before do
    # Reset Capistrano configuration before each test
    Capistrano::Configuration.reset!

    # Reset WebMock stubs before each test
    WebMock.reset!
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    Rake.application = Rake::Application.new
  end
end
