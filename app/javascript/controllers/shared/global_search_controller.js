import { Controller } from "@hotwired/stimulus"

// Global search controller that can open the search overlay from anywhere in the app
// This controller is attached to the body element and handles global search functionality
export default class extends Controller {
  connect() {
    // Listen for Cmd+K (or Ctrl+K on Windows/Linux) keyboard shortcut
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  // Handle keyboard shortcuts
  handleKeydown(event) {
    // Check for Cmd+K (Mac) or Ctrl+K (Windows/Linux)
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault() // Prevent browser's default search behavior
      this.toggleOverlay()
    }
  }

  // Open the search overlay by dispatching a custom event
  openOverlay() {
    const overlay = document.getElementById("search-overlay")
    if (overlay) {
      overlay.dispatchEvent(new CustomEvent("open-search-overlay"))
    }
  }

  // Toggle the search overlay (open if closed, close if open)
  toggleOverlay() {
    const overlay = document.getElementById("search-overlay")
    if (overlay) {
      if (overlay.classList.contains("hidden")) {
        // Overlay is closed, open it
        overlay.dispatchEvent(new CustomEvent("open-search-overlay"))
      } else {
        // Overlay is open, close it
        overlay.dispatchEvent(new CustomEvent("close-search-overlay"))
      }
    }
  }
}
