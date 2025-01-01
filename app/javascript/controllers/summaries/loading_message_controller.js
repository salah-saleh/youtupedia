import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

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
    this.startCycling()
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  startCycling() {
    this.interval = setInterval(() => {
      this.currentIndex = (this.currentIndex + 1) % this.messages.length
      this.messageTarget.textContent = this.messages[this.currentIndex]
    }, 2500)
  }
}