class CsvWriteWorker
  include Sidekiq::Job
  sidekiq_options queue: 'csv_write', retry: 2

  CSV_QUEUE_KEY = 'queue:write_to_csv'

  def perform(directory_path)
    cws = csv_write_service(directory_path)
    cws.push_headers
    loop do
      batch = csv_cache.rpop(CSV_QUEUE_KEY)
      break if batch.nil?
      parsed_batch = JSON.parse(batch)
      cws.push_batch(parsed_batch)
    end
    csv_cache.flushdb
  end

  private

  def csv_write_service(directory_path)
    CsvWriter.new(
      directory_path:directory_path,
      filename: generate_filename
    )
  end

  def generate_filename
    "stripe_customers_#{Time.now.strftime("%m-%d-%Y.%H.%M.%S")}.csv"
  end
  def csv_cache
    CSV_QUEUE_CACHE
  end
end