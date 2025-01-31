import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner", "content", "originalContent", "expandedContent", "expandAllButton", "globalIcon", "itemToggle"]

  connect() {
    this.expanding = false
    // Initialize all content as expanded (not collapsed)
    this.contentTargets.forEach(content => {
      content.classList.remove('h-0', 'invisible', 'mt-0', 'mb-0')
    })

    // Create floating message element
    this.floatingMessage = document.createElement('div')
    this.floatingMessage.classList.add(
      'absolute', 'z-10', 'bg-purple-600', 'text-white', 'px-3', 'py-2', 'rounded-lg',
      'text-sm', 'shadow-lg', 'transform', 'transition-all', 'duration-200', 'ease-in-out',
      'opacity-0', 'translate-y-2', 'pointer-events-none', 'dark:bg-purple-500',
      'whitespace-nowrap'
    )
    this.floatingMessage.textContent = "Expand information"
    
    // Position it above the expand all button
    const expandAllButton = this.expandAllButtonTarget
    expandAllButton.parentElement.style.position = 'relative'
    expandAllButton.parentElement.appendChild(this.floatingMessage)
    
    // Add highlight effect class
    expandAllButton.classList.add('transition-all', 'duration-200')
    
    // Show message on hover
    expandAllButton.addEventListener('mouseenter', () => this.showFloatingMessage())
    expandAllButton.addEventListener('mouseleave', () => this.hideFloatingMessage())

    // Show message and highlight button on page load
    setTimeout(() => {
      this.showFloatingMessage()
      this.highlightButton()
      // Hide after 3 seconds
      setTimeout(() => {
        this.hideFloatingMessage()
        this.unhighlightButton()
      }, 3000)
    }, 500) // Small delay to ensure everything is loaded
  }

  highlightButton() {
    const button = this.expandAllButtonTarget
    // Add pulsing ring effect
    button.classList.add('ring-4', 'ring-purple-300', 'dark:ring-purple-800', 'animate-pulse')
    // Increase text and icon opacity
    button.classList.add('text-purple-800', 'dark:text-purple-300')
  }

  unhighlightButton() {
    const button = this.expandAllButtonTarget
    // Remove highlight effects
    button.classList.remove(
      'ring-4', 'ring-purple-300', 'dark:ring-purple-800', 'animate-pulse',
      'text-purple-800', 'dark:text-purple-300'
    )
  }

  showFloatingMessage() {
    // Position the message above the button
    this.floatingMessage.style.bottom = 'calc(100% + 5px)'
    this.floatingMessage.style.left = '50%'
    this.floatingMessage.style.transform = 'translateX(-50%)'
    
    // Show with animation
    this.floatingMessage.classList.remove('opacity-0', 'translate-y-2')
    this.floatingMessage.classList.add('opacity-100', 'translate-y-0')

    // Highlight the button
    this.highlightButton()
  }

  hideFloatingMessage() {
    // Hide with animation
    this.floatingMessage.classList.remove('opacity-100', 'translate-y-0')
    this.floatingMessage.classList.add('opacity-0', 'translate-y-2')

    // Remove button highlight
    this.unhighlightButton()
  }

  toggle(event) {
    const button = event.currentTarget
    const timelineItem = button.closest('[data-timeline-item]')
    if (!timelineItem) return

    // Find all toggle buttons for this item to keep them in sync
    const toggleButtons = timelineItem.querySelectorAll('[data-timeline-target="itemToggle"]')
    const content = timelineItem.querySelector('[data-timeline-target="content"]')
    if (!content) return

    const isCollapsed = !content.classList.contains('h-0')
    const contentText = content.querySelector('[data-timeline-target="originalContent"]')

    // Toggle content visibility with synchronized animations
    if (isCollapsed) {
      // First fade out the text
      if (contentText) {
        contentText.style.opacity = '0'
        contentText.style.transform = 'translateY(-10px)'
      }
      
      // Then collapse the container after a small delay
      setTimeout(() => {
        content.classList.add('h-0', 'invisible', 'mt-0', 'mb-0')
      }, 50)
    } else {
      // First expand the container
      content.classList.remove('h-0', 'invisible', 'mt-0', 'mb-0')
      
      // Then fade in the text after a small delay
      if (contentText) {
        setTimeout(() => {
          contentText.style.opacity = '1'
          contentText.style.transform = 'translateY(0)'
        }, 50)
      }
    }

    // Update all toggle buttons for this item
    toggleButtons.forEach(toggleButton => {
      const icon = toggleButton.querySelector('svg')
      if (icon) {
        icon.style.transform = isCollapsed ? '' : 'rotate(180deg)'
      }
      toggleButton.setAttribute('aria-expanded', !isCollapsed)
    })
  }

  toggleAll(event) {
    const button = event.currentTarget
    const icon = button.querySelector('svg')
    const isCollapsed = this.contentTargets.some(content => !content.classList.contains('h-0'))

    this.contentTargets.forEach(content => {
      const contentText = content.querySelector('[data-timeline-target="originalContent"]')
      const timelineItem = content.closest('[data-timeline-item]')
      const toggleButtons = timelineItem?.querySelectorAll('[data-timeline-target="itemToggle"]')

      if (isCollapsed) {
        // First fade out the text
        if (contentText) {
          contentText.style.opacity = '0'
          contentText.style.transform = 'translateY(-10px)'
        }
        
        // Then collapse the container after a small delay
        setTimeout(() => {
          content.classList.add('h-0', 'invisible', 'mt-0', 'mb-0')
        }, 50)
      } else {
        // First expand the container
        content.classList.remove('h-0', 'invisible', 'mt-0', 'mb-0')
        
        // Then fade in the text after a small delay
        if (contentText) {
          setTimeout(() => {
            contentText.style.opacity = '1'
            contentText.style.transform = 'translateY(0)'
          }, 50)
        }
      }

      // Update toggle buttons for this item
      toggleButtons?.forEach(toggleButton => {
        const buttonIcon = toggleButton.querySelector('svg')
        if (buttonIcon) {
          buttonIcon.style.transform = isCollapsed ? '' : 'rotate(180deg)'
        }
        toggleButton.setAttribute('aria-expanded', !isCollapsed)
      })
    })

    // Update global icon
    if (icon) {
      icon.style.transform = isCollapsed ? '' : 'rotate(180deg)'
    }
  }

  startLoading(event) {
    event.preventDefault()
    const button = event.currentTarget
    const timelineItem = button.closest('[data-timeline-item]')
    if (!timelineItem) return

    const expandedFrame = timelineItem.querySelector('[data-timeline-target="expandedContent"]')
    const hasExpandedContent = expandedFrame?.querySelector('[data-expanded-takeaway]')?.textContent.trim() !== ''

    if (hasExpandedContent) {
      // If we already have the content, just toggle visibility
      button.dataset.action = "click->timeline#toggleExpand"
      button.click()
      return
    }

    // Hide button and show spinner
    button.classList.add("hidden")
    const spinner = timelineItem.querySelector('[data-timeline-target="spinner"]')
    if (spinner) spinner.classList.remove("hidden")

    // Ensure content is visible
    const content = timelineItem.querySelector('[data-timeline-target="content"]')
    if (content) {
      content.classList.remove('h-0', 'invisible', 'mt-0', 'mb-0')
    }

    // Submit the form to load expanded content
    const form = button.closest('form')
    if (form) {
      form.setAttribute('data-turbo-frame', button.dataset.turboFrame)
      form.requestSubmit()
    }
  }

  hideSpinner(event) {
    const frame = event.target
    const timelineItem = frame.closest('[data-timeline-item]')
    
    if (timelineItem) {
      const spinner = timelineItem.querySelector('[data-timeline-target="spinner"]')
      const button = timelineItem.querySelector('[data-timeline-target="button"]')
      
      if (spinner) spinner.classList.add("hidden")
      if (button) {
        button.classList.remove("hidden")
        button.classList.add("expanded")
      }
    }
  }

  replaceContent(event) {
    const frame = event.target
    const expandedContent = frame.querySelector("[data-expanded-takeaway]")
    if (!expandedContent) return

    const timelineItem = frame.closest('[data-timeline-item]')
    if (!timelineItem) return

    const originalContent = timelineItem.querySelector('[data-timeline-target="originalContent"]')
    const button = timelineItem.querySelector('[data-timeline-target="button"]')

    // Hide spinner and show button
    const spinner = timelineItem.querySelector('[data-timeline-target="spinner"]')
    if (spinner) spinner.classList.add("hidden")
    if (button) {
      button.classList.remove("hidden")
      button.classList.add("expanded")
      
      // Update button to handle toggle between original and expanded content
      button.dataset.action = "click->timeline#toggleExpand"
      const icon = button.querySelector('svg')
      if (icon) icon.style.transform = 'rotate(180deg)'
    }

    // Fade out original content and show expanded
    if (originalContent) {
      originalContent.style.opacity = '0'
      originalContent.style.transform = 'translateY(-10px)'
      
      setTimeout(() => {
        originalContent.classList.add("hidden")
        frame.classList.remove("hidden")
        frame.style.opacity = '1'
        frame.style.transform = 'translateY(0)'
      }, 50)
    }
  }

  toggleExpand(event) {
    event.preventDefault()
    const button = event.currentTarget
    const timelineItem = button.closest('[data-timeline-item]')
    if (!timelineItem) return

    const originalContent = timelineItem.querySelector('[data-timeline-target="originalContent"]')
    const expandedFrame = timelineItem.querySelector('[data-timeline-target="expandedContent"]')
    const icon = button.querySelector('svg')

    const isExpanded = originalContent.classList.contains('hidden')

    if (isExpanded) {
      // Switch to original content
      expandedFrame.style.opacity = '0'
      expandedFrame.style.transform = 'translateY(-10px)'
      
      setTimeout(() => {
        expandedFrame.classList.add('hidden')
        originalContent.classList.remove('hidden')
        originalContent.style.opacity = '1'
        originalContent.style.transform = 'translateY(0)'
      }, 50)

      button.classList.remove('expanded')
      if (icon) icon.style.transform = ''
    } else {
      // Switch to expanded content
      originalContent.style.opacity = '0'
      originalContent.style.transform = 'translateY(-10px)'
      
      setTimeout(() => {
        originalContent.classList.add('hidden')
        expandedFrame.classList.remove('hidden')
        expandedFrame.style.opacity = '1'
        expandedFrame.style.transform = 'translateY(0)'
      }, 50)

      button.classList.add('expanded')
      if (icon) icon.style.transform = 'rotate(180deg)'
    }
  }

  async expandAll() {
    if (this.expanding) return

    this.expanding = true
    const expandAllButton = this.expandAllButtonTarget
    const icon = expandAllButton?.querySelector('svg')
    
    // Add transition class to icon
    if (icon) {
      icon.classList.add('transition-transform', 'duration-200', 'ease-in-out')
    }

    try {
      const timelineItems = Array.from(this.element.querySelectorAll('[data-timeline-item]'))
      const allExpanded = timelineItems.every(item => 
        item.querySelector('[data-timeline-target="button"].expanded')
      )

      if (allExpanded) {
        // Collapse all items
        for (const item of timelineItems) {
          const button = item.querySelector('[data-timeline-target="button"].expanded')
          if (!button) continue

          const originalContent = item.querySelector('[data-timeline-target="originalContent"]')
          const expandedFrame = item.querySelector('[data-timeline-target="expandedContent"]')

          // Use the same animation as individual toggle
          expandedFrame.style.opacity = '0'
          expandedFrame.style.transform = 'translateY(-10px)'
          
          setTimeout(() => {
            expandedFrame.classList.add('hidden')
            originalContent.classList.remove('hidden')
            originalContent.style.opacity = '1'
            originalContent.style.transform = 'translateY(0)'
          }, 50)

          button.classList.remove('expanded')
          const buttonIcon = button.querySelector('svg')
          if (buttonIcon) buttonIcon.style.transform = ''
        }

        // Update global icon
        if (icon) {
          icon.style.transform = ''
        }
      } else {
        // Process all items
        for (const item of timelineItems) {
          const button = item.querySelector('[data-timeline-target="button"]:not(.expanded)')
          if (!button) continue

          const expandedFrame = item.querySelector('[data-timeline-target="expandedContent"]')
          const hasExpandedContent = expandedFrame?.querySelector('[data-expanded-takeaway]')?.textContent.trim() !== ''

          if (hasExpandedContent) {
            // If we already have the content, just toggle visibility
            button.dataset.action = "click->timeline#toggleExpand"
            button.click()
          } else {
            // Need to load content
            const content = item.querySelector('[data-timeline-target="content"]')
            if (content) {
              content.classList.remove('h-0', 'invisible', 'mt-0', 'mb-0')
            }

            button.classList.add("hidden")
            const spinner = item.querySelector('[data-timeline-target="spinner"]')
            if (spinner) spinner.classList.remove("hidden")

            const form = button.closest('form')
            if (form && expandedFrame) {
              expandedFrame.classList.add('hidden')
              expandedFrame.innerHTML = '<div data-expanded-takeaway></div>'
              form.setAttribute('data-turbo-frame', button.dataset.turboFrame)

              try {
                await new Promise((resolve, reject) => {
                  const timeout = setTimeout(() => reject(new Error("Expansion timed out")), 10000)

                  const handleLoad = () => {
                    clearTimeout(timeout)
                    setTimeout(resolve, 100)
                  }

                  expandedFrame.addEventListener("turbo:frame-load", handleLoad, { once: true })
                  form.requestSubmit()
                })

                const buttonIcon = button.querySelector('svg')
                if (buttonIcon) {
                  buttonIcon.style.transform = 'rotate(180deg)'
                }
              } catch (error) {
                console.error(`Failed to expand item: ${error.message}`)
                if (spinner) spinner.classList.add("hidden")
                button.classList.remove("hidden")
              }
            }
          }
        }

        // Update global icon for expansion
        if (icon) {
          icon.style.transform = 'rotate(180deg)'
        }
      }
    } finally {
      this.expanding = false
      if (expandAllButton) {
        expandAllButton.disabled = false
      }
    }
  }
} 