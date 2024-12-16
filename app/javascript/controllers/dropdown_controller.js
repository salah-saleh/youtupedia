import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")

    // Add animation classes
    if (this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.remove("opacity-100", "scale-100")
      this.menuTarget.classList.add("opacity-0", "scale-95")
    } else {
      this.menuTarget.classList.remove("opacity-0", "scale-95")
      this.menuTarget.classList.add("opacity-100", "scale-100")
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden", "opacity-0", "scale-95")
      this.menuTarget.classList.remove("opacity-100", "scale-100")
    }
  }
}