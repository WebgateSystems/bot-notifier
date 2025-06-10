# Bot Notifier

A Ruby gem for sending deployment notifications to various messaging platforms (Slack, Microsoft Teams, Mattermost).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bot-notifier'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install bot-notifier
```

## Usage

### Basic Usage

```ruby
bn = Bot::Notifier.new('YOUR_WEBHOOK_URL')
bn.notify('Hello from Bot Notifier!')
```

### Capistrano Integration

Add to your `config/deploy.rb`:

```ruby
require 'bot-notifier'

# Required settings
set :bn_webhook_url, 'YOUR_WEBHOOK_URL'

# Optional settings with defaults
set :bn_messenger, :slack          # :slack, :teams, or :mattermost
set :bn_room, '#deployments'       # Channel/room to post to
set :bn_username, 'DeployBot'      # Bot username
set :bn_emoji, ':rocket:'          # Bot emoji
set :bn_app_name, 'my-app'         # Defaults to :application
set :bn_color, true                # Enable/disable colors
set :bn_destination, 'production'   # Defaults to :stage or 'staging'
set :deployer, ENV.fetch('USER', nil).capitalize # Who is deploying
```

The integration will automatically:
- Send a notification when deployment starts
- Send a notification when deployment finishes successfully
- Send a notification when deployment fails

You can also test the notifications with:
```bash
cap <stage> bot:test
```

### Mina Integration

Add to your `config/deploy.rb`:

```ruby
require 'bot-notifier'

# Required settings
set :bn_webhook_url, 'YOUR_WEBHOOK_URL'

# Optional settings with defaults
set :bn_messenger, :slack          # :slack, :teams, or :mattermost
set :bn_room, '#deployments'       # Channel/room to post to
set :bn_username, 'DeployBot'      # Bot username
set :bn_emoji, ':rocket:'          # Bot emoji
set :bn_app_name, 'my-app'         # Defaults to :application_name
set :bn_color, true                # Enable/disable colors
set :bn_destination, 'production'   # Defaults to :stage or :rails_env or 'staging'
set :deployer, ENV.fetch('USER', nil).capitalize # Who is deploying

# Important: Initialize the bot notifier hooks
Bot::Mina.setup!
```

The `setup!` call is required to initialize the Mina hooks. Once initialized, the integration will automatically:
- Send a notification when deployment starts
- Send a notification when deployment finishes successfully
- Send a notification when deployment fails

### Platform-Specific Features

#### Slack
- Supports message formatting with emojis
- Customizable username and channel
- Colored attachments
- Fields and sections

#### Microsoft Teams
- Supports message cards
- Theme colors
- Sections and facts
- Rich text formatting

#### Mattermost
- Supports Markdown formatting
- Custom props
- Message cards
- Channel overrides

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the MIT License.
