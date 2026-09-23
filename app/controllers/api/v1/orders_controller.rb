module Api
  module V1
    class OrdersController < BaseController
      before_action :set_order, only: [ :show ]

      def index
        orders = Order.includes(:customer, :order_items, :products, :invoice)

        if params[:customer_id].present?
          orders = orders.where(customer_id: params[:customer_id])
        end

        if params[:status].present? && Order.statuses.key?(params[:status])
          orders = orders.where(status: params[:status])
        end

        render_success(orders.order(created_at: :desc).map { |order| order_payload(order) })
      end

      def show
        render_success(order_payload(@order, detailed: true))
      end

      def create
        order_params = params.require(:order).permit(:customer_id, :currency, items: [ :product_id, :quantity ])

        result = Orders::CreateOrderService.call(
          customer_id: order_params[:customer_id],
          items: order_params[:items],
          currency: order_params[:currency] || "USD"
        )

        if result.success?
          render_success(order_payload(result.data[:order], detailed: true), status: :created)
        else
          render_error(result.errors, status: :unprocessable_entity)
        end
      end

      private

      def set_order
        @order = Order.includes(:customer, :order_items, :products, :invoice).find(params[:id])
      end

      def order_payload(order, detailed: false)
        payload = {
          id: order.id,
          order_number: order.order_number,
          status: order.status,
          currency: order.currency,
          total_cents: order.total_cents,
          total_formatted: "$#{'%.2f' % order.total_in_currency}",
          customer: {
            id: order.customer.id,
            name: order.customer.name,
            email: order.customer.email
          },
          created_at: order.created_at.iso8601
        }

        if detailed
          payload[:items] = order.order_items.map do |item|
            {
              id: item.id,
              product_id: item.product_id,
              product_name: item.product.name,
              sku: item.product.sku,
              quantity: item.quantity,
              unit_price_cents: item.unit_price_cents,
              subtotal_cents: item.subtotal_cents,
              subtotal_formatted: "$#{'%.2f' % (item.subtotal_cents / 100.0)}"
            }
          end

          if order.invoice.present?
            payload[:invoice] = {
              id: order.invoice.id,
              invoice_number: order.invoice.invoice_number,
              status: order.invoice.status,
              target_currency: order.invoice.target_currency,
              exchange_rate: order.invoice.exchange_rate.to_f,
              total_target_currency_cents: order.invoice.total_target_currency_cents,
              total_target_currency_formatted: "#{order.invoice.target_currency} #{'%.2f' % order.invoice.total_in_target_currency}"
            }
          end
        end

        payload
      end
    end
  end
end
