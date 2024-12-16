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
    maxHeight: Number,  // Maximum height (in px) when collapsed
    increment: { type: Number, default: 60 },  // Height increment for each click
    expanded: { type: Boolean, default: false }  // Track expanded state
  }

  /**
   * On connect, check if the content needs the expand/collapse functionality
   * This runs when the controller is initialized
   */
  connect() {
    // Set initial state
    this.currentHeight = this.maxHeightValue
    this.checkOverflow()
  }

  /**
   * Check if content exceeds maxHeight and show/hide controls accordingly
   * This determines whether we need the expand/collapse functionality
   */
  checkOverflow() {
    const content = this.contentTarget
    const isOverflowing = content.scrollHeight > this.maxHeightValue

    if (isOverflowing) {
      // Content is taller than max height, show collapse UI
      content.style.maxHeight = `${this.currentHeight}px`
      this.footerTarget.classList.remove("hidden")
      this.gradientTarget.classList.remove("hidden")
    }
  }

  /**
   * Toggle the expanded/collapsed state
   * This handles the show more/less button click
   */
  toggle(event) {
    // Prevent event from bubbling up to parent links
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const content = this.contentTarget
    const fullHeight = content.scrollHeight

    if (this.expandedValue) {
      // Collapse
      this.currentHeight = this.maxHeightValue
      content.style.maxHeight = `${this.currentHeight}px`
      this.buttonTextTarget.textContent = "Show more"
      this.iconTarget.classList.remove("rotate-180")
      this.gradientTarget.classList.remove("hidden")
      this.expandedValue = false
    } else {
      // Expand incrementally
      this.currentHeight = Math.min(
        this.currentHeight + this.incrementValue,
        fullHeight
      )
      content.style.maxHeight = `${this.currentHeight}px`

      // Check if we've reached full height
      if (this.currentHeight >= fullHeight) {
        this.buttonTextTarget.textContent = "Show less"
        this.iconTarget.classList.add("rotate-180")
        this.gradientTarget.classList.add("hidden")
        this.expandedValue = true
      }
    }
  }
}