import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "buttonText", "spinner", "input"]

  submit(event) {
    // Prevent double submission
    if (this.submitButtonTarget.disabled) {
      event.preventDefault()
      return
    }

    // Don't submit if input is empty
    if (!this.inputTarget.value.trim()) {
      event.preventDefault()
      return
    }

    // Show loading state
    this.submitButtonTarget.disabled = true
    this.spinnerTarget.classList.remove("hidden")
    this.buttonTextTarget.textContent = "Searching..."
  }
}