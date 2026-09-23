require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'creation and validations' do
    let(:order) { create(:order) }

    it 'auto-generates an invoice number before creation' do
      invoice = create(:invoice, order: order, invoice_number: nil)
      expect(invoice.invoice_number).to be_present
      expect(invoice.invoice_number).to start_with('INV-')
    end

    it 'validates positive exchange rate' do
      invoice = build(:invoice, order: order, exchange_rate: -0.5)
      expect(invoice).not_to be_valid
      expect(invoice.errors[:exchange_rate]).to include('must be greater than 0')
    end

    it 'formats currency values correctly' do
      invoice = build(:invoice, total_cents: 10500, total_target_currency_cents: 9660)
      expect(invoice.total_in_currency).to eq(105.00)
      expect(invoice.total_in_target_currency).to eq(96.60)
    end
  end
end
