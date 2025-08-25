
import { Controller } from "@hotwired/stimulus"

// Remove Item Controller
// Handles smooth animations when removing summaries and channels
// Uses Turbo Streams for actual DOM removal, JavaScript only for animations
export default class extends Controller {
  // Static values that can be set via data attributes
  static values = {
    type: String,     // The type of item (summary or channel)
    id: String        // The ID of the item to remove
  }

  // Called when the controller connects
  connect() {
    // Controller connected successfully
  }

  // Handles the remove button click with smooth animations
  // Turbo Streams will handle the actual DOM removal
  async remove(event) {
    event.preventDefault()
    event.stopPropagation()

    // Get the button element and show loading state
    const button = event.currentTarget
    const originalContent = button.innerHTML
    button.innerHTML = `
      <svg class="w-3 h-3 animate-spin" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
    `
    button.disabled = true

    // Add fade-out animation immediately
    const cardId = `${this.typeValue}-card-${this.idValue}`
    const card = document.getElementById(cardId)
    
    if (card) {
      // Add fade-out animation
      card.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      card.style.opacity = "0"
      card.style.transform = "scale(0.95)"
    }

    try {
      // Use fetch with proper Turbo Stream headers
      const url = `/${this.typeValue === 'summary' ? 'summaries' : 'channels'}/${this.idValue}/remove_from_user`
      
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        // Get the Turbo Stream response and execute it
        const turboStreamHtml = await response.text()
        Turbo.renderStreamMessage(turboStreamHtml)
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
      
    } catch (error) {
      // Handle network or other errors
      this.showError("Network error. Please try again.")
      
      // Restore button and card state
      button.innerHTML = originalContent
      button.disabled = false
      
      if (card) {
        card.style.opacity = "1"
        card.style.transform = "scale(1)"
      }
    }
  }

  // Check if the grid is empty and show appropriate empty state
  checkEmptyState() {
    const grid = this.element.closest(".grid") || this.element.closest("[class*='grid']")
    if (grid && grid.children.length === 0) {
      // Find the parent container and show empty state
      const container = grid.closest(".space-y-6") || grid.parentElement
      if (container) {
        const emptyState = this.createEmptyState()
        container.appendChild(emptyState)
      }
    }
  }

  // Create an empty state message
  createEmptyState() {
    const emptyDiv = document.createElement("div")
    emptyDiv.className = "text-center py-12"
    emptyDiv.innerHTML = `
      <div class="text-gray-500 dark:text-gray-400">
        <svg class="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
        </svg>
        <p class="text-lg font-medium">No ${this.typeValue === "summary" ? "videos" : "channels"} found.</p>
        <p class="text-sm">Start exploring to add some ${this.typeValue === "summary" ? "videos" : "channels"} to your list.</p>
      </div>
    `
    return emptyDiv
  }

  // Show error message to the user
  showError(message) {
    // Simple error display using alert
    alert(message)
  }
}