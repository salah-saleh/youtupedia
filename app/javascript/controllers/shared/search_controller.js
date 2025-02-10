import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]
  static values = {
    delay: { type: Number, default: 2000 } // 2 seconds delay
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search() {
    // Clear any existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Set a new timeout
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }

  submit(event) {
    event.preventDefault()
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.performSearch()
  }

  async performSearch() {
    const form = this.formTarget
    const url = new URL(form.action)
    const formData = new FormData(form)
    
    // Add form data to URL parameters
    for (const [key, value] of formData.entries()) {
      url.searchParams.set(key, value)
    }

    // Update URL without page reload
    window.history.pushState({}, "", url)

    try {
      // Submit the form through Turbo
      Turbo.navigator.submitForm(form)
      
      // Keep focus on input
      this.inputTarget.focus()
    } catch (error) {
      console.error('Search error:', error)
    }
  }
} 