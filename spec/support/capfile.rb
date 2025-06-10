# frozen_string_literal: true

# Load core Capistrano functionality first
require "capistrano/configuration"
require "capistrano/dsl"

# Load airbrussh before setup
require "airbrussh"
require "airbrussh/capistrano"

# Configure airbrussh
Airbrussh.configure do |config|
  config.log_file = nil
  config.truncate = false
  config.color = false
end

# Load DSL and Setup Up Stages last
require "capistrano/setup"
require "capistrano/deploy"
