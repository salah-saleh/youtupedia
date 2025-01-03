import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon", "globalIcon", "itemToggle"]

  connect() {
    // Initialize the state
    this.expanded = true
    this.globalExpanded = true
  }

  toggle(event) {
    const button = event.currentTarget
    const isExpanded = button.getAttribute("aria-expanded") === "true"
    this.toggleContent(!isExpanded, button)
  }

  toggleAll() {
    this.globalExpanded = !this.globalExpanded

    // Update all item toggles
    this.itemToggleTargets.forEach(button => {
      this.toggleContent(this.globalExpanded, button)
    })

    // Update global icon
    if (this.hasGlobalIconTarget) {
      this.globalIconTarget.style.transform = this.globalExpanded ? "rotate(0deg)" : "rotate(-90deg)"
    }
  }

  toggleContent(expand, button) {
    const content = button.closest("div").nextElementSibling
    const icon = button.querySelector("[data-collapsible-target='icon']")

    if (expand) {
      content.style.maxHeight = content.scrollHeight + "px"
      content.classList.remove("opacity-0")
      if (icon) icon.style.transform = "rotate(0deg)"
    } else {
      content.style.maxHeight = "0"
      content.classList.add("opacity-0")
      if (icon) icon.style.transform = "rotate(-90deg)"
    }

    button.setAttribute("aria-expanded", expand)
  }
}