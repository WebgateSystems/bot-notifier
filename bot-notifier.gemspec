# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "bot-notifier"
  spec.version       = "4.0.1"
  spec.authors       = ["Jerzy Sładkowski"]
  spec.email         = ["jerzy.sladkowski@gmail.com"]
  spec.summary       = "A flexible notification sender that can push JSON payloads to any webhook URL"
  spec.description   = "Simple HTTP notification sender for any messenger platform like Mattermost, Slack " \
                       "or Microsoft Teams. Feel free to add your own, favorite messanger :)"
  spec.homepage      = "https://github.com/WebgateSystems/bot-notifier"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[README.md LICENSE.txt]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "json", "~> 2.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
