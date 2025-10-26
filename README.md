# NovaCloud Client (WIP)

Sprint 01 delivered the core HTTP client for the NovaCloud Open Platform. The gem now:

- Manages configuration once (`app_key`, `app_secret`, `service_domain`).
- Handles authentication headers automatically via Faraday middleware.
- Maps HTTP errors to a typed exception hierarchy.
- Normalizes GET/POST payloads and parses JSON responses.

## Quick Start

```ruby
require "novacloud_client"

client = NovacloudClient::Client.new(
  app_key: "YOUR_APP_KEY",
  app_secret: "YOUR_APP_SECRET",
  service_domain: "open-us.vnnox.com"
)

response = client.request(
  http_method: :get,
  endpoint: "/v2/player/list",
  params: { start: 0, count: 20 }
)
```

### Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

Sprint 02 will add resource helpers (e.g., `client.players.list`) and response objects built on these foundations.
