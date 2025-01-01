import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["tldr", "transcript", "takeaways", "tags", "summary", "chatSubmit"]
  static values = {
    videoId: String,
    loading: Boolean,
    interval: { type: Number, default: 5000 },
    maxAttempts: { type: Number, default: 12 }
  }

  connect() {
    console.log("SummaryLoader connected", {
      videoId: this.videoIdValue,
      loading: this.loadingValue,
      interval: this.intervalValue,
      maxAttempts: this.maxAttemptsValue
    })

    // Disable chat submit button if summary is loading
    if (this.loadingValue && this.hasChatSubmitTarget) {
      this.chatSubmitTarget.disabled = true
      this.chatSubmitTarget.title = "Please wait for the summary to complete before asking questions"
    }

    if (this.loadingValue) {
      this.attempts = 0
      this.startPolling()
    }
  }

  disconnect() {
    console.log("SummaryLoader disconnected")
    this.stopPolling()
  }

  startPolling() {
    console.log("Starting polling")
    this.poll()
    this.pollingId = setInterval(() => {
      this.poll()
    }, this.intervalValue)
  }

  stopPolling() {
    if (this.pollingId) {
      console.log("Stopping polling")
      clearInterval(this.pollingId)
      this.pollingId = null
    }
  }

  async poll() {
    try {
      this.attempts++
      console.log(`Polling attempt ${this.attempts}/${this.maxAttemptsValue}`)

      if (this.attempts >= this.maxAttemptsValue) {
        console.warn("Max polling attempts reached")
        this.stopPolling()
        return
      }

      console.log("Checking status...")
      const response = await fetch(`/summaries/${this.videoIdValue}/check_status`, {
        headers: {
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        console.log("Status response:", data)

        if (data.status === "completed" || data.status === "failed") {
          console.log(`Summary ${data.status}, updating sections...`)
          // Update all sections with the new data
          const sections = ["tldr", "transcript", "takeaways", "tags", "summary"]

          for (const section of sections) {
            console.log(`Updating section: ${section}`)
            const updateResponse = await fetch(
              `/summaries/${this.videoIdValue}/check_status?frame_id=${section}`,
              {
                headers: {
                  "Accept": "text/vnd.turbo-stream.html"
                }
              }
            )

            if (updateResponse.ok) {
              const html = await updateResponse.text()
              console.log(`Received Turbo Stream for ${section}`)
              Turbo.renderStreamMessage(html)
            } else {
              console.error(`Failed to update ${section}:`, {
                status: updateResponse.status,
                statusText: updateResponse.statusText
              })
            }
          }

          if (data.status === "completed") {
            // Enable chat submit button when summary is completed
            if (this.hasChatSubmitTarget) {
              this.chatSubmitTarget.disabled = false
              this.chatSubmitTarget.removeAttribute("title")
            }
          }

          if (data.status === "failed") {
            console.error("Summary generation failed:", data.error)
          }

          console.log("All sections updated, stopping polling")
          this.stopPolling()
        } else {
          console.log("Still processing...")
        }
      } else {
        console.error("Status check failed:", response.status)
      }
    } catch (error) {
      console.error("Polling error:", error)
    }
  }
}