require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe 'pricing and validations' do
    let(:product) { create(:product, price_cents: 1500) }
    let(:order) { create(:order) }

    it 'sets unit_price and subtotal automatically from product' do
      item = OrderItem.create!(
        order: order,
        product: product,
        quantity: 3
      )

      expect(item.unit_price_cents).to eq(1500)
      expect(item.subtotal_cents).to eq(4500)
    end

    it 'requires quantity to be strictly positive' do
      item = build(:order_item, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include('must be greater than 0')
    end
  end
end
