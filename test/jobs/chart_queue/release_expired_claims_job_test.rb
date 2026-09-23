require "test_helper"

class ChartQueue::ReleaseExpiredClaimsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  setup do
    Seeds.load_all!
    Seeds::Queue.reset!
  end

  test "claims past the SLA go back to the queue and the board hears about it; fresh claims stay" do
    maya = ChartQueue::Coder.find_by!(slug: "maya")
    fresh = nil
    assert_enqueued_with(job: ChartQueue::ReleaseExpiredClaimsJob) { fresh = ChartQueue::Chart.claim_next!(maya) }
    seeded = ChartQueue::Chart.claimed.where.not(id: fresh.id).to_a

    travel ChartQueue::Chart::CLAIM_SLA - 30.seconds do
      # Seeded claims were taken 80s and 120s ago, so they are past the SLA now.
      assert_broadcasts(ChartQueue::Chart::STREAM, seeded.size) do
        assert_equal seeded.size, ChartQueue::ReleaseExpiredClaimsJob.perform_now
      end
    end

    assert seeded.all? { |chart| chart.reload.available? && chart.coder.nil? }
    assert fresh.reload.claimed?
    assert_equal 0, ChartQueue::ReleaseExpiredClaimsJob.perform_now
  end
end
