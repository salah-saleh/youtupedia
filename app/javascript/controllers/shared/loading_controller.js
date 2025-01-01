import { Controller } from "@hotwired/stimulus"

// Handles loading states for forms and content areas
export default class extends Controller {
  static targets = ["form", "button", "content"]
  static values = {
    state: { type: String, default: "idle" }
  }

  connect() {
    this.handleFormSubmit = this.handleFormSubmit.bind(this)
    if (this.hasFormTarget) {
      this.formTarget.addEventListener("submit", this.handleFormSubmit)
    }
  }

  disconnect() {
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener("submit", this.handleFormSubmit)
    }
  }

  handleFormSubmit(event) {
    this.setState("loading")
  }

  // State management
  setState(state) {
    this.stateValue = state
    this.updateLoadingState()
  }

  updateLoadingState() {
    switch(this.stateValue) {
      case "loading":
        this.startLoading()
        break
      case "error":
        this.showError()
        break
      case "success":
        this.showSuccess()
        break
      default:
        this.stopLoading()
    }
  }

  // Loading states
  startLoading() {
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("loading", "true")
      this.buttonTarget.disabled = true
    }
    if (this.hasContentTarget) {
      this.contentTarget.setAttribute("loading", "true")
    }
  }

  stopLoading() {
    if (this.hasButtonTarget) {
      this.buttonTarget.removeAttribute("loading")
      this.buttonTarget.disabled = false
    }
    if (this.hasContentTarget) {
      this.contentTarget.removeAttribute("loading")
    }
  }

  // Error handling
  showError() {
    this.stopLoading()
    // Add error state handling
    const event = new CustomEvent("loading:error", {
      bubbles: true,
      detail: { controller: this }
    })
    this.element.dispatchEvent(event)
  }

  showSuccess() {
    this.stopLoading()
    // Add success state handling
    const event = new CustomEvent("loading:success", {
      bubbles: true,
      detail: { controller: this }
    })
    this.element.dispatchEvent(event)
  }
}