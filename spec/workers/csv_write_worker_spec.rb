require 'rails_helper'
require 'sidekiq/testing'
require 'csv'

RSpec.describe CsvWriteWorker do
  context "test basic functions of worker" do
    let(:directory_path) { Dir.mktmpdir }
    let(:csv_q_cache) { MockRedis.new }
    let(:cw_worker) { CsvWriteWorker.new }
    let(:csv_cache_key) { 'queue:write_to_csv' }
    let(:dummy_filename) { random_string + '.csv' }

    before do
      csv_q_cache.flushdb
      allow(cw_worker).to receive(:csv_cache).and_return(csv_q_cache)
      allow(cw_worker).to receive(:generate_filename).and_return(dummy_filename)
    end

    it 'should push CsvWriteWorker to queue' do
      Sidekiq::Testing.fake! do
        CsvWriteWorker.jobs.clear
        expect(CsvWriteWorker.jobs.size).to eq 0
        CsvWriteWorker.perform_async(directory_path)
        expect(CsvWriteWorker.jobs.size).to eq 1
      end
    end

    it 'should pop all elements from csv queue cache' do
      csv_q_cache.lpush(csv_cache_key, JSON.dump([{name: 'aasdf'}]))
      cw_worker.perform(directory_path)
      expect(csv_q_cache.rpop(csv_cache_key)).to be_nil
    end

    it 'should write headers and other contents to csv file' do
      csv_q_cache.lpush(csv_cache_key, JSON.dump([{name: 'stripe'}]))
      cw_worker.perform(directory_path)
      contents = CSV.open(directory_path + "/#{dummy_filename}" ).each.to_a
      expect(contents[0]).to match_array(%w[id name email phone address account_balance currency])
      expect(contents[1]).to match_array(['stripe'])
    end
  end

  def random_string
    SecureRandom.alphanumeric(20)
  end
end
