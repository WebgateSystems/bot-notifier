# frozen_string_literal: true

# Load core Capistrano functionality
require "capistrano/dsl"
require "capistrano/configuration"

# Load DSL and Setup Up Stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Load airbrussh
require "airbrussh/capistrano"

# Configure airbrussh
Airbrussh.configure do |config|
  config.log_file = nil
  config.truncate = false
  config.color = false
end
