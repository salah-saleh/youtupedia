
import { Controller } from "@hotwired/stimulus"

// Remove Item Controller
// Handles smooth animations when removing summaries and channels
// Shows deleted state permanently until page refresh/navigation
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
  // Shows deleted state permanently until page refresh/navigation
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

    // Get the card element
    const cardId = `${this.typeValue}-card-${this.idValue}`
    const card = document.getElementById(cardId)
    
    if (!card) {
      this.showError("Item not found.")
      return
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
        // Show deleted state permanently - item stays in UI until page refresh
        this.showDeletedState(card, button)
        
        // No need to remove from DOM - item stays in deleted state
        // User will see the deleted state until they refresh or navigate away
        
      } else {
        throw new Error(`HTTP ${response.status}`)
      }
      
    } catch (error) {
      // Handle network or other errors
      this.showError("Network error. Please try again.")
      
      // Restore button and card state
      button.innerHTML = originalContent
      button.disabled = false
    }
  }

  // Shows the deleted state with blur and overlay
  // Item remains in this state until page refresh/navigation
  showDeletedState(card, button) {
    // Find the card content (the link element) to apply blur to
    // The remove button is outside this element, so it won't be blurred
    const cardContent = card.querySelector('a') || card.querySelector('[href]')
    
    if (cardContent) {
      // Apply blur and opacity only to the main content area (link)
      cardContent.style.transition = "all 0.3s ease-out"
      cardContent.style.filter = "blur(2px)"
      cardContent.style.opacity = "0.6"
    }
    
    // Add deleted overlay with reduced opacity (0.1) - simplified as per user preference
    const overlay = document.createElement("div")
    overlay.className = "absolute inset-0 bg-red-500/10 rounded-lg z-20"
    
    // Position overlay absolutely within the card
    card.style.position = "relative"
    card.appendChild(overlay)
    
    // Hide the remove button completely after deletion
    button.style.display = "none"
    
    // Show toast notice using the existing toast system
    this.showToastNotice(`${this.typeValue === 'summary' ? 'Video' : 'Channel'} deleted`)
    
    // Store the deleted state in the card for reference
    card.setAttribute('data-deleted', 'true')
  }

  // Shows a toast notice using the existing toast system
  showToastNotice(message) {
    // Create a custom event to trigger the toast
    const toastEvent = new CustomEvent('showToast', {
      detail: {
        message: message,
        type: 'success' // Use success styling (green)
      }
    })
    
    // Dispatch the event so the toast controller can handle it
    document.dispatchEvent(toastEvent)
  }

  // Check if the grid is empty and show appropriate empty state
  // Note: This won't be called since items stay in deleted state
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