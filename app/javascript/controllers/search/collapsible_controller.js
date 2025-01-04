import { Controller } from "@hotwired/stimulus"

/**
 * Collapsible Controller
 *
 * This controller manages expandable/collapsible content sections with a "Show more/less" toggle.
 * It includes a gradient overlay effect and smooth height transitions.
 * Enhanced for better mobile compatibility.
 */
export default class extends Controller {
  static targets = [
    "content",    // The main content container that will be expanded/collapsed
    "footer",     // The footer containing the show more/less button
    "buttonText", // The text inside the toggle button
    "icon",       // The chevron icon that rotates
    "gradient",   // The gradient overlay that fades out the content
    "itemToggle", // Individual item toggle buttons
    "globalIcon"  // Global expand/collapse icon
  ]

  static values = {
    maxHeight: Number,  // Maximum height (in px) when collapsed
    increment: { type: Number, default: 60 },  // Height increment for each click
    expanded: { type: Boolean, default: false }  // Track expanded state
  }

  connect() {
    // Set initial state
    this.currentHeight = this.maxHeightValue
    this.checkOverflow()

    // Initialize all items as expanded
    this.itemToggleTargets.forEach(toggle => {
      const content = toggle.nextElementSibling
      if (content) {
        content.style.maxHeight = content.scrollHeight + "px"
      }
    })
  }

  /**
   * Toggle individual item expansion
   * @param {Event} event - Click event
   */
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const content = button.closest("[data-timeline-item]").querySelector("[data-collapsible-target='content']")
    const icon = button.querySelector("[data-collapsible-target='icon']")

    if (!content || !icon) return

    const isExpanded = content.style.maxHeight !== "0px"

    // Toggle content visibility with animation
    if (isExpanded) {
      content.style.maxHeight = "0px"
      content.style.marginBottom = "0px"
      icon.classList.remove("rotate-180")
      button.setAttribute("aria-expanded", "false")
    } else {
      content.style.maxHeight = content.scrollHeight + "px"
      content.style.marginBottom = "0.5rem"
      icon.classList.add("rotate-180")
      button.setAttribute("aria-expanded", "true")
    }
  }

  /**
   * Toggle all items' expansion state
   * @param {Event} event - Click event
   */
  toggleAll(event) {
    event.preventDefault()
    event.stopPropagation()

    const allExpanded = this.itemToggleTargets.every(toggle =>
      toggle.getAttribute("aria-expanded") === "true"
    )

    this.itemToggleTargets.forEach(toggle => {
      const content = toggle.closest("[data-timeline-item]").querySelector("[data-collapsible-target='content']")
      const icon = toggle.querySelector("[data-collapsible-target='icon']")

      if (!content || !icon) return

      if (allExpanded) {
        content.style.maxHeight = "0px"
        content.style.marginBottom = "0px"
        icon.classList.remove("rotate-180")
        toggle.setAttribute("aria-expanded", "false")
      } else {
        content.style.maxHeight = content.scrollHeight + "px"
        content.style.marginBottom = "0.5rem"
        icon.classList.add("rotate-180")
        toggle.setAttribute("aria-expanded", "true")
      }
    })

    // Toggle global icon
    if (this.hasGlobalIconTarget) {
      this.globalIconTarget.classList.toggle("rotate-180", !allExpanded)
    }
  }

  /**
   * Check if content exceeds maxHeight and show/hide controls accordingly
   */
  checkOverflow() {
    const content = this.contentTarget
    const isOverflowing = content.scrollHeight > this.maxHeightValue

    if (isOverflowing && this.hasFooterTarget && this.hasGradientTarget) {
      content.style.maxHeight = `${this.currentHeight}px`
      this.footerTarget.classList.remove("hidden")
      this.gradientTarget.classList.remove("hidden")
    }
  }
}