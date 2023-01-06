desc "Save stripe customers to a csv file"
task :save_stripe_customers_to_csv, [:target_directory,:api_key] => :environment do |t, args|
  target_directory = args.target_directory || Dir.home + '/stripe_csv'
  api_key = args.api_key
  csv_cache_key = 'queue:write_to_csv'
  puts "Your files will be downloaded to #{target_directory} in some time"
  # flush all caches
  THROTTLER_CACHE.flushall
  CSV_QUEUE_CACHE.flushall
  PAGE_TRACKER_CACHE.flushall
  # Fetch data to cache
  CustomersFetchWorker.perform_async(api_key)
  # Load data from cache to csv
  CsvWriteWorker.perform_async(target_directory, csv_cache_key)
end
