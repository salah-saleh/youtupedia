import { Controller } from "@hotwired/stimulus"

/**
 * Theme Controller
 *
 * Handles dark mode toggling and persistence
 */
export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    // Check for saved theme preference or system preference
    const prefersDark = localStorage.theme === 'dark' ||
      (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)

    // Set initial state without animation
    if (prefersDark) {
      this.enableDarkMode(false)
    } else {
      this.disableDarkMode(false)
    }

    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      if (!('theme' in localStorage)) {
        if (e.matches) {
          this.enableDarkMode(true)
        } else {
          this.disableDarkMode(true)
        }
      }
    })
  }

  toggle() {
    const isDark = document.documentElement.classList.contains('dark')
    if (isDark) {
      this.disableDarkMode(true)
    } else {
      this.enableDarkMode(true)
    }
  }

  enableDarkMode(animate = true) {
    // Add dark mode to HTML root
    document.documentElement.classList.add('dark')
    localStorage.theme = 'dark'

    // Update toggle state
    this.element.setAttribute('aria-checked', 'true')
    if (animate) {
      this.element.classList.add('transition-colors')
      this.indicatorTarget.classList.add('transition')
    }

    // Update toggle appearance
    this.element.classList.remove('bg-gray-200')
    this.element.classList.add('bg-gray-700')
    this.indicatorTarget.classList.add('translate-x-5')
  }

  disableDarkMode(animate = true) {
    // Remove dark mode from HTML root
    document.documentElement.classList.remove('dark')
    localStorage.theme = 'light'

    // Update toggle state
    this.element.setAttribute('aria-checked', 'false')
    if (animate) {
      this.element.classList.add('transition-colors')
      this.indicatorTarget.classList.add('transition')
    }

    // Update toggle appearance
    this.element.classList.remove('bg-gray-700')
    this.element.classList.add('bg-gray-200')
    this.indicatorTarget.classList.remove('translate-x-5')
  }
}