THROTTLER_CACHE = Redis.new(
  url: 'redis://localhost:6379/1'
)

CSV_QUEUE_CACHE = Redis.new(
  url: 'redis://localhost:6379/2'
)

PAGE_TRACKER_CACHE = Redis.new(
  url: 'redis://localhost:6379/3'
)