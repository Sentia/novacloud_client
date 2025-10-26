# NovaCloud Client (WIP)

Sprint 01 delivered the core HTTP client for the NovaCloud Open Platform. The gem now:

- Manages configuration once (`app_key`, `app_secret`, `service_domain`).
- Handles authentication headers automatically via Faraday middleware.
- Maps HTTP errors to a typed exception hierarchy.
- Normalizes GET/POST payloads and parses JSON responses.

Sprint 02 expands on this foundation with dedicated resource helpers (`client.players`, `client.control`) and typed response objects (e.g., `NovacloudClient::Objects::Player`).

## Quick Start

```ruby
require "novacloud_client"

client = NovacloudClient::Client.new(
  app_key: "YOUR_APP_KEY",
  app_secret: "YOUR_APP_SECRET",
  service_domain: "open-us.vnnox.com"
)

players = client.players.list(count: 20)
first_player = players.first

statuses = client.players.statuses(player_ids: players.map(&:player_id))

request = client.control.brightness(
  player_ids: players.map(&:player_id),
  brightness: 80,
  notice_url: "https://example.com/callback"
)

result = client.control.request_result(request_id: request.request_id)
puts result.all_successful?
```

### Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

### Documentation

Run YARD to generate HTML API documentation for the gem:

```bash
bundle exec yard doc
```

Then browse the docs via the generated `doc/index.html` or launch a local server with `bundle exec yard server --reload`.
