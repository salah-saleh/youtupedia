import { Controller } from "@hotwired/stimulus"

// Stimulus controller for search input animation
// Handles focus/blur events to show/hide the moving border animation
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.updateContainerState()
  }

  // Called when input gains focus
  inputFocused() {
    this.element.classList.add("focused")
    this.updateContainerState()
  }

  // Called when input loses focus
  inputBlurred() {
    this.element.classList.remove("focused")
    this.updateContainerState()
  }

  // Called when input content changes
  inputChanged() {
    this.updateContainerState()
  }

  // Updates container classes based on input state
  updateContainerState() {
    const input = this.inputTarget
    const hasContent = input.value.trim().length > 0
    
    if (hasContent) {
      this.element.classList.add("has-content")
    } else {
      this.element.classList.remove("has-content")
    }
  }
}
