require 'rails_helper'

RSpec.describe GenerateInvoiceJob, type: :job do
  let(:order) { create(:order, total_cents: 10000, currency: 'USD') }

  it 'creates an invoice for the order with converted total' do
    allow(ExchangeRates::FetchRateService).to receive(:call).and_return(
      ApplicationService::Result.new(success: true, data: { exchange_rate: 0.9000 })
    )

    expect {
      described_class.perform_now(order.id, 'EUR')
    }.to change(Invoice, :count).by(1)

    invoice = order.reload.invoice
    expect(invoice).to be_present
    expect(invoice.total_cents).to eq(10000)
    expect(invoice.total_target_currency_cents).to eq(9000)
    expect(invoice.exchange_rate).to eq(0.9000)
    expect(invoice.status).to eq('issued')
  end

  it 'is idempotent and does not recreate invoice if one already exists' do
    create(:invoice, order: order)

    expect {
      described_class.perform_now(order.id, 'EUR')
    }.not_to change(Invoice, :count)
  end
end
