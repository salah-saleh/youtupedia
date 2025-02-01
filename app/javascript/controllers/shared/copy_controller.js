import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values = { text: String }

  connect() {
    console.log("Copy controller connected", {
      hasSourceTarget: this.hasSourceTarget,
      hasButtonTarget: this.hasButtonTarget,
      hasTextValue: this.hasTextValue
    });
  }

  copy(event) {
    let text;
    const button = event.currentTarget;

    // If copying a single timeline item
    if (button.hasAttribute('data-copy-single-target')) {
      const timelineItem = button.closest('[data-timeline-item]');
      const topic = button.dataset.topic;
      
      // Get either expanded or original content
      const expandedContent = timelineItem.querySelector('[data-expanded-takeaway]');
      const originalContent = timelineItem.querySelector('[data-timeline-target="originalContent"]');
      let takeaway;
      
      if (expandedContent && !expandedContent.classList.contains('hidden')) {
        // For expanded content, collect bullet points
        const bullets = Array.from(expandedContent.querySelectorAll('li')).map(li => li.textContent.trim());
        takeaway = bullets.join('\n  - ');
      } else {
        takeaway = originalContent?.textContent.trim() || button.dataset.takeaway;
      }
      
      text = `- ${topic}\n  - ${takeaway}`;
    } else if (this.hasTextValue) {
      text = this.textValue;
    } else if (this.hasSourceTarget) {
      const element = this.sourceTarget;

      // If it's a timeline section
      if (element.querySelector('[data-timeline-item]')) {
        const items = [];
        element.querySelectorAll('[data-timeline-item]').forEach(item => {
          const topicElement = item.querySelector('h4[data-timeline-topic]');
          const topic = topicElement?.textContent.trim() || '';
          
          // Get the takeaway content
          const originalContent = item.querySelector('[data-timeline-target="originalContent"]');
          let takeaway = '';
          
          // If there's an expanded content and it's visible, use bullet points
          const expandedContent = item.querySelector('[data-expanded-takeaway]');
          const expandedParent = expandedContent?.closest('[data-timeline-target="expandedContent"]');
          if (expandedContent && expandedParent && !expandedParent.classList.contains('hidden')) {
            const bullets = Array.from(expandedContent.querySelectorAll('li')).map(li => li.textContent.trim());
            takeaway = bullets.join('\n  - ');
          } else {
            takeaway = originalContent?.textContent.trim() || '';
          }
          
          if (topic && takeaway) {
            items.push(`- ${topic}\n  - ${takeaway}`);
          }
        });
        text = items.join('\n\n');
      } else {
        // For regular content
        const temp = document.createElement('div');
        temp.innerHTML = element.innerHTML;

        // Remove unwanted elements
        temp.querySelectorAll('button, [data-timeline-target="spinner"], turbo-frame').forEach(el => el.remove());

        // Get the text content and clean it up
        text = temp.textContent
          .replace(/\s+/g, ' ')  // Replace multiple spaces with single space
          .replace(/\n\s*/g, '\n')  // Clean up newlines
          .replace(/\n{3,}/g, '\n\n')  // Replace 3 or more newlines with 2
          .trim();

        // For takeaways, format as numbered list
        if (element.classList.contains('space-y-3')) {
          text = text.split(/\d+/).filter(Boolean)  // Split by numbers and remove empty strings
            .map((item, index) => `${index + 1}. ${item.trim()}`)  // Add numbers back
            .join('\n');
        }
      }
    } else {
      return;
    }

    if (!text) {
      return;
    }

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
    }).catch(error => {
      console.error('Failed to copy text:', error);
    });
  }
}