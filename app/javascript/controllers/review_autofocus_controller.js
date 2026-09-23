import { Controller } from "@hotwired/stimulus"

// Moves focus to this element when it arrives on the page. Used on the first
// field of an inline edit form and on a code row re-rendered after a save,
// so keyboard users stay where they were across Turbo Frame swaps.
export default class extends Controller {
  connect() {
    this.element.focus()
  }
}
