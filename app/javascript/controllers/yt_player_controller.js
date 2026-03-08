import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "seek"]
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
    // Dynamically create a placeholder so Stimulus doesn't lose the container target
    this.containerTarget.innerHTML = '<div id="yt-player-placeholder" class="w-full h-full"></div>';
    const placeholder = this.containerTarget.querySelector("#yt-player-placeholder");

    this.player = new YT.Player(placeholder, {
      videoId: this.videoIdValue,
      width: '100%',
      height: '100%',
      playerVars: {
        rel: 0,
        playsinline: 1,
        controls: 1,
        autoplay: 1,
        origin: window.location.origin // Previne alguns erros 150 em embeds localhost/produção
      },
      events: {
        onReady: (e) => this.onReady(e),
        onStateChange: (e) => this.onStateChange(e),
        onError: (e) => this.onError(e)
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

  onError(e) {
    console.error("Jukebox: YouTube Player Error! Code:", e.data);
    
    // Substitui a tela preta por um aviso amigável
    this.containerTarget.innerHTML = `
      <div class="w-full h-full flex flex-col items-center justify-center bg-zinc-900 text-white p-6 text-center">
        <svg class="w-12 h-12 text-red-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
        <h3 class="text-xl font-bold mb-2">Vídeo Indisponível (Erro ${e.data})</h3>
        <p class="text-zinc-400">O dono do vídeo bloqueou a reprodução fora do YouTube ou o vídeo foi apagado.</p>
        <p class="text-zinc-500 mt-4 text-sm font-semibold animate-pulse">Pulando para a próxima faixa em 3 segundos...</p>
      </div>
    `;

    // 100 = Video removed/private, 101/150 = Embedding disabled by owner
    // Pula para o próximo vídeo após 3 segundos para dar tempo das pessoas lerem
    setTimeout(() => {
      this.playNext();
    }, 3000);
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
        "X-CSRF-Token": token
      }
    })
  }
}
