class GenerateInvoiceJob < ApplicationJob
  queue_as :default

  def perform(order_id, target_currency = "EUR")
    order = Order.find_by(id: order_id)
    return unless order

    # Idempotency check: don't create multiple invoices for the same order
    return if order.invoice.present?

    rate_result = ExchangeRates::FetchRateService.call(
      base_currency: order.currency,
      target_currency: target_currency
    )

    exchange_rate = rate_result.success? ? rate_result.data[:exchange_rate] : 1.0
    total_target_cents = (order.total_cents * exchange_rate).round

    invoice = order.create_invoice!(
      currency: order.currency,
      target_currency: target_currency,
      exchange_rate: exchange_rate,
      total_cents: order.total_cents,
      total_target_currency_cents: total_target_cents,
      status: :issued,
      issued_at: Time.current
    )

    Rails.logger.info("[GenerateInvoiceJob] Created Invoice #{invoice.invoice_number} for Order #{order.order_number}")
    invoice
  end
end
