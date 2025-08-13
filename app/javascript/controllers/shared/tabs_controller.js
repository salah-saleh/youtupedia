import { Controller } from "@hotwired/stimulus"

// Generic tab controller
// Usage:
// <div data-controller="tabs" data-tabs-active-value="summary">
//   <button data-tabs-target="tab" data-name="summary" data-action="click->tabs#show">Summary</button>
//   <button data-tabs-target="tab" data-name="timeline" data-action="click->tabs#show">Timeline</button>
//   <button data-tabs-target="tab" data-name="transcript" data-action="click->tabs#show">Transcript</button>
//   <div data-tabs-target="panel" data-name="summary">...</div>
//   <div data-tabs-target="panel" data-name="timeline">...</div>
//   <div data-tabs-target="panel" data-name="transcript">...</div>
// </div>
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String }

  connect() {
    // Default to first tab if none provided
    if (!this.hasActiveValue || !this.activeValue) {
      const first = this.tabTargets[0]?.dataset.name
      if (first) this.activeValue = first
    }
    this.render()
  }

  show(event) {
    const name = event.currentTarget.dataset.name
    if (!name) return
    this.activeValue = name
    this.render()
  }

  render() {
    // Toggle panels
    this.panelTargets.forEach((panel) => {
      const isActive = panel.dataset.name === this.activeValue
      panel.classList.toggle("hidden", !isActive)
      panel.setAttribute("aria-hidden", (!isActive).toString())
    })

    // Toggle tab button styles
    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.name === this.activeValue
      tab.setAttribute("aria-selected", isActive.toString())
      tab.classList.toggle("bg-gray-200", isActive)
      tab.classList.toggle("dark:bg-gray-700", isActive)
      tab.classList.toggle("text-gray-900", isActive)
      tab.classList.toggle("dark:text-white", isActive)
      tab.classList.toggle("bg-transparent", !isActive)
      tab.classList.toggle("text-gray-600", !isActive)
      tab.classList.toggle("dark:text-gray-300", !isActive)
    })
  }
}


