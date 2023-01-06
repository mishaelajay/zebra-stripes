class CustomersFetchWorker
  include Sidekiq::Job
  sidekiq_options queue: 'customers_fetch', retry: 2

  KEYS_TO_BE_EXTRACTED = %i[id name email phone address account_balance currency]
  CSV_QUEUE_KEY = 'queue:write_to_csv'

  def perform(directory_path)
    has_more = true
    while has_more
      if throttler_service.throttle?
        throttle_for_in_seconds = throttler_service.throttle_for_in_milliseconds.to_f/1000.0
        sleep(throttle_for_in_seconds)
        puts "Throttling for #{throttle_for_in_seconds}"
      end
      customers,has_more = customers_fetch_service.next_fifty_customers
      throttler_service.increment_counter
      filtered_customer_data = remove_unnecessary_fields(customers.data)
      push_csv_write_queue(filtered_customer_data)
    end
    customers_fetch_service.flush_tracking_cache
    CsvWriteWorker.perform_async(directory_path)
  end

  private

  def push_csv_write_queue(customer_data)
    csv_cache.lpush(CSV_QUEUE_KEY, JSON.dump(customer_data))
  end

  def remove_unnecessary_fields(customers)
    customers.map{ |customer| extract_fields_from_hash(customer)}
  end

  def extract_fields_from_hash(customer)
    customer.to_h.slice(*KEYS_TO_BE_EXTRACTED)
  end

  def throttler_service
    Throttler.new
  end

  def customers_fetch_service
    CustomersFetcher.new
  end

  def csv_cache
    CSV_QUEUE_CACHE
  end
end