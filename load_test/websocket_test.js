import ws from "k6/ws";
import { check, sleep } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------
const connectionSuccessRate = new Rate("ws_connection_success");
const heartbeatSuccessRate  = new Rate("ws_heartbeat_success");
const heartbeatLatency      = new Trend("ws_heartbeat_latency_ms", true);
const messagesReceived      = new Counter("ws_messages_received");

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const BASE_URL  = __ENV.BASE_URL  || "ws://localhost:3000";
const ROOM_SLUG = __ENV.ROOM_SLUG || "test-room";
// Optional session cookie for authenticated connections (not required for
// read-only presence, but ActionCable rejects unauthenticated connections
// if ApplicationCable::Connection enforces it).
// Supply via:  k6 run -e SESSION_COOKIE="<value>" websocket_test.js
const SESSION_COOKIE = __ENV.SESSION_COOKIE || "";

const WS_URL = `${BASE_URL}/cable`;

// ---------------------------------------------------------------------------
// Load profile
//   0 →  15 s : ramp up   0 → 100 VUs
//  15 →  45 s : hold         100 VUs
//  45 →  60 s : ramp down 100 →   0 VUs
// ---------------------------------------------------------------------------
export const options = {
  stages: [
    { duration: "15s", target: 100 },
    { duration: "30s", target: 100 },
    { duration: "15s", target: 0   },
  ],
  thresholds: {
    ws_connection_success:   ["rate>0.95"],          // ≥95 % connections ok
    ws_heartbeat_success:    ["rate>0.90"],          // ≥90 % heartbeats acked
    ws_heartbeat_latency_ms: ["p(95)<2000"],         // p95 under 2 s
  },
};

// ---------------------------------------------------------------------------
// ActionCable wire protocol helpers
// ---------------------------------------------------------------------------
const IDENTIFIER = JSON.stringify({
  channel: "PresenceChannel",
  room_slug: ROOM_SLUG,
});

function acSubscribe() {
  return JSON.stringify({ command: "subscribe", identifier: IDENTIFIER });
}

function acHeartbeat() {
  return JSON.stringify({
    command: "message",
    identifier: IDENTIFIER,
    data: JSON.stringify({ action: "heartbeat" }),
  });
}

// ---------------------------------------------------------------------------
// VU entry-point
// ---------------------------------------------------------------------------
export default function () {
  const headers = {};
  if (SESSION_COOKIE) {
    headers["Cookie"] = `_jukebox_session=${SESSION_COOKIE}`;
  }

  let subscribed        = false;
  let heartbeatSentAt   = 0;
  let heartbeatPending  = false;

  const res = ws.connect(WS_URL, { headers }, function (socket) {
    // ------------------------------------------------------------------
    // Connection opened — send subscribe command
    // ------------------------------------------------------------------
    socket.on("open", () => {
      connectionSuccessRate.add(1);
      socket.send(acSubscribe());
    });

    // ------------------------------------------------------------------
    // Incoming messages
    // ------------------------------------------------------------------
    socket.on("message", (raw) => {
      messagesReceived.add(1);

      let msg;
      try {
        msg = JSON.parse(raw);
      } catch (_) {
        return;
      }

      // ActionCable ping — ignore
      if (msg.type === "ping") return;

      // Welcome frame
      if (msg.type === "welcome") return;

      // Subscription confirmed
      if (msg.type === "confirm_subscription") {
        subscribed = true;
        return;
      }

      // Broadcast from server (presence count update) in response to heartbeat
      if (msg.message && heartbeatPending) {
        const latency = Date.now() - heartbeatSentAt;
        heartbeatLatency.add(latency);
        heartbeatSuccessRate.add(1);
        heartbeatPending = false;
      }
    });

    // ------------------------------------------------------------------
    // Errors
    // ------------------------------------------------------------------
    socket.on("error", () => {
      connectionSuccessRate.add(0);
    });

    // ------------------------------------------------------------------
    // Heartbeat loop — every 30 s while subscribed
    // ------------------------------------------------------------------
    socket.setInterval(() => {
      if (!subscribed) return;

      heartbeatSentAt  = Date.now();
      heartbeatPending = true;
      socket.send(acHeartbeat());

      // If no response arrives within 5 s, count as failure
      socket.setTimeout(() => {
        if (heartbeatPending) {
          heartbeatSuccessRate.add(0);
          heartbeatPending = false;
        }
      }, 5000);
    }, 30000);

  });

  check(res, { "WS connection status 101": (r) => r && r.status === 101 });
}
