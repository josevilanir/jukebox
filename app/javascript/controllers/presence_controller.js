import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { slug: String }
  static targets = ["count"]

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PresenceChannel", room_slug: this.slugValue },
      {
        received: (data) => {
          if (data.count !== undefined) {
            this.countTarget.textContent = this.label(data.count)
          }
        }
      }
    )

    this.heartbeatTimer = setInterval(() => {
      this.subscription.perform("heartbeat", { room_slug: this.slugValue })
    }, 30000)
  }

  disconnect() {
    clearInterval(this.heartbeatTimer)
    this.subscription?.unsubscribe()
  }

  label(n) {
    return n === 1 ? "1 pessoa ouvindo" : `${n} pessoas ouvindo`
  }
}
