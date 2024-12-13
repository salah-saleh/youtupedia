import { Controller } from "@hotwired/stimulus"

/**
 * Collapsible Controller
 *
 * This controller manages expandable/collapsible content sections with a "Show more/less" toggle.
 * It includes a gradient overlay effect and smooth height transitions.
 */
export default class extends Controller {
  // Define targets that we'll interact with
  static targets = [
    "content",    // The main content container that will be expanded/collapsed
    "footer",     // The footer containing the show more/less button
    "buttonText", // The text inside the toggle button
    "icon",       // The chevron icon that rotates
    "gradient"    // The gradient overlay that fades out the content
  ]

  // Define values that can be configured via data attributes
  static values = {
    maxHeight: Number, // Maximum height (in px) when collapsed
    increment: { type: Number, default: 60 }  // Default increment of 60px
  }

  /**
   * On connect, check if the content needs the expand/collapse functionality
   * This runs when the controller is initialized
   */
  connect() {
    // Set initial state
    this.checkOverflow()
  }

  /**
   * Check if content exceeds maxHeight and show/hide controls accordingly
   * This determines whether we need the expand/collapse functionality
   */
  checkOverflow() {
    const contentHeight = this.contentTarget.scrollHeight
    const maxHeight = this.maxHeightValue

    if (contentHeight > maxHeight) {
      // Content is taller than maxHeight, show collapse UI
      this.contentTarget.style.maxHeight = `${maxHeight}px`
      this.footerTarget.classList.remove("hidden")
      this.gradientTarget.classList.remove("hidden")
    } else {
      // Content fits within maxHeight, hide collapse UI
      this.contentTarget.style.maxHeight = null
      this.footerTarget.classList.add("hidden")
      this.gradientTarget.classList.add("hidden")
    }
  }

  /**
   * Toggle the expanded/collapsed state
   * This handles the show more/less button click
   */
  toggle(event) {
    event.preventDefault()
    const currentHeight = parseInt(this.contentTarget.style.maxHeight) || this.maxHeightValue
    const fullHeight = this.contentTarget.scrollHeight
    const isExpanded = currentHeight >= fullHeight

    if (isExpanded) {
      // Collapse back to initial height
      this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
      this.buttonTextTarget.textContent = "Show more"
      this.iconTarget.classList.remove("rotate-180")
      this.gradientTarget.classList.remove("hidden")
    } else {
      // Expand by increment, but don't exceed full height
      const newHeight = Math.min(currentHeight + this.incrementValue, fullHeight)
      this.contentTarget.style.maxHeight = `${newHeight}px`

      if (newHeight >= fullHeight) {
        this.buttonTextTarget.textContent = "Show less"
        this.iconTarget.classList.add("rotate-180")
        this.gradientTarget.classList.add("hidden")
      }
    }
  }
}