# Writes a heartbeat timestamp to Redis and pushes the refreshed status panel
# to every open page over Action Cable. One job exercises the whole stack:
# Sidekiq picked it up, Redis stored it, Turbo Streams delivered it.
class HeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    status = StatusCheck.new
    status.record_heartbeat!

    Turbo::StreamsChannel.broadcast_replace_to(
      "status",
      target: "status_panel",
      partial: "pages/status_panel",
      locals: { status: status }
    )
  end
end
