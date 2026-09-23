import { Controller } from "@hotwired/stimulus"

// Optimistic claim: the row dims and says "Claiming…" the moment it is
// clicked. The response (or the broadcast) replaces the whole row, so this
// state never has to be undone by hand unless the request itself fails.
export default class extends Controller {
  static targets = ["button"]

  pending() {
    this.row?.classList.add("opacity-60", "ring-indigo-300")
    this.buttonTarget.textContent = "Claiming…"
    this.element.setAttribute("aria-busy", "true")
  }

  // Only reached if the row survived the response, i.e. the request failed.
  settle(event) {
    if (event.detail.success) return
    this.row?.classList.remove("opacity-60", "ring-indigo-300")
    this.buttonTarget.textContent = "Claim"
    this.element.removeAttribute("aria-busy")
  }

  get row() {
    return this.element.closest("article")
  }
}
