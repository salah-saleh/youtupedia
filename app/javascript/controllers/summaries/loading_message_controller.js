import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "timer"]

  connect() {
    this.messages = [
      "Teaching AI to speed read... might take a few seconds 🤓",
      "AI is doing its best impression of a speed-reading champion 🏃‍♂️",
      "Brewing coffee for the AI to stay focused... ☕",
      "AI is channeling its inner TL;DR master 🎯",
      "Converting caffeine into summaries... ⚡",
      "AI is skimming faster than your college self before finals 📚",
      "Summoning the spirit of CliffsNotes... 📝",
      "AI is doing mental gymnastics to summarize this video 🤸‍♂️",
      "Teaching robots the art of brevity... 🤖",
      "AI is practicing its elevator pitch skills... 🛗"
    ]
    this.currentIndex = 0
    this.startTime = Date.now()
    this.startCycling()
  }

  disconnect() {
    this.cleanup()
  }

  cleanup() {
    if (this.interval) {
      clearInterval(this.interval)
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  startCycling() {
    // Start the message cycling
    this.updateMessage()
    this.interval = setInterval(() => {
      this.currentIndex = (this.currentIndex + 1) % this.messages.length
      this.updateMessage()
    }, 2500)

    // Start the timer update
    this.updateTimer(0)
    this.timerInterval = setInterval(() => {
      const elapsedSeconds = Math.floor((Date.now() - this.startTime) / 1000)
      
      // If we've hit 60 seconds, show error message and stop cycling
      if (elapsedSeconds >= 60) {
        this.cleanup()
        this.messageTarget.innerHTML = `
          <div class="text-red-600 dark:text-red-400">
            Something went wrong. Please refresh the page and try again.
          </div>
        `
        this.timerTarget.remove()
        return
      }

      this.updateTimer(elapsedSeconds)
    }, 1000)
  }

  updateTimer(elapsedSeconds) {
    this.timerTarget.textContent = `This might take up to a minute (${elapsedSeconds}s)`
  }

  updateMessage() {
    this.messageTarget.textContent = this.messages[this.currentIndex]
  }
}