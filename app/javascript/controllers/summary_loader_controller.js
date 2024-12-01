import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["tldr", "takeaways", "tags", "summary"]
  static values = {
    videoId: String,
    interval: { type: Number, default: 2000 },
    maxAttempts: { type: Number, default: 30 }
  }

  connect() {
    console.log("SummaryLoader connected", {
      videoId: this.videoIdValue,
      interval: this.intervalValue,
      maxAttempts: this.maxAttemptsValue,
      targets: {
        tldr: this.hasTldrTarget,
        takeaways: this.hasTakeawaysTarget,
        tags: this.hasTagsTarget,
        summary: this.hasSummaryTarget
      }
    })
    this.attempts = 0
    this.startPolling()
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

        if (data.status === "completed") {
          console.log("Summary completed, updating sections...")
          // Update all sections with the new data
          const sections = ["tldr", "takeaways", "tags", "summary"]

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
              console.log(`Received Turbo Stream for ${section}:`, {
                status: updateResponse.status,
                headers: Object.fromEntries(updateResponse.headers.entries()),
                html: html
              })

              // Process the Turbo Stream response
              Turbo.renderStreamMessage(html)
            } else {
              console.error(`Failed to update ${section}:`, {
                status: updateResponse.status,
                statusText: updateResponse.statusText
              })
            }
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