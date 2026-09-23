import { Controller } from "@hotwired/stimulus"

// Time left on a claim, ticking down to the SLA. The server's release job is
// the source of truth; this only shows the clock.
export default class extends Controller {
  static values = { expiresAt: String }

  connect() {
    this.render()
    this.timer = setInterval(() => this.render(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  render() {
    const left = Math.max(0, Math.round((Date.parse(this.expiresAtValue) - Date.now()) / 1000))
    const urgent = left <= 30
    this.element.classList.toggle("badge-info", !urgent)
    this.element.classList.toggle("badge-warning", urgent)
    this.element.textContent = left === 0 ? "releasing…" : `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")} left`
  }
}
