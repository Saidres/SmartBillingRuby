require 'rails_helper'

RSpec.describe Orders::CreateOrderService do
  let(:customer) { create(:customer) }
  let(:product1) { create(:product, price_cents: 2000, stock: 10, active: true) }
  let(:product2) { create(:product, price_cents: 1500, stock: 5, active: true) }

  describe '#call' do
    context 'when all items have sufficient stock' do
      let(:items) do
        [
          { product_id: product1.id, quantity: 2 },
          { product_id: product2.id, quantity: 1 }
        ]
      end

      it 'creates the order and deducts inventory inside a transaction' do
        expect {
          result = described_class.call(customer_id: customer.id, items: items)
          expect(result).to be_success
        }.to change(Order, :count).by(1)
         .and change(OrderItem, :count).by(2)
         .and have_enqueued_job(GenerateInvoiceJob)

        expect(product1.reload.stock).to eq(8)
        expect(product2.reload.stock).to eq(4)

        created_order = Order.last
        expect(created_order.total_cents).to eq(5500) # (2000 * 2) + (1500 * 1)
        expect(created_order.status).to eq('paid')
      end
    end

    context 'when stock is insufficient for an item' do
      let(:items) do
        [
          { product_id: product1.id, quantity: 2 },
          { product_id: product2.id, quantity: 10 } # stock is 5
        ]
      end

      it 'fails and does not deduct stock for any product (atomic rollback)' do
        expect {
          result = described_class.call(customer_id: customer.id, items: items)
          expect(result).to be_failure
          expect(result.errors.first).to match(/Insufficient stock/)
        }.not_to change(Order, :count)

        expect(product1.reload.stock).to eq(10)
        expect(product2.reload.stock).to eq(5)
      end
    end

    context 'when product is inactive' do
      let(:inactive_product) { create(:product, active: false, stock: 10) }
      let(:items) { [ { product_id: inactive_product.id, quantity: 1 } ] }

      it 'returns a failure and rolls back' do
        result = described_class.call(customer_id: customer.id, items: items)
        expect(result).to be_failure
        expect(result.errors.first).to match(/discontinued or inactive/)
      end
    end

    context 'when customer does not exist' do
      let(:items) { [ { product_id: product1.id, quantity: 1 } ] }

      it 'returns customer not found' do
        result = described_class.call(customer_id: 999_999, items: items)
        expect(result).to be_failure
        expect(result.errors).to include('Customer not found')
      end
    end

    context 'when items list is empty' do
      it 'returns validation error' do
        result = described_class.call(customer_id: customer.id, items: [])
        expect(result).to be_failure
        expect(result.errors).to include('Order must contain at least one item')
      end
    end
  end
end
