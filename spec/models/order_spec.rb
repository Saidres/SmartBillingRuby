require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations and callbacks' do
    let(:customer) { create(:customer) }

    it 'auto-generates an order number before creation' do
      order = create(:order, customer: customer, order_number: nil)
      expect(order.order_number).to be_present
      expect(order.order_number).to start_with('ORD-')
    end

    it 'defaults status to pending' do
      order = create(:order, customer: customer)
      expect(order.status).to eq('pending')
      expect(order).to be_pending
    end

    it 'does not allow negative total_cents' do
      order = build(:order, customer: customer, total_cents: -50)
      expect(order).not_to be_valid
      expect(order.errors[:total_cents]).to include('must be greater than or equal to 0')
    end
  end

  describe 'recalculate_total!' do
    let(:order) { create(:order) }
    let(:prod1) { create(:product, price_cents: 1000) }
    let(:prod2) { create(:product, price_cents: 2500) }

    it 'calculates sum of order items' do
      create(:order_item, order: order, product: prod1, quantity: 2, unit_price_cents: 1000, subtotal_cents: 2000)
      create(:order_item, order: order, product: prod2, quantity: 1, unit_price_cents: 2500, subtotal_cents: 2500)

      order.recalculate_total!
      expect(order.reload.total_cents).to eq(4500)
      expect(order.total_in_currency).to eq(45.00)
    end
  end
end
