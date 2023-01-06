require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe CustomersFetchWorker do
  context "test basic functions of worker" do
    let(:directory_path) { Dir.mktmpdir }
    let(:csv_q_cache) { MockRedis.new }
    let(:cf_worker) { CustomersFetchWorker.new }
    let(:csv_cache_key) { 'queue:write_to_csv' }

    before do
      csv_q_cache.flushdb
      allow(cf_worker).to receive(:csv_cache).and_return(csv_q_cache)
    end

    it 'should push CustomersFetchWorker to queue' do
      Sidekiq::Testing.fake! do
        CustomersFetchWorker.jobs.clear
        expect(CustomersFetchWorker.jobs.size).to eq 0
        CustomersFetchWorker.perform_async(directory_path)
        expect(CustomersFetchWorker.jobs.size).to eq 1
      end
    end

    it 'should push 13 pages of 50 to csv queue cache' do
      VCR.use_cassette("customers_all_pages") do
        cf_worker.perform(directory_path)
        all_pages = csv_q_cache.lrange(csv_cache_key,0 , -1)
        expect(all_pages.count).to eq 13
        total_count = all_pages.sum{|page| JSON.parse(page).count }
        expect(total_count).to eq 648
        first_page = JSON.parse(csv_q_cache.rpop(csv_cache_key))
        expect(first_page.count).to eq 50
      end
    end

    it 'should trigger a csv write worker' do
      VCR.use_cassette("customers_all_pages") do
        Sidekiq::Testing.fake! do
          CsvWriteWorker.jobs.clear
          expect(CsvWriteWorker.jobs.size).to eq 0
          cf_worker.perform(directory_path)
          expect(CsvWriteWorker.jobs.size).to eq 1
        end
      end
    end
  end
end