require 'rails_helper'

RSpec.describe 'Api::V1::Products', type: :request do
  describe 'GET /api/v1/products' do
    let!(:active_in_stock) { create(:product, name: 'Laptop', active: true, stock: 5) }
    let!(:out_of_stock) { create(:product, :out_of_stock, name: 'Mouse', active: true) }
    let!(:inactive) { create(:product, :inactive, name: 'Keyboard', stock: 10) }

    it 'returns all products by default' do
      get '/api/v1/products'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].size).to eq(3)
    end

    it 'filters active products' do
      get '/api/v1/products', params: { active: true }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json['data'].map { |p| p['name'] }
      expect(names).to include('Laptop', 'Mouse')
      expect(names).not_to include('Keyboard')
    end

    it 'filters products in stock' do
      get '/api/v1/products', params: { in_stock: true }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      names = json['data'].map { |p| p['name'] }
      expect(names).to include('Laptop', 'Keyboard')
      expect(names).not_to include('Mouse')
    end
  end

  describe 'GET /api/v1/products/:id' do
    let(:product) { create(:product) }

    it 'returns product data for valid ID' do
      get "/api/v1/products/#{product.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(product.id)
      expect(json['data']['sku']).to eq(product.sku)
    end

    it 'returns 404 when product is not found' do
      get '/api/v1/products/999999'

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
    end
  end

  describe 'POST /api/v1/products' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          product: {
            name: 'Mechanical Keyboard',
            sku: 'KB-MECH-01',
            description: 'RGB mechanical gaming keyboard',
            price_cents: 8999,
            stock: 25,
            active: true
          }
        }
      end

      it 'creates a product and returns 201' do
        expect {
          post '/api/v1/products', params: valid_params
        }.to change(Product, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('Mechanical Keyboard')
        expect(json['data']['sku']).to eq('KB-MECH-01')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          product: {
            name: '',
            price_cents: -500
          }
        }
      end

      it 'returns 422 unprocessable entity' do
        post '/api/v1/products', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end
end
