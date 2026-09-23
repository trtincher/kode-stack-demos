require "test_helper"

class StatusCheckTest < ActiveSupport::TestCase
  test "database_ok? is true against a reachable database" do
    assert StatusCheck.new.database_ok?
  end

  test "redis_ok? is true against a reachable Redis" do
    assert StatusCheck.new.redis_ok?
  end

  test "redis_ok? is false, not raising, when the connection fails" do
    exploding = ->(*) { raise RedisClient::CannotConnectError, "no route to host" }

    assert_not StatusCheck.new(redis: exploding).redis_ok?
  end

  test "last_heartbeat_at is nil until record_heartbeat! writes one" do
    status = StatusCheck.new(redis: hash_redis)
    assert_nil status.last_heartbeat_at

    at = status.record_heartbeat!(Time.utc(2026, 9, 22, 12, 0, 0))

    assert_equal at.iso8601, status.last_heartbeat_at.iso8601
  end

  private
    # Stands in for the Redis connection with a hash.
    def hash_redis(store = {})
      lambda do |command, *args|
        case command
        when "SET" then store[args[0]] = args[1] and "OK"
        when "GET" then store[args[0]]
        when "PING" then "PONG"
        end
      end
    end
end
