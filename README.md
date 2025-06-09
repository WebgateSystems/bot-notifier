# Bot::Notifier

Deploy notifier for team messangers like Slack, Mattermost or Teams. Based on https://github.com/parkr/capistrano-slack-notify.

![Sample Slack output for success.](https://raw.githubusercontent.com/WebgateSystems/bot-notifier/main/screenshot.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bot-notifier'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bot-notifier

## Usage

`bot-notifier` defines two tasks:

Add the following to your `Capfile`:

```ruby
require 'bot-notifier'
```

That's it! It'll send 2 messages to `#general` as the `capistrano` user when you deploy.

The tasks are:

- `bn:starting`    - the intent-to-deploy message
- `bn:finished`    - the completion message
- `bn:failed`      - the failure message
- `bn:rolled_back` - the rollback message

**None of the tasks are automatically added**, you have to do that yourself,
like in the usage example above.

You can optionally set some other parameters to customize the output:

```ruby
set :bn_webhook_url,   "https://hooks.slack.com/services/XXX/XXX/XXX"
set :bn_messenger, :mattermost # defaults to :slack, also supports :teams
set :bn_room,     '#my_channel' # defaults to #platform
set :bn_username, 'my-company-bot' # defaults to 'capistrano'
set :bn_emoji,    ':ghost:' # defaults to :rocket:
set :bn_icon_url, 'https://example.com/bot-icon.png' # optional, for Mattermost
set :deployer,       ENV['USER'].capitalize # defaults to ENV['USER']
set :bn_app_name, 'example-app' # defaults to :application
set :bn_color,    false # defaults to true
set :bn_destination, fetch(:stage, 'production') # where your code is going
```

### Messenger Types

The gem supports different messenger platforms with their specific message formats:

- `:slack` (default) - Uses Slack's attachment format for colored messages
- `:mattermost` - Uses status emojis to indicate message type:
  - Starting: `:arrow_right:`
  - Success: `:white_check_mark:`
  - Failure/Rollback: `:x:`
  - Info: `:information_source:`
- `:teams` - Uses Microsoft Teams' message card format

Each platform has its own way of handling colors and formatting. Set `:bn_messenger` to match your platform for the best results.

For Mattermost, you can optionally set a custom icon URL using `:bn_icon_url`. This is useful if you want to use a custom bot icon instead of an emoji.

## Contributing

1. Fork it ( https://github.com/WebgateSystems/bot-notifier/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
