# NovaCloud Client

A Ruby gem for interacting with the NovaCloud Open Platform API. This client provides:

- Manages configuration once (`app_key`, `app_secret`, `service_domain`).
- Handles authentication headers automatically via Faraday middleware.
- Maps HTTP errors to a typed exception hierarchy.
- Normalizes GET/POST payloads and parses JSON responses.

 Sprint 02 expands on this foundation with dedicated resource helpers (`client.players`, `client.control`, `client.scheduled_control`, `client.solutions`) and typed response objects (e.g., `NovacloudClient::Objects::Player`).

## Resource Overview

- **Players**: `list`, `statuses`, `running_status`
- **Control**: `brightness`, `volume`, `video_source`, `screen_power`, `screen_status`, `screenshot`, `reboot`, `ntp_sync`, `synchronous_playback`, `request_result`
- **Scheduled Control**: `screen_status`, `reboot`, `volume`, `brightness`, `video_source`
- **Solutions**: `emergency_page`, `cancel_emergency`, `common_solution`, `offline_export`, `set_over_spec_detection`, `program_over_spec_detection`
- **Screens** (VNNOXCare): `list`, `monitor`, `detail`
- **Logs**: `control_history`

> **Heads-up:** NovaCloud's public API docs (as of October 2025) do not expose
> "material" endpoints for uploading, listing, or deleting media assets. This
> client therefore expects assets to be hosted already (either uploaded via the
> VNNOX UI or served from your own CDN) and referenced by URL in solution
> payloads.

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

queue = client.players.config_status(
  player_ids: players.map(&:player_id),
  notice_url: "https://example.com/status-webhook"
)

client.control.ntp_sync(
  player_ids: players.map(&:player_id),
  server: "ntp1.aliyun.com",
  enable: true
)

client.scheduled_control.brightness(
  player_ids: players.map(&:player_id),
  schedules: {
    start_date: Date.today.strftime("%Y-%m-%d"),
    end_date: (Date.today + 30).strftime("%Y-%m-%d"),
    exec_time: "07:00:00",
    type: 0,
    value: 55
  }
)

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
puts screens.first.name

client.solutions.emergency_page(
  player_ids: [first_player.player_id],
  attribute: { duration: 20_000, normal_program_status: "PAUSE", spots_type: "IMMEDIATELY" },
  page: {
    name: "urgent-alert",
    widgets: [
      {
        type: "PICTURE",
        z_index: 1,
        duration: 10_000,
        url: "https://example.com/alert.png",
        layout: { x: "0%", y: "0%", width: "100%", height: "100%" }
      }
    ]
  }
)

offline_bundle = client.solutions.offline_export(
  program_type: 1,
  plan_version: "V2",
  pages: [
    {
      name: "main",
      widgets: [
        { type: "PICTURE", md5: "abc", url: "https://cdn.example.com/img.jpg" }
      ]
    }
  ]
)

puts offline_bundle.plan_json.url

over_spec_result = client.solutions.program_over_spec_detection(
  player_ids: [first_player.player_id],
  pages: [
    {
      page_id: 1,
      widgets: [
        { widget_id: 1, type: "VIDEO", url: "https://cdn.example.com/video.mp4", width: "3840", height: "2160" }
      ]
    }
  ]
)

if over_spec_result.items.any?(&:over_spec?)
  warn "Program exceeds specifications"
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
