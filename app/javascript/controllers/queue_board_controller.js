import { Controller } from "@hotwired/stimulus"

// The board's per-tab brain. Rows arrive over a shared broadcast that does not
// know who is looking, so this tab (1) stamps its coder into every form it
// submits, (2) shows owner-only buttons on rows its coder holds, and (3) polls
// for the columns if Action Cable never connects.
export default class extends Controller {
  static values = { coder: String, columnsUrl: String }
  static targets = ["row", "polling"]

  connect() {
    this.fallback = setTimeout(() => this.startPolling(), 5000)
  }

  disconnect() {
    clearTimeout(this.fallback)
    this.stopPolling()
  }

  stamp(event) {
    const field = event.target.querySelector("input[name='as']")
    if (field && this.coderValue) field.value = this.coderValue
  }

  rowTargetConnected(row) {
    const mine = this.coderValue !== "" && row.dataset.coder === this.coderValue
    row.querySelectorAll("[data-owner-only]").forEach((el) => { el.hidden = !mine })
  }

  // Fallback for hosts without WebSockets: re-fetch the columns every 5s
  // until the cable connects.
  startPolling() {
    if (this.cableConnected || this.poll) return
    this.pollingTarget.classList.remove("hidden")
    this.poll = setInterval(() => this.refresh(), 5000)
  }

  stopPolling() {
    clearInterval(this.poll)
    this.poll = null
    if (this.hasPollingTarget) this.pollingTarget.classList.add("hidden")
  }

  async refresh() {
    if (this.cableConnected) return this.stopPolling()

    const response = await fetch(this.columnsUrlValue, { headers: { Accept: "text/vnd.turbo-stream.html" } })
    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }

  get cableConnected() {
    return document.querySelector("turbo-cable-stream-source[connected]") !== null
  }
}
