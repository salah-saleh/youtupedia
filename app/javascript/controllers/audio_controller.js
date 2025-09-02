// Audio controller for handling text-to-speech generation
// 
// This controller manages the audio summary generation process using Turbo Streams:
// 1) Handles the generate audio button clicks
// 2) Sends Turbo Stream requests to the backend to start audio generation
// 3) Shows loading states during the request
// 4) Lets Turbo Streams handle all UI updates and notifications
//
// Dependencies:
// - Requires data-audio-video-id-value to be set on buttons
// - Integrates with Rails Turbo Streams for real-time DOM updates
// - Server responses update the UI automatically via Turbo Stream responses
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Stimulus targets
  static targets = ["button", "content"]
  
  // Stimulus values
  static values = { 
    videoId: String,
    generating: { type: Boolean, default: false }
  }

  // Connect lifecycle method
  connect() {
    console.log("Audio controller connected")
  }

  // Disconnect lifecycle method
  disconnect() {
    console.log("Audio controller disconnected")
  }

  // Generate audio summary from text summary
  async generateAudio(event) {
    event.preventDefault()
    
    if (this.generatingValue) {
      console.log("Audio generation already in progress")
      return
    }

    const button = event.currentTarget
    const videoId = this.videoIdValue || button.dataset.audioVideoIdValue
    
    if (!videoId) {
      console.error("No video ID found for audio generation")
      return
    }

    // Set generating state
    this.generatingValue = true
    this.updateButtonState(button, true)

    try {
      console.log(`Starting audio generation for video ${videoId} with Algenib voice`)
      
      // Create form data for Turbo Stream request
      const formData = new FormData()
      formData.append("voice", "Algenib")
      formData.append("authenticity_token", this.getCsrfToken())
      
      // Make Turbo Stream request to start audio generation
      const response = await fetch(`/summaries/${videoId}/generate_audio`, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.getCsrfToken()
        },
        body: formData
      })

      if (response.ok) {
        console.log("Audio generation request sent successfully")
        // Turbo Streams will handle the UI updates automatically
        // The server response will update the DOM directly
        
        // Reset generating state after a short delay to allow Turbo Stream to update
        setTimeout(() => {
          this.generatingValue = false
          // Don't reset button state here - let Turbo Stream handle it
        }, 500)
      } else {
        console.error("Failed to start audio generation", response.statusText)
        // Reset state on error
        this.generatingValue = false
        this.updateButtonState(button, false)
      }

    } catch (error) {
      console.error("Error during audio generation request", error)
      // Reset state on exception
      this.generatingValue = false
      this.updateButtonState(button, false)
    }
  }

  // Update button state during generation
  updateButtonState(button, isGenerating) {
    if (isGenerating) {
      button.disabled = true
      button.innerHTML = `
        <svg class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Generating...
      `
      button.classList.add("opacity-75", "cursor-not-allowed")
    } else {
      button.disabled = false
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>
        </svg>
        Create Audio Summary
      `
      button.classList.remove("opacity-75", "cursor-not-allowed")
    }
  }

  // Get CSRF token from meta tag
  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
  }

  // Reset button state when job completes (called by Turbo Stream updates)
  resetGeneratingState() {
    console.log("Resetting audio generation state")
    this.generatingValue = false
    const button = this.element.querySelector('#generate-audio-btn')
    if (button) {
      this.updateButtonState(button, false)
    }
  }

  // Note: Toast notifications are now handled by Turbo Stream responses from the server
  // This provides better consistency with the app's flash message system
}
