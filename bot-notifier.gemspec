# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "bot-notifier"
  spec.version       = "3.0.1"
  spec.authors       = ["Jerzy Sładkowski"]
  spec.email         = ["jerzy.sladkowski@gmail.com"]
  spec.summary       = "Bot notifier for team messengers like Slack or Mattermost, based on https://github.com/parkr/capistrano-slack-notify"
  spec.homepage      = "https://github.com/WebgateSystems/bot-notifier"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = `git ls-files -z`.split("\x0").grep(%r{^(bin|lib)/})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "capistrano", "~> 3.0"
  spec.add_dependency "sshkit", "~> 1.21"
end
