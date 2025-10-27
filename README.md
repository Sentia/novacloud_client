# NovaCloud Client

A Ruby gem for interacting with the NovaCloud Open Platform API. This client provides:

- Simple configuration with `app_key`, `app_secret`, and `service_domain`
- Automatic authentication headers via Faraday middleware
- Typed exception hierarchy for HTTP errors
- JSON request/response handling
- Resource-based API wrappers with typed response objects

## Resource Overview

The gem currently implements the following NovaCloud API resources:

- **Players**: `list`, `statuses`, `running_status` - Player management and status queries
- **Control**: `brightness`, `volume`, `video_source`, `screen_power`, `screen_status`, `screenshot`, `reboot`, `request_result` - Real-time player control commands
- **Screens** (VNNOXCare): `list`, `monitor`, `detail` - Screen device status monitoring
- **Logs**: `control_history` - Control command execution history

**Note**: The gem focuses on the most commonly used endpoints. Additional endpoints like Solutions (emergency insertion, offline export), Scheduled Control, and Play Logs are not yet implemented but can be added based on demand.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'novacloud_client'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install novacloud_client
```

## Quick Start

```ruby
require "novacloud_client"

# Initialize the client
client = NovacloudClient::Client.new(
  app_key: "YOUR_APP_KEY",
  app_secret: "YOUR_APP_SECRET",
  service_domain: "open-us.vnnox.com"
)

# List players
players = client.players.list(count: 20)
puts "Found #{players.size} players"

# Get player statuses
statuses = client.players.statuses(player_ids: players.map(&:player_id))
statuses.each do |status|
  puts "Player #{status.player_id}: online=#{status.online?}"
end

# Control player brightness
request = client.control.brightness(
  player_ids: players.map(&:player_id),
  brightness: 80,
  notice_url: "https://example.com/callback"
)

# Check control request result
result = client.control.request_result(request_id: request.request_id)
puts "All successful? #{result.all_successful?}"

# List screens (VNNOXCare)
screens = client.screens.list(status: 1)
puts "Screen: #{screens.first.name}" if screens.any?

# View control command history
logs = client.logs.control_history(player_id: players.first.player_id)
logs.each do |log|
  puts "#{log.time}: #{log.task_name} - #{log.status}"
end
```

## API Coverage

This gem currently covers the following NovaCloud API categories:

- ✅ **Player Management**: List players, get player statuses
- ✅ **Real-Time Control**: Brightness, volume, video source, screen power/status, screenshot, reboot
- ✅ **VNNOXCare Monitoring**: Screen list, monitor, detail
- ✅ **Logs**: Control command history
- ❌ **Solutions**: Emergency insertion, offline export, over-spec detection (not yet implemented)
- ❌ **Scheduled Control**: Scheduled brightness, volume, screen status, reboot (not yet implemented)
- ❌ **Play Logs**: Batch play log queries (not yet implemented)
- ❌ **Notifications**: Video source/solution change notifications (not yet implemented)

**Material API Note**: NovaCloud's public API documentation (as of October 2025) does not expose material upload/management endpoints. Assets must be hosted externally or uploaded via the NovaCloud web UI before being referenced in API calls.

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Lint code
```

## Documentation

Generate YARD API documentation:

```bash
bundle exec yard doc
```

Then browse `doc/index.html` or launch a local server:

```bash
bundle exec yard server --reload
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [github.com/Sentia/novacloud_client](https://github.com/Sentia/novacloud_client).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
