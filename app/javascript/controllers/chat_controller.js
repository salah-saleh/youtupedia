import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["input", "messagesContainer", "submitButton", "loading"]
  static values = {
    videoId: String
  }

  connect() {
    this.csrfToken = document.querySelector("meta[name='csrf-token']").content
    marked.setOptions({
      breaks: true,
      gfm: true
    })
  }

  async submitQuestion(event) {
    event.preventDefault()

    const question = this.inputTarget.value.trim()
    if (!question) return

    // Disable form while processing
    this.submitButtonTarget.disabled = true
    this.loadingTarget.classList.remove("hidden")

    // Add question to chat
    this.addMessageToChat("user", question)

    try {
      const response = await fetch(`/summaries/${this.videoIdValue}/ask_gpt`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ question })
      })

      const data = await response.json()

      if (data.success) {
        this.addMessageToChat("assistant", data.answer)
      } else {
        this.addMessageToChat("error", "Sorry, there was an error processing your question.")
      }
    } catch (error) {
      console.error("Error:", error)
      this.addMessageToChat("error", "Sorry, there was an error processing your question.")
    } finally {
      // Re-enable form
      this.submitButtonTarget.disabled = false
      this.loadingTarget.classList.add("hidden")
      this.inputTarget.value = ""
    }
  }

  addMessageToChat(role, content) {
    const messageDiv = document.createElement("div")
    messageDiv.className = `p-3 rounded-lg mb-4 ${this.getMessageClasses(role)}`
    messageDiv.innerHTML = `
      <div class="flex items-start gap-2">
        <span class="font-medium ${role === 'user' ? 'text-purple-700' : 'text-gray-700'}">
          ${role === 'user' ? 'You' : 'Assistant'}:
        </span>
        <div class="flex-1 prose prose-sm max-w-none">
          ${role === 'user' ? content : marked.parse(content)}
        </div>
      </div>
    `
    this.messagesContainerTarget.appendChild(messageDiv)
    this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
  }

  getMessageClasses(role) {
    switch (role) {
      case 'user':
        return 'bg-purple-50'
      case 'assistant':
        return 'bg-gray-50'
      case 'error':
        return 'bg-red-50 text-red-700'
      default:
        return 'bg-gray-50'
    }
  }
}