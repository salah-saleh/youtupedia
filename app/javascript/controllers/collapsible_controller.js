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
    maxHeight: Number // Maximum height (in px) when collapsed
  }

  /**
   * On connect, check if the content needs the expand/collapse functionality
   * This runs when the controller is initialized
   */
  connect() {
    this.checkOverflow()
  }

  /**
   * Check if content exceeds maxHeight and show/hide controls accordingly
   * This determines whether we need the expand/collapse functionality
   */
  checkOverflow() {
    const isOverflowing = this.contentTarget.scrollHeight > this.maxHeightValue

    if (isOverflowing) {
      // Content is taller than maxHeight, show collapse UI
      this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
      this.footerTarget.classList.remove("hidden")
      this.gradientTarget.classList.remove("hidden")
    } else {
      // Content fits within maxHeight, hide collapse UI
      this.footerTarget.classList.add("hidden")
      this.gradientTarget.classList.add("hidden")
    }
  }

  /**
   * Toggle the expanded/collapsed state
   * This handles the show more/less button click
   */
  toggle() {
    // Check current state by comparing current height to maxHeight
    const isExpanded = this.contentTarget.style.maxHeight !== `${this.maxHeightValue}px`

    if (isExpanded) {
      // Currently expanded, so collapse
      this.contentTarget.style.maxHeight = `${this.maxHeightValue}px`
      this.buttonTextTarget.textContent = "Show more"
      this.iconTarget.classList.remove("rotate-180")
      this.gradientTarget.classList.remove("hidden")
    } else {
      // Currently collapsed, so expand
      this.contentTarget.style.maxHeight = `${this.contentTarget.scrollHeight}px`
      this.buttonTextTarget.textContent = "Show less"
      this.iconTarget.classList.add("rotate-180")
      this.gradientTarget.classList.add("hidden")
    }
  }
}