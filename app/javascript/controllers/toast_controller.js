import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["notification"]

  connect() {
    this.notificationTargets.forEach(notification => {
      // Trigger animation after a small delay to ensure the element is rendered
      setTimeout(() => {
        notification.classList.remove("translate-x-full", "opacity-0")
      }, 100)

      // Auto-hide after 2.5 seconds
      setTimeout(() => {
        this.hide(notification)
      }, 5000)
    })

    // Listen for custom toast events from other controllers
    this.boundShowToast = this.showToast.bind(this)
    document.addEventListener('showToast', this.boundShowToast)
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener('showToast', this.boundShowToast)
  }

  // Handle custom toast events
  showToast(event) {
    const { message, type = 'success' } = event.detail
    
    // Create toast element
    const toast = document.createElement("div")
    toast.className = `bg-${type === 'success' ? 'green' : 'red'}-50 text-${type === 'success' ? 'green' : 'red'}-600 px-4 py-3 rounded-lg shadow-lg mb-3 flex items-center transform translate-x-full opacity-0 transition-all duration-300`
    toast.setAttribute('data-toast-target', 'notification')
    
    toast.innerHTML = `
      <div class="flex-1">${message}</div>
      <button class="ml-4 text-${type === 'success' ? 'green' : 'red'}-500 hover:text-${type === 'success' ? 'green' : 'red'}-700" data-action="toast#close">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    `
    
    // Add to the toast container
    this.element.appendChild(toast)
    
    // Trigger animation
    setTimeout(() => {
      toast.classList.remove("translate-x-full", "opacity-0")
    }, 100)

    // Auto-hide after 5 seconds
    setTimeout(() => {
      this.hide(toast)
    }, 5000)
  }

  close(event) {
    const notification = event.target.closest("[data-toast-target='notification']")
    this.hide(notification)
  }

  hide(notification) {
    // Only hide if the notification still exists
    if (notification && notification.parentElement) {
      notification.classList.add("translate-x-full", "opacity-0")

      // Remove from DOM after animation completes
      setTimeout(() => {
        notification.remove()
      }, 300)
    }
  }
}
