import { Controller } from "@hotwired/stimulus"

// Reviewer keyboard shortcuts on the chart page:
//   a  approve            r  jump to the return note
//   e  edit focused row   ?  show / hide the legend
// Ignored while typing in a field or with a modifier held, so the keys never
// hijack text entry or browser shortcuts.
export default class extends Controller {
  static targets = ["approve", "returnNote", "row", "legend", "legendToggle"]

  connect() {
    this.lastRowId = null
    this.trackRow = (event) => {
      const frame = event.target.closest("turbo-frame")
      if (frame && this.element.contains(frame)) this.lastRowId = frame.id
    }
    this.element.addEventListener("focusin", this.trackRow)
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.trackRow)
  }

  handle(event) {
    if (event.metaKey || event.ctrlKey || event.altKey || this.typing(event.target)) return

    switch (event.key) {
      case "a":
        if (this.hasApproveTarget) this.run(event, () => this.approveTarget.click())
        break
      case "r":
        if (this.hasReturnNoteTarget) this.run(event, () => this.returnNoteTarget.focus())
        break
      case "e":
        this.run(event, () => this.editFocusedRow())
        break
      case "?":
        this.run(event, () => this.toggleLegend())
        break
    }
  }

  toggleLegend() {
    const show = this.legendTarget.hidden
    this.legendTarget.hidden = !show
    this.legendToggleTarget.setAttribute("aria-expanded", String(show))
  }

  editFocusedRow() {
    const frame = document.activeElement?.closest("turbo-frame") ||
      (this.lastRowId && document.getElementById(this.lastRowId))
    frame?.querySelector("a[data-review-edit]")?.click()
  }

  run(event, action) {
    event.preventDefault()
    action()
  }

  typing(element) {
    return element.isContentEditable || ["INPUT", "TEXTAREA", "SELECT"].includes(element.tagName)
  }
}
