#!/usr/bin/env node
/**
 * Minimal ActionCable mock server for k6 script validation.
 *
 * Speaks the ActionCable wire protocol:
 *   → welcome
 *   → confirm_subscription  (on "subscribe" command)
 *   → ping                  (every 3 s)
 *   → broadcast {count: N}  (on "heartbeat" action)
 *
 * Usage:
 *   node load_test/mock_cable_server.js
 */

const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 3000;
const wss  = new WebSocketServer({ port: PORT, path: "/cable" });

let totalConnections = 0;
let activeConnections = 0;
let heartbeatsReceived = 0;

wss.on("connection", (socket) => {
  totalConnections++;
  activeConnections++;

  // 1. Welcome frame
  socket.send(JSON.stringify({ type: "welcome" }));

  // 2. Ping every 3 s (ActionCable default is 3 s)
  const pingInterval = setInterval(() => {
    if (socket.readyState === socket.OPEN) {
      socket.send(JSON.stringify({ type: "ping", message: Date.now() }));
    }
  }, 3000);

  socket.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch (_) { return; }

    if (msg.command === "subscribe") {
      // 3. Confirm subscription
      socket.send(JSON.stringify({
        type: "confirm_subscription",
        identifier: msg.identifier,
      }));
      return;
    }

    if (msg.command === "message") {
      let data;
      try { data = JSON.parse(msg.data); } catch (_) { return; }

      if (data.action === "heartbeat") {
        heartbeatsReceived++;
        // 4. Simulate server broadcast (presence count update)
        socket.send(JSON.stringify({
          identifier: msg.identifier,
          message: { count: activeConnections },
        }));
      }
    }
  });

  socket.on("close", () => {
    activeConnections--;
    clearInterval(pingInterval);
  });

  socket.on("error", () => {
    activeConnections--;
    clearInterval(pingInterval);
  });
});

// Stats every 5 s
setInterval(() => {
  console.log(
    `[mock] active=${activeConnections}  total=${totalConnections}  heartbeats=${heartbeatsReceived}`
  );
}, 5000);

console.log(`ActionCable mock server listening on ws://localhost:${PORT}/cable`);
