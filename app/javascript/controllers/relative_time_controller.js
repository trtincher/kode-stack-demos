import { Controller } from "@hotwired/stimulus"

// Renders a timestamp as "12s ago" and keeps counting, so the panel shows the
// heartbeat aging without another round trip.
export default class extends Controller {
  static values = { at: String }

  connect() {
    this.render()
    this.timer = setInterval(() => this.render(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  render() {
    const seconds = Math.max(0, Math.round((Date.now() - Date.parse(this.atValue)) / 1000))
    this.element.textContent = `${this.humanize(seconds)} ago`
    this.element.title = this.atValue
  }

  humanize(seconds) {
    if (seconds < 60) return `${seconds}s`
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m`
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`
    return `${Math.floor(seconds / 86400)}d`
  }
}
