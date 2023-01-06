require 'rails_helper'

RSpec.describe Throttler do
  context "Basic throttling functions" do
    let(:throttler_service) { Throttler.new(requests_allowed: 2, reset_in_seconds: 5) }

    before do
      allow(throttler_service).to receive(:redis_cache).and_return(MockRedis.new)
    end

    it 'should not throttle when request limit is not exceeded' do
      expect(throttler_service.throttle?).to be false
    end

    it 'should throttle when request limit is exceeded' do
      3.times { throttler_service.increment_counter }
      expect(throttler_service.throttle?).to be true
    end

    it 'should not throttle after reset time is over' do
      # travel to the time left for throttling
      Timecop.travel(Time.now + throttler_service.throttle_for_in_milliseconds.to_f/1000.00)
      expect(throttler_service.throttle?).to be false
    end
  end
end