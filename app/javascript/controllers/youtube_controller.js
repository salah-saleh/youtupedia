import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player", "transcript", "debug", "debugTime", "debugState", "segment"]
  static values = {
    videoId: String
  }

  connect() {
    console.log("YouTube controller connected")
    this.currentSegment = null
    this.loadYouTubeAPI()
  }

  loadYouTubeAPI() {
    if (window.YT) {
      this.initializePlayer()
    } else {
      // Load the IFrame Player API code asynchronously
      const tag = document.createElement('script')
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName('script')[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

      // Set up global callback
      window.onYouTubeIframeAPIReady = () => this.initializePlayer()
    }
  }

  initializePlayer() {
    console.log("Initializing YouTube player")
    try {
      this.player = new YT.Player(this.playerTarget, {
        videoId: this.videoIdValue,
        events: {
          'onReady': () => this.onPlayerReady(),
          'onStateChange': (event) => this.onPlayerStateChange(event),
          'onError': (event) => this.onPlayerError(event)
        }
      })
    } catch (e) {
      console.error("Error initializing YouTube player:", e)
    }
  }

  onPlayerReady() {
    console.log("Player ready")
    this.startMonitoring()
  }

  startMonitoring() {
    setInterval(() => this.updateDebug(), 100)
    setInterval(() => this.checkTranscriptTime(), 100)
  }

  checkTranscriptTime() {
    if (this.player?.getCurrentTime) {
      const currentTime = this.player.getCurrentTime()
      this.highlightCurrentSegment(currentTime)
    }
  }

  highlightCurrentSegment(currentTime) {
    let activeSegment = null

    this.segmentTargets.forEach(segment => {
      const start = parseFloat(segment.dataset.start)
      const duration = parseFloat(segment.dataset.duration)
      const end = start + duration

      segment.classList.remove('bg-purple-50', 'border-l-4', 'border-purple-500')

      if (currentTime >= start && currentTime < end) {
        activeSegment = segment
        segment.classList.add('bg-purple-50', 'border-l-4', 'border-purple-500')
      }
    })

    this.handleActiveSegmentScroll(activeSegment)
  }

  handleActiveSegmentScroll(activeSegment) {
    if (activeSegment && activeSegment !== this.currentSegment) {
      this.currentSegment = activeSegment
      const container = this.transcriptTarget
      const containerRect = container.getBoundingClientRect()
      const activeRect = activeSegment.getBoundingClientRect()

      if (activeRect.top < containerRect.top || activeRect.bottom > containerRect.bottom) {
        activeSegment.scrollIntoView({
          behavior: 'smooth',
          block: 'center'
        })
      }
    }
  }

  seekToTime(event) {
    const seconds = parseFloat(event.currentTarget.dataset.start)
    console.log("Seeking to:", seconds)

    try {
      if (this.player?.seekTo) {
        this.player.seekTo(seconds, true)
        this.player.playVideo()
        this.highlightCurrentSegment(seconds)
      }
    } catch (e) {
      console.error("Seek error:", e)
    }
  }

  updateDebug() {
    if (!this.hasDebugTarget) return

    try {
      if (this.player?.getCurrentTime) {
        this.debugTimeTarget.textContent =
          `Current Time: ${this.player.getCurrentTime().toFixed(2)}`
        this.debugStateTarget.textContent =
          `Player State: ${this.player.getPlayerState()}`
      }
    } catch (e) {
      console.error("Debug update error:", e)
    }
  }

  onPlayerStateChange(event) {
    console.log("Player State Changed:", event.data)
  }

  onPlayerError(event) {
    console.error("Player Error:", event.data)
  }
}