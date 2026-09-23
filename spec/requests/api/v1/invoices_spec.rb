require 'rails_helper'

RSpec.describe 'Api::V1::Invoices', type: :request do
  describe 'GET /api/v1/invoices/:id' do
    let(:order) { create(:order) }
    let(:invoice) { create(:invoice, order: order) }

    it 'returns invoice details' do
      get "/api/v1/invoices/#{invoice.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['invoice_number']).to eq(invoice.invoice_number)
      expect(json['data']['order_number']).to eq(order.order_number)
      expect(json['data']['target_currency']).to eq('EUR')
    end

    it 'returns 404 for non-existent invoice' do
      get '/api/v1/invoices/999999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
