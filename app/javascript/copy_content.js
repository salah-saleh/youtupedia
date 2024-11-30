function copyContent(button) {
  const targetId = button.dataset.copyTarget;
  const element = document.getElementById(targetId);

  // Create a temporary element
  const temp = document.createElement('div');
  temp.innerHTML = element.innerHTML;

  // Remove all button elements
  temp.querySelectorAll('button').forEach(btn => btn.remove());

  // Get the text content
  const text = temp.textContent.trim();

  // Copy to clipboard
  navigator.clipboard.writeText(text).then(() => {
    // Show feedback
    const originalText = button.textContent;
    button.textContent = 'Copied!';
    button.disabled = true;

    setTimeout(() => {
      button.textContent = originalText;
      button.disabled = false;
    }, 2000);
  });
}