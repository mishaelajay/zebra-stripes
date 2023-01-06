require 'rails_helper'

RSpec.describe CustomersFetcher do
  context "lists 50 customers as expected" do
    let(:customers_fetcher_service) { CustomersFetcher.new }
    let(:page_mock_cache) { MockRedis.new }
    before do
      page_mock_cache.flushdb
      allow(customers_fetcher_service).to receive(:page_tracker_cache).and_return(page_mock_cache)
    end

    it "should return 50 customers and set cache" do
      VCR.use_cassette("customers_first_page") do
        customers,has_more = customers_fetcher_service.next_fifty_customers
        expect(customers.data.count).to be 50
        expect(page_mock_cache.get('current_starting_after')).to equal(customers.data.last.id)
      end
    end

    it "should update page cache for second batch" do
      VCR.use_cassette("customers_multiple_pages") do
        customers,has_more = customers_fetcher_service.next_fifty_customers
        expect(customers.data.count).to be 50
        expect(page_mock_cache.get('current_starting_after')).to equal(customers.data.last.id)
        next_customers, next_hash_more = customers_fetcher_service.next_fifty_customers
        expect(customers.data.count).to be 50
        expect(customers.data.last.id).not_to be(next_customers.data.last.id)
        expect(page_mock_cache.get('current_starting_after')).to equal(next_customers.data.last.id)
      end
    end
  end
end