require 'rails_helper'

RSpec.describe 'Api::V1::Orders', type: :request do
  let(:customer) { create(:customer) }
  let(:product1) { create(:product, price_cents: 2500, stock: 10) }
  let(:product2) { create(:product, price_cents: 1000, stock: 8) }

  describe 'GET /api/v1/orders' do
    let!(:order1) { create(:order, customer: customer) }
    let!(:other_customer) { create(:customer) }
    let!(:order2) { create(:order, customer: other_customer) }

    it 'lists all orders' do
      get '/api/v1/orders'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].size).to eq(2)
    end

    it 'filters orders by customer_id' do
      get '/api/v1/orders', params: { customer_id: customer.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].size).to eq(1)
      expect(json['data'].first['id']).to eq(order1.id)
    end
  end

  describe 'GET /api/v1/orders/:id' do
    let(:order) { create(:order, customer: customer) }
    let!(:item) { create(:order_item, order: order, product: product1, quantity: 2) }

    it 'returns order details with nested items' do
      get "/api/v1/orders/#{order.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['order_number']).to eq(order.order_number)
      expect(json['data']['items'].size).to eq(1)
      expect(json['data']['items'].first['product_name']).to eq(product1.name)
    end

    it 'returns 404 for unknown order' do
      get '/api/v1/orders/888888'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/orders' do
    context 'with valid items and stock' do
      let(:payload) do
        {
          order: {
            customer_id: customer.id,
            currency: 'USD',
            items: [
              { product_id: product1.id, quantity: 2 },
              { product_id: product2.id, quantity: 1 }
            ]
          }
        }
      end

      it 'creates order, deducts stock and enqueues invoice job' do
        expect {
          post '/api/v1/orders', params: payload
        }.to change(Order, :count).by(1)
         .and have_enqueued_job(GenerateInvoiceJob)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['status']).to eq('paid')
        expect(json['data']['total_cents']).to eq(6000) # (2500*2) + (1000*1)
        expect(json['data']['items'].size).to eq(2)
      end
    end

    context 'when stock is insufficient' do
      let(:payload) do
        {
          order: {
            customer_id: customer.id,
            currency: 'USD',
            items: [
              { product_id: product1.id, quantity: 99 } # stock is only 10
            ]
          }
        }
      end

      it 'returns 422 unprocessable entity with specific error' do
        post '/api/v1/orders', params: payload

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors'].first).to match(/Insufficient stock/)
      end
    end

    context 'with missing order parameter' do
      it 'returns 400 bad request' do
        post '/api/v1/orders', params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
