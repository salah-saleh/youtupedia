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
      }, 2500)
    })
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