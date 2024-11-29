import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player", "transcript", "debug", "debugTime", "debugState", "segment", "loadingIndicator"]
  static values = {
    videoId: String
  }

  connect() {
    console.log("YouTube controller connected")
    this.currentSegment = null
    this.loadYouTubeAPI()
  }

  loadYouTubeAPI() {
    console.log("Loading YouTube API...")
    if (window.YT) {
      this.initializePlayer()
    } else {
      const tag = document.createElement('script')
      tag.src = "https://www.youtube.com/iframe_api"
      const firstScriptTag = document.getElementsByTagName('script')[0]
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
      window.onYouTubeIframeAPIReady = () => this.initializePlayer()
    }
  }

  initializePlayer() {
    console.log("Initializing player...")
    try {
      this.player = new YT.Player(this.playerTarget, {
        videoId: this.videoIdValue,
        events: {
          'onReady': (event) => this.onPlayerReady(event),
          'onStateChange': (event) => this.onPlayerStateChange(event),
          'onError': (event) => this.onPlayerError(event)
        }
      })
    } catch (e) {
      console.error("Error initializing player:", e)
    }
  }

  onPlayerReady(event) {
    console.log("Player ready!")
    if (this.hasLoadingIndicatorTarget) {
      console.log("Found loading indicator, hiding it...")
      this.loadingIndicatorTarget.style.display = 'none'
    } else {
      console.log("Loading indicator target not found!")
    }
    this.startMonitoring()
  }

  startMonitoring() {
    setInterval(() => {
      if (this.player && this.player.getCurrentTime) {
        this.updateDebug()
        this.checkTranscriptTime()
      }
    }, 100)
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

      const relativeTop = activeRect.top - containerRect.top
      const relativeBottom = activeRect.bottom - containerRect.top

      if (relativeTop < 0 || relativeBottom > containerRect.height) {
        container.scrollTop = container.scrollTop + relativeTop - (containerRect.height / 2) + (activeRect.height / 2)
      }
    }
  }

  seekToTime(event) {
    const time = parseFloat(event.currentTarget.dataset.time);
    if (this.player?.seekTo) {
      this.player.seekTo(time, true);
      this.player.playVideo();
    }
  }

  onPlayerStateChange(event) {
    console.log("Player State Changed:", event.data)
  }

  onPlayerError(event) {
    console.error("Player Error:", event.data)
  }
}