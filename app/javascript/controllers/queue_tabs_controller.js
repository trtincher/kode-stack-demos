import { Controller } from "@hotwired/stimulus"

// Notices other tabs on this board (BroadcastChannel, same browser only) and
// swaps the hint for a nudge to race them.
export default class extends Controller {
  static targets = ["hint"]

  connect() {
    if (!("BroadcastChannel" in window)) return

    this.id = Math.random().toString(36).slice(2)
    this.peers = new Map()
    this.original = this.hintTarget.innerHTML
    this.channel = new BroadcastChannel("kode-queue-board")
    this.channel.onmessage = ({ data }) => this.heard(data)
    this.ping()
    this.timer = setInterval(() => this.ping(), 2000)
  }

  disconnect() {
    clearInterval(this.timer)
    this.channel?.close()
  }

  ping() {
    this.channel.postMessage({ id: this.id })
    const now = Date.now()
    for (const [id, seen] of this.peers) if (now - seen > 5000) this.peers.delete(id)
    this.render()
  }

  heard({ id }) {
    if (!id || id === this.id) return
    const isNew = !this.peers.has(id)
    this.peers.set(id, Date.now())
    if (isNew) { this.channel.postMessage({ id: this.id }); this.render() }
  }

  render() {
    const tabs = this.peers.size + 1
    this.hintTarget.innerHTML = tabs > 1
      ? `You are in <strong class="font-semibold text-slate-900">${tabs} tabs</strong>. Pick a different coder in each, then click Claim on the same chart in both: one wins, the other flips to &ldquo;claimed by&rdquo;.`
      : this.original
  }
}
