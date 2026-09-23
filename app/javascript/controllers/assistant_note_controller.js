import { Controller } from "@hotwired/stimulus"

// Fills the note from a sample button and keeps the character counter live.
export default class extends Controller {
  static targets = ["input", "counter"]

  connect() {
    this.count()
  }

  pick({ params: { text } }) {
    this.inputTarget.value = text
    this.count()
    this.inputTarget.focus()
  }

  count() {
    this.counterTarget.textContent = this.inputTarget.value.length
  }
}
