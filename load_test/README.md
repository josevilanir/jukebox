# Jukebox — K6 WebSocket Load Test

Tests the ActionCable endpoint (`/cable`) under concurrent WebSocket load,
focusing on `PresenceChannel` subscription and heartbeat behaviour.

---

## Prerequisites

### macOS

```bash
brew install k6
```

### Linux (Debian/Ubuntu)

```bash
sudo gpg -k
sudo gpg --no-default-keyring \
  --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
  https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

### Linux (rpm / Fedora)

```bash
sudo dnf install https://dl.k6.io/rpm/repo.rpm
sudo dnf install k6
```

### Docker (any platform)

```bash
docker pull grafana/k6
```

---

## Running locally

Start the Rails server first:

```bash
bin/dev        # or: bin/rails server
```

Then, in a separate terminal:

```bash
k6 run load_test/websocket_test.js
```

### Options

| Variable        | Default                    | Description                            |
|-----------------|----------------------------|----------------------------------------|
| `BASE_URL`      | `ws://localhost:3000`      | WebSocket base URL                     |
| `ROOM_SLUG`     | `test-room`                | Slug of the room to subscribe to       |
| `SESSION_COOKIE`| *(empty)*                  | Value of `_jukebox_session` cookie     |

Pass environment variables with `-e`:

```bash
k6 run \
  -e ROOM_SLUG=my-room \
  -e SESSION_COOKIE="<paste cookie value here>" \
  load_test/websocket_test.js
```

---

## Running against production (Fly.io)

> **Warning:** run load tests against a staging environment whenever possible.
> Hammering the production database with 100 concurrent WebSocket connections
> that each touch `solid_cache` / Postgres may affect real users.

```bash
k6 run \
  -e BASE_URL=wss://your-app.fly.dev \
  -e ROOM_SLUG=test-room \
  -e SESSION_COOKIE="<value from browser DevTools>" \
  load_test/websocket_test.js
```

To obtain the session cookie value:

1. Log in to the production app in your browser.
2. Open DevTools → Application → Cookies.
3. Copy the **value** of `_jukebox_session` (not the whole `name=value` string).

---

## Load profile

```
VUs
100 |         ████████████████
    |        /                \
  0 |_______/                  \______
    0s      15s               45s  60s
```

| Stage      | Duration | VUs    |
|------------|----------|--------|
| Ramp-up    | 15 s     | 0→100  |
| Steady     | 30 s     | 100    |
| Ramp-down  | 15 s     | 100→0  |

---

## Thresholds (test fails if violated)

| Metric                    | Threshold         |
|---------------------------|-------------------|
| Connection success rate   | ≥ 95 %            |
| Heartbeat success rate    | ≥ 90 %            |
| Heartbeat latency p95     | < 2 000 ms        |

---

## Results

<!-- Fill in after running the test -->

| VUs | Duration | Req/s | p95 latency | Error rate |
|-----|----------|-------|-------------|------------|
| 100 | 60 s     |       |             |            |
