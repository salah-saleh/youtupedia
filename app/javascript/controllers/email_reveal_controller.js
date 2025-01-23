import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hidden", "visible", "copy"]
  static values = {
    copied: Boolean
  }

  connect() {
    // Construct email parts to avoid easy scraping
    const domain = "youtupedia.ai"
    const user = "support"
    this.email = `${user}@${domain}`
  }

  reveal(event) {
    event.preventDefault()
    this.hiddenTarget.classList.add("hidden")
    this.visibleTarget.classList.remove("hidden")
    this.copyTarget.classList.remove("hidden")
    this.visibleTarget.textContent = this.email
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.email)
      this.copiedValue = true
      
      // Reset after 2 seconds
      setTimeout(() => {
        this.copiedValue = false
      }, 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  copiedValueChanged() {
    const text = this.copyTarget.querySelector("[data-copy-text]")
    const icon = this.copyTarget.querySelector("[data-copy-icon]")
    
    if (this.copiedValue) {
      text.textContent = "Copied!"
      icon.innerHTML = this.checkIcon
    } else {
      text.textContent = "Copy"
      icon.innerHTML = this.clipboardIcon
    }
  }

  get clipboardIcon() {
    return `<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" />
    </svg>`
  }

  get checkIcon() {
    return `<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
    </svg>`
  }
} 