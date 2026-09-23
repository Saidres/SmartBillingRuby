require 'rails_helper'

RSpec.describe 'Api::V1::Health', type: :request do
  describe 'GET /api/v1/health' do
    it 'returns status 200 with healthy state' do
      get '/api/v1/health'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['status']).to eq('healthy')
      expect(json['data']['database']).to be true
    end
  end
end
