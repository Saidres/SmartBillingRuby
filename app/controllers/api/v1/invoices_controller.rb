module Api
  module V1
    class InvoicesController < BaseController
      def show
        invoice = Invoice.includes(:order).find(params[:id])

        render_success({
          id: invoice.id,
          invoice_number: invoice.invoice_number,
          order_id: invoice.order_id,
          order_number: invoice.order.order_number,
          status: invoice.status,
          currency: invoice.currency,
          target_currency: invoice.target_currency,
          exchange_rate: invoice.exchange_rate.to_f,
          total_cents: invoice.total_cents,
          total_formatted: "$#{'%.2f' % invoice.total_in_currency}",
          total_target_currency_cents: invoice.total_target_currency_cents,
          total_target_currency_formatted: "#{invoice.target_currency} #{'%.2f' % invoice.total_in_target_currency}",
          issued_at: invoice.issued_at&.iso8601
        })
      end
    end
  end
end
