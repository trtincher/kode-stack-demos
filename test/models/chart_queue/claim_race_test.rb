require "test_helper"

class ChartQueue::ClaimRaceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # Real concurrency needs real transactions on two connections.
  self.use_transactional_tests = false

  setup do
    Seeds.load_all!
    Seeds::Queue.reset!
    @maya = ChartQueue::Coder.find_by!(slug: "maya")
    @dev = ChartQueue::Coder.find_by!(slug: "dev")
    @chart = ChartQueue::Chart.available.order(:due_at).first
  end

  teardown do
    ChartQueue::Chart.delete_all
    ChartQueue::Coder.delete_all
  end

  test "while one claim holds the row lock, a second claim skips it instead of waiting or double-claiming" do
    locked = Queue.new
    finish = Queue.new

    holder = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        # Keep Maya's claim transaction open so the row stays locked.
        ChartQueue::Chart.transaction do
          ChartQueue::Chart.claim!(@chart.id, @maya)
          locked << true
          finish.pop
        end
      end
    end
    locked.pop

    # Plain FOR UPDATE would block here; NOWAIT would raise. SKIP LOCKED
    # returns at once: no chart for Dev, and "claim next" hands him another.
    Timeout.timeout(2) do
      assert_nil ChartQueue::Chart.claim!(@chart.id, @dev)
      other = ChartQueue::Chart.claim_next!(@dev)
      assert other
      assert_not_equal @chart.id, other.id
    end

    finish << true
    holder.join

    assert_equal @maya, @chart.reload.coder
    assert_nil ChartQueue::Chart.claim!(@chart.id, @dev), "a committed claim is not available either"
  end
end
