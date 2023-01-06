class Throttler
  attr_accessor :requests_allowed, :reset_in_seconds
  REQUESTS_COUNT_KEY = 'requests_count'

  def initialize(requests_allowed: 25, reset_in_seconds: 1)
    @requests_allowed = requests_allowed
    @reset_in_seconds = reset_in_seconds
    redis_cache.del(REQUESTS_COUNT_KEY)
  end

  def increment_counter
    if current_counter_value.zero?
      redis_cache.set(REQUESTS_COUNT_KEY, '1', ex: reset_in_seconds)
    else
      redis_cache.incr(REQUESTS_COUNT_KEY)
    end
  end

  def current_counter_value
    redis_cache.get(REQUESTS_COUNT_KEY).to_i
  end

  def throttle?
    current_counter_value >= (requests_allowed - 1)
  end

  def throttle_for_in_milliseconds
    redis_cache.pttl(REQUESTS_COUNT_KEY)
  end

  private

  def redis_cache
    THROTTLER_CACHE
  end
end