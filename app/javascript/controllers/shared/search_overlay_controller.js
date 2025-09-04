import { Controller } from "@hotwired/stimulus"

// Stimulus controller for YouTube URL search overlay
// Handles opening/closing the overlay modal with keyboard and click events
export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Listen for escape key globally
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
    
    // Listen for custom open and close events
    this.boundHandleOpenEvent = this.handleOpenEvent.bind(this)
    this.boundHandleCloseEvent = this.handleCloseEvent.bind(this)
    this.element.addEventListener("open-search-overlay", this.boundHandleOpenEvent)
    this.element.addEventListener("close-search-overlay", this.boundHandleCloseEvent)
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener("keydown", this.boundHandleKeydown)
    this.element.removeEventListener("open-search-overlay", this.boundHandleOpenEvent)
    this.element.removeEventListener("close-search-overlay", this.boundHandleCloseEvent)
  }

  // Handle custom open event
  handleOpenEvent() {
    this.open()
  }

  // Handle custom close event
  handleCloseEvent() {
    this.close()
  }

  // Open the overlay
  open() {
    this.element.classList.remove("hidden")
    // Focus the input after a short delay to ensure it's visible
    setTimeout(() => {
      const input = this.element.querySelector('input[type="text"]')
      if (input) {
        input.focus()
      }
    }, 100)
    
    // Prevent body scroll when overlay is open
    document.body.style.overflow = "hidden"
  }

  // Close the overlay
  close() {
    this.element.classList.add("hidden")
    // Restore body scroll
    document.body.style.overflow = ""
  }

  // Handle keyboard events
  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close()
    }
  }

  // Close when clicking on backdrop (not on modal content)
  closeOnBackdrop(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  // Prevent closing when clicking on modal content
  preventClose(event) {
    event.stopPropagation()
  }
}
