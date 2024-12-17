import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { text: String }

  copy() {
    let text;

    if (this.hasTextValue) {
      // Use the text value if provided
      text = this.textValue;
    } else if (this.hasSourceTarget) {
      // Otherwise use the source target's content
      const element = this.sourceTarget;
      const temp = document.createElement('div');
      temp.innerHTML = element.innerHTML;

      // Remove all button elements
      temp.querySelectorAll('button').forEach(btn => btn.remove());

      // Get the text content and clean it up
      text = temp.textContent
        .replace(/\s+/g, ' ')  // Replace multiple spaces with single space
        .replace(/\n\s*/g, '\n')  // Clean up newlines
        .trim();

      // For takeaways, format as numbered list
      if (element.classList.contains('space-y-3')) {
        text = text.split(/\d+/).filter(Boolean)  // Split by numbers and remove empty strings
          .map((item, index) => `${index + 1}. ${item.trim()}`)  // Add numbers back
          .join('\n');
      }
    }

    if (!text) return;

    // Copy to clipboard
    navigator.clipboard.writeText(text).then(() => {
      // Show check icon feedback
      const originalHTML = this.buttonTarget.innerHTML;
      this.buttonTarget.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      `;
      this.buttonTarget.disabled = true;

      setTimeout(() => {
        this.buttonTarget.innerHTML = originalHTML;
        this.buttonTarget.disabled = false;
      }, 2000);
    });
  }
}