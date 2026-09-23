require "test_helper"

class StatusCheckTest < ActiveSupport::TestCase
  test "reports the database and Redis as reachable when they are up" do
    status = StatusCheck.new

    assert status.database_ok?
    assert status.redis_ok?
  end

  test "fails soft: an unreachable Redis reads as down, never raises" do
    exploding = ->(*) { raise RedisClient::CannotConnectError, "no route to host" }
    status = StatusCheck.new(redis: exploding)

    assert_not status.redis_ok?
    assert_nil status.last_heartbeat_at
  end
end
