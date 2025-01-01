import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player", "transcript", "debug", "debugTime", "debugState", "segment", "loadingIndicator"]
  static values = {
    videoId: String
  }

  connect() {
    console.log("YouTube controller connected")
    this.currentSegment = null
    this.nextSegment = null
    this.lastCheckedTime = null
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
      this.loadingIndicatorTarget.style.display = 'none'
    }
    // Initialize segment data for faster lookups
    this.initializeSegmentData()
    this.startMonitoring()
  }

  initializeSegmentData() {
    // Create a sorted array of segment boundaries for binary search
    this.segments = this.segmentTargets.map(segment => ({
      element: segment,
      start: parseFloat(segment.dataset.start),
      duration: parseFloat(segment.dataset.duration),
      end: parseFloat(segment.dataset.start) + parseFloat(segment.dataset.duration)
    })).sort((a, b) => a.start - b.start)
  }

  startMonitoring() {
    this.monitoringInterval = setInterval(() => {
      if (this.player?.getCurrentTime && this.player.getPlayerState() === YT.PlayerState.PLAYING) {
        this.updateDebug()
        this.checkTranscriptTime()
      }
    }, 100)
  }

  updateDebug() {
    if (!this.hasDebugTarget) return

    try {
      if (this.player?.getCurrentTime) {
        this.debugTimeTarget.textContent = `Current Time: ${this.player.getCurrentTime().toFixed(2)}`
        this.debugStateTarget.textContent = `Player State: ${this.player.getPlayerState()}`
      }
    } catch (e) {
      console.error("Debug update error:", e)
    }
  }

  checkTranscriptTime() {
    if (!this.player?.getCurrentTime) return

    const currentTime = this.player.getCurrentTime()
    // Only update if time has changed significantly (more than 50ms)
    if (this.lastCheckedTime !== null && Math.abs(currentTime - this.lastCheckedTime) < 0.05) {
      return
    }
    this.lastCheckedTime = currentTime
    this.highlightCurrentSegment(currentTime)
  }

  highlightCurrentSegment(currentTime) {
    // Find the active segments
    const { currentSegment, nextSegment } = this.findActiveSegments(currentTime)

    // Remove highlights from old segments
    if (this.currentSegment && (!currentSegment || this.currentSegment.element !== currentSegment.element)) {
      this.currentSegment.element.classList.remove(
        'bg-purple-50',
        'dark:bg-purple-900/50',
        'border-l-4',
        'border-purple-500'
      )
    }
    if (this.nextSegment && (!nextSegment || this.nextSegment.element !== nextSegment.element)) {
      this.nextSegment.element.classList.remove(
        'bg-purple-50',
        'dark:bg-purple-900/50',
        'border-l-4',
        'border-purple-500'
      )
    }

    // Highlight current segment with primary highlight
    if (currentSegment && currentSegment !== this.currentSegment) {
      currentSegment.element.classList.add(
        'bg-purple-50',
        'dark:bg-purple-900/50',
        'border-l-4',
        'border-purple-500'
      )
      this.handleActiveSegmentScroll(currentSegment.element)
      this.currentSegment = currentSegment
    }

    // Highlight next segment with secondary highlight
    if (nextSegment && nextSegment !== this.nextSegment) {
      nextSegment.element.classList.add(
        'bg-purple-50',
        'dark:bg-purple-900/50',
        'border-l-4',
        'border-purple-500'
      )
      this.nextSegment = nextSegment
    }
  }

  findActiveSegments(currentTime) {
    const buffer = 0.1

    // Find current segment
    const currentIndex = this.segments.findIndex(segment =>
      currentTime >= (segment.start - buffer) && currentTime < (segment.end + buffer)
    )

    if (currentIndex === -1) {
      return { currentSegment: null, nextSegment: null }
    }

    // Get next segment if available
    const nextSegment = currentIndex < this.segments.length - 1 ?
      this.segments[currentIndex + 1] : null

    return {
      currentSegment: this.segments[currentIndex],
      nextSegment
    }
  }

  handleActiveSegmentScroll(activeSegment) {
    if (!activeSegment) return

    const container = this.transcriptTarget
    const containerRect = container.getBoundingClientRect()
    const activeRect = activeSegment.getBoundingClientRect()

    const relativeTop = activeRect.top - containerRect.top
    const relativeBottom = activeRect.bottom - containerRect.top

    if (relativeTop < 0 || relativeBottom > containerRect.height) {
      const scrollTarget = container.scrollTop + relativeTop - (containerRect.height / 3)
      container.scrollTo({
        top: scrollTarget,
        behavior: 'smooth'
      })
    }
  }

  seekToTime(event) {
    const time = parseFloat(event.currentTarget.dataset.time)
    if (this.player?.seekTo) {
      this.player.seekTo(time, true)
      this.player.playVideo()
    }
  }

  onPlayerStateChange(event) {
    if (event.data === YT.PlayerState.PLAYING) {
      this.checkTranscriptTime()
    }
  }

  onPlayerError(event) {
    console.error("Player Error:", event.data)
  }

  disconnect() {
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval)
    }
  }
}