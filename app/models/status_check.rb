# Reads the liveness of the three moving parts the scaffold stands on:
# PostgreSQL, Redis/Valkey, and the Sidekiq worker (via a heartbeat key that
# HeartbeatJob writes). Every probe fails soft — the hello page must render
# even when a dependency is down, because saying "unreachable" is the point.
class StatusCheck
  HEARTBEAT_KEY = "status:heartbeat".freeze

  # Sidekiq owns the Redis pool, so borrow it rather than opening a second one.
  # Injectable so tests can hand in a hash or a raising stub.
  SIDEKIQ_REDIS = ->(*args) { Sidekiq.redis { |conn| conn.call(*args) } }

  def initialize(redis: SIDEKIQ_REDIS)
    @redis = redis
  end

  def database_ok?
    ActiveRecord::Base.connection.select_value("SELECT 1").to_i == 1
  rescue StandardError
    false
  end

  def redis_ok?
    @redis.call("PING") == "PONG"
  rescue StandardError
    false
  end

  def last_heartbeat_at
    raw = @redis.call("GET", HEARTBEAT_KEY)
    raw.present? ? Time.zone.parse(raw) : nil
  rescue StandardError
    nil
  end

  # Called by HeartbeatJob; returns the timestamp it stored.
  def record_heartbeat!(at = Time.current)
    @redis.call("SET", HEARTBEAT_KEY, at.iso8601)
    at
  end
end
