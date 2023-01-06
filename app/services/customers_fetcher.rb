class CustomersFetcher
  DEFAULT_API_KEY = Rails.application.credentials.stripe_api_key
  def initialize
    @api_key = DEFAULT_API_KEY
    Stripe.api_key = @api_key
  end

  def next_fifty_customers
    has_more = false
    starting_after = get_starting_after
    customers = list_customers(starting_after: starting_after)
    new_starting_after = customers.data&.last&.id
    has_more = customers.has_more
    set_starting_after(new_starting_after)
    [customers, has_more]
  end

  def list_customers(limit: 50, starting_after:)
    params = {limit: limit}
    params[:starting_after] = starting_after unless starting_after.nil?
    Stripe::Customer.list(params)
  end

  def flush_tracking_cache
    page_tracker_cache.flushdb
  end

  private

  def get_starting_after
    page_tracker_cache.get('current_starting_after')
  end

  def set_starting_after(starting_after)
    page_tracker_cache.set('current_starting_after', starting_after)
  end

  def page_tracker_cache
    PAGE_TRACKER_CACHE
  end
end