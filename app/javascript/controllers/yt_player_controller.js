import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame"]
  static values = {
    videoId: String,
    roomSlug: String
  }

  connect() {
    if (!this.hasVideoIdValue || !this.videoIdValue) return
    this.loadApi().then(() => this.buildPlayer())
  }

  disconnect() {
    if (this.player && this.player.destroy) {
      try { this.player.destroy() } catch (_) {}
      this.player = null
    }
  }

  // --- helpers ---

  loadApi() {
    if (window.YT && window.YT.Player) return Promise.resolve()

    if (window.__ytApiLoading) return window.__ytApiLoading

    window.__ytApiLoading = new Promise((resolve) => {
      const tag = document.createElement("script")
      tag.src = "https://www.youtube.com/iframe_api"
      document.head.appendChild(tag)
      window.onYouTubeIframeAPIReady = () => resolve()
    })
    return window.__ytApiLoading
  }

  buildPlayer() {
    this.player = new YT.Player(this.frameTarget, {
      videoId: this.videoIdValue,
      playerVars: {
        rel: 0,
        playsinline: 1,
        controls: 1,
        autoplay: 1
      },
      events: {
        onReady: (e) => this.onReady(e),
        onStateChange: (e) => this.onStateChange(e)
      }
    })
  }

  onReady(e) {
    try { e.target.playVideo() } catch (_) {}
  }

  onStateChange(e) {
    // 0 = ENDED
    if (e.data === YT.PlayerState.ENDED) {
      this.playNext()
    }
  }

  playNext() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(`/rooms/${encodeURIComponent(this.roomSlugValue)}/play_next`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
  }
}
