require 'rails_helper'

RSpec.describe ExchangeRates::FetchRateService do
  describe '#call' do
    it 'returns 1.0 if base and target currency are identical' do
      result = described_class.call(base_currency: 'USD', target_currency: 'USD')
      expect(result).to be_success
      expect(result.data[:exchange_rate]).to eq(1.0)
    end

    it 'returns rate when external API succeeds' do
      fake_response = instance_double(Faraday::Response, success?: true, body: '{"rates":{"EUR":0.9250}}')
      allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(fake_response)

      result = described_class.call(base_currency: 'USD', target_currency: 'EUR')
      expect(result).to be_success
      expect(result.data[:exchange_rate]).to eq(0.9250)
    end

    it 'falls back to cached rate when external API fails or times out' do
      allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new('Timeout'))

      result = described_class.call(base_currency: 'USD', target_currency: 'EUR')
      expect(result).to be_success
      expect(result.data[:exchange_rate]).to eq(0.92)
      expect(result.data[:note]).to match(/Fallback used/)
    end
  end
end
