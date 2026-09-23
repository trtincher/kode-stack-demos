import { Controller } from "@hotwired/stimulus"

// Fills the note from a sample button, keeps the character counter live, and
// holds "Suggest codes" disabled until the page's Turbo Stream subscription
// is connected: the job's broadcasts go nowhere if the page isn't listening
// yet, and a person can click faster than the WebSocket subscribes.
export default class extends Controller {
  static targets = ["input", "counter", "submit", "list", "queued"]

  connect() {
    this.count()
    this.source = this.element.querySelector("turbo-cable-stream-source")
    this.observer = new MutationObserver(() => this.syncSubmit())
    if (this.source) this.observer.observe(this.source, { attributes: true, attributeFilter: ["connected"] })
    this.syncSubmit()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  pick({ params: { text } }) {
    this.inputTarget.value = text
    this.count()
    this.inputTarget.focus()
  }

  count() {
    this.counterTarget.textContent = this.inputTarget.value.length
  }

  syncSubmit() {
    const connected = this.source?.hasAttribute("connected") ?? false
    this.submitTarget.disabled = !connected
    this.submitTarget.value = connected ? this.submitTarget.dataset.label : "Connecting…"
  }

  // A new request clears the previous answer and shows "queued" before the
  // request goes out, so nothing the server sends afterwards can be undone by
  // this step.
  submitStart() {
    this.listTarget.replaceChildren()
    document.getElementById("assistant_status")?.replaceWith(this.queuedTarget.content.cloneNode(true))
  }
}
