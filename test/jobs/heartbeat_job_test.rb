require "test_helper"

class HeartbeatJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  # Runs against the compose Redis (CI uses its valkey service): the point is
  # that the job writes a real heartbeat and pushes a real broadcast.
  test "stores a heartbeat and broadcasts the refreshed status panel" do
    assert_broadcasts("status", 1) { HeartbeatJob.perform_now }

    assert_in_delta Time.current, StatusCheck.new.last_heartbeat_at, 10.seconds
  end
end
