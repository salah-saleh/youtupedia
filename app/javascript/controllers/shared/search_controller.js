import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]
  static values = {
    delay: { type: Number, default: 2000 } // 2 seconds delay
  }

  connect() {
    this.timeout = null
    this.handleSearchParam()
    // Listen for Turbo frame updates
    document.addEventListener("turbo:frame-render", this.handleFrameUpdate.bind(this))
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    document.removeEventListener("turbo:frame-render", this.handleFrameUpdate.bind(this))
  }

  handleFrameUpdate(event) {
    // Only handle updates for our specific frame
    const frameId = this.formTarget.dataset.turboFrame
    if (event.target.id === frameId) {
      this.handleSearchParam()
    }
  }

  handleSearchParam() {
    const url = new URL(window.location.href)
    const searchQuery = url.searchParams.get('q')
    if (searchQuery) {
      requestAnimationFrame(() => {
        this.inputTarget.focus()
        // Place cursor at the end
        this.inputTarget.setSelectionRange(searchQuery.length, searchQuery.length)
      })
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

  performSearch() {
    const form = this.formTarget
    const url = new URL(form.action)
    const formData = new FormData(form)
    
    // Add form data to URL parameters
    for (const [key, value] of formData.entries()) {
      url.searchParams.set(key, value)
    }

    // Update browser URL
    window.history.pushState({}, "", url)

    // Submit the request
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      if (!response.ok) throw new Error(response.statusText)
      return response.text()
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Search error:", error)
      // On error, reload the page to recover
      window.location.reload()
    })
  }
} 