import { Controller } from "@hotwired/stimulus"

// Stimulus controller to download transcript content as text files.
// - Provides two actions: downloadFull and downloadSegmented
// - fullValue: the full transcript text (from server)
// - videoIdValue: used to derive a helpful file name
export default class extends Controller {
  static values = {
    full: String,
    videoId: String
  }

  // Handles click on "Download Full"
  downloadFull() {
    const text = this.fullValue || this.buildFullFromSegments()
    const baseName = this.videoIdValue || "transcript"
    this.downloadText(text, `${baseName}-full.txt`)
  }

  // Handles click on "Download Segmented"
  downloadSegmented() {
    const text = this.buildSegmentedFromDom()
    const baseName = this.videoIdValue || "transcript"
    this.downloadText(text, `${baseName}-segmented.txt`)
  }

  // Builds a segmented transcript string from rendered DOM segments
  buildSegmentedFromDom() {
    const segments = this.element.querySelectorAll('[data-youtube-target="segment"]')
    if (!segments || segments.length === 0) return ""

    const lines = []
    segments.forEach(segment => {
      const start = parseFloat(segment.dataset.start)
      const textEl = segment.querySelector('.flex-1')
      const text = (textEl?.textContent || '').trim()
      const timestamp = this.formatSeconds(start)
      if (text) {
        lines.push(`${timestamp} ${text}`)
      }
    })
    return lines.join("\n")
  }

  // Fallback: builds a "full" transcript by concatenating segmented DOM
  // if fullValue wasn't provided
  buildFullFromSegments() {
    const segments = this.element.querySelectorAll('[data-youtube-target="segment"]')
    if (!segments || segments.length === 0) return ""

    const parts = []
    segments.forEach(segment => {
      const start = parseFloat(segment.dataset.start)
      const textEl = segment.querySelector('.flex-1')
      const text = (textEl?.textContent || '').trim()
      const timestamp = this.formatSeconds(start)
      if (text) {
        parts.push(`${text} (${timestamp})`)
      }
    })
    return parts.join(" ")
  }

  // Utility: formats seconds to hh:mm:ss or mm:ss
  formatSeconds(seconds) {
    if (isNaN(seconds)) return "0:00"
    const total = Math.max(0, Math.floor(seconds))
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor((total % 3600) / 60)
    const secs = total % 60
    const two = n => n.toString().padStart(2, '0')
    return hours > 0 ? `${hours}:${two(minutes)}:${two(secs)}` : `${minutes}:${two(secs)}`
  }

  // Triggers a browser download of the given text content
  downloadText(text, filename) {
    if (!text) return
    const blob = new Blob([text], { type: "text/plain;charset=utf-8" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }
}


