class CustomersFetchWorker
  include Sidekiq::Job
  sidekiq_options queue: 'customers_fetch', retry: 0

  
end