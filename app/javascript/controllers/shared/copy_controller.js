import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { text: String }

  copy(event) {
    let text;
    const button = event.currentTarget;

    // If copying a single timeline item
    if (button.hasAttribute('data-copy-single-target')) {
      text = `${button.dataset.topic}\n${button.dataset.takeaway}`;
    } else if (this.hasTextValue) {
      // Use the text value if provided
      text = this.textValue;
    } else if (this.hasSourceTarget) {
      // Otherwise use the source target's content
      const element = this.sourceTarget;

      // If it's a timeline section
      if (element.querySelector('[data-timeline-item]')) {
        const items = [];
        element.querySelectorAll('[data-timeline-item]').forEach(item => {
          const topic = item.querySelector('[data-timeline-topic]').textContent.trim();
          const takeaway = item.querySelector('[data-timeline-takeaway]').textContent.trim();
          items.push(`${topic}\n${takeaway}`);
        });
        text = items.join('\n\n');
      } else {
        // For regular content (like before)
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
    }

    if (!text) return;

    // Copy to clipboard
    navigator.clipboard.writeText(text).then(() => {
      // Show check icon feedback
      const targetButton = button.hasAttribute('data-copy-single-target') ? button : this.buttonTarget;
      const originalHTML = targetButton.innerHTML;
      const checkIcon = `
        <svg xmlns="http://www.w3.org/2000/svg" class="${targetButton.firstElementChild.classList.value}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      `;
      targetButton.innerHTML = checkIcon;
      targetButton.disabled = true;

      setTimeout(() => {
        targetButton.innerHTML = originalHTML;
        targetButton.disabled = false;
      }, 2000);
    });
  }
}