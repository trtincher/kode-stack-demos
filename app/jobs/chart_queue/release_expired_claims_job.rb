# Puts claims that blew their SLA back in the queue. Each claim schedules one
# of these for its deadline (no cron, no chain); the sweep releases every
# expired claim it finds, so duplicate or late runs are harmless.
class ChartQueue::ReleaseExpiredClaimsJob < ApplicationJob
  queue_as :default

  # Returns how many claims were released.
  def perform
    ChartQueue::Chart.transaction do
      # SKIP LOCKED: a chart being completed right now is left to that
      # transaction, which is completing or releasing it anyway.
      ChartQueue::Chart.expired.lock("FOR UPDATE SKIP LOCKED").to_a.count(&:release!)
    end
  end
end
