import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "seek"]
  static values = {
    videoId: String,
    roomSlug: String,
    startedAt: Number
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
    if (this.startedAtValue > 0) {
      const elapsed = Math.floor(Date.now() / 1000 - this.startedAtValue)
      if (elapsed > 0) e.target.seekTo(elapsed, true)
    }
    try { e.target.playVideo() } catch (_) {}
  }

  onStateChange(e) {
    // 0 = ENDED
    if (e.data === YT.PlayerState.ENDED) {
      this.playNext()
    }
  }

  // Called by Turbo when the hidden #player-seek div is replaced (seek broadcast)
  seekTargetConnected(el) {
    const startedAt = parseInt(el.dataset.startedAt, 10)
    if (!this.player || startedAt <= 0) return
    const elapsed = Math.floor(Date.now() / 1000 - startedAt)
    this.player.seekTo(Math.max(0, elapsed), true)
  }

  rewind() {
    this.seekBy(-15)
  }

  forward() {
    this.seekBy(15)
  }

  seekBy(delta) {
    if (!this.player) return
    const duration = this.player.getDuration() || Infinity
    const newTime = Math.max(0, Math.min(duration, this.player.getCurrentTime() + delta))
    // Seek locally immediately for instant feedback
    this.player.seekTo(newTime, true)
    // Broadcast the new position to all other users
    this.sendSeek(newTime)
  }

  sendSeek(currentTime) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(`/rooms/${encodeURIComponent(this.roomSlugValue)}/seek`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": token,
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: `current_time=${currentTime}`
    })
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
