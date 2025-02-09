import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]
  static values = {
    delay: { type: Number, default: 2000 } // 2 seconds delay
  }

  connect() {
    this.timeout = null
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

  // Clear timeout if user submits manually
  submit(event) {
    event.preventDefault()
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.performSearch()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  async performSearch() {
    const form = this.formTarget
    const url = new URL(form.action)
    const formData = new FormData(form)
    
    // Add form data to URL parameters
    for (const [key, value] of formData.entries()) {
      url.searchParams.append(key, value)
    }
    
    // Add turbo stream format
    url.searchParams.append("format", "turbo_stream")

    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Search error:", error)
    }
  }
} 