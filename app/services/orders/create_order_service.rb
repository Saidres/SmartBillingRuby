module Orders
  class CreateOrderService < ApplicationService
    def initialize(customer_id:, items:, currency: "USD")
      @customer_id = customer_id
      @items = items || []
      @currency = currency
      @errors = []
    end

    def call
      validate_inputs
      return failure(@errors) if @errors.any?

      customer = Customer.find_by(id: @customer_id)
      return failure([ "Customer not found" ]) unless customer
      return failure([ "Customer account is not active" ]) unless customer.status == "active"

      order = nil

      ActiveRecord::Base.transaction do
        order = Order.create!(
          customer: customer,
          currency: @currency,
          status: :paid,
          total_cents: 0
        )

        @items.each do |item_params|
          product = Product.lock.find_by(id: item_params[:product_id])

          if product.nil?
            @errors << "Product with ID #{item_params[:product_id]} does not exist"
            raise ActiveRecord::Rollback
          end

          unless product.active?
            @errors << "Product '#{product.name}' is currently discontinued or inactive"
            raise ActiveRecord::Rollback
          end

          quantity = item_params[:quantity].to_i
          unless product.in_stock?(quantity)
            @errors << "Insufficient stock for '#{product.name}'. Available: #{product.stock}, requested: #{quantity}"
            raise ActiveRecord::Rollback
          end

          # Deduct stock atomically
          product.update!(stock: product.stock - quantity)

          # Build and save order item
          order.order_items.create!(
            product: product,
            quantity: quantity,
            unit_price_cents: product.price_cents,
            subtotal_cents: product.price_cents * quantity
          )
        end

        # Recalculate order total
        order.recalculate_total!

        # Enqueue background invoice generation job
        GenerateInvoiceJob.perform_later(order.id)
      end

      if @errors.any?
        failure(@errors)
      else
        success(order: order)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def validate_inputs
      if @items.blank?
        @errors << "Order must contain at least one item"
        return
      end

      @items.each_with_index do |item, idx|
        if item[:product_id].blank?
          @errors << "Item at index #{idx} is missing product_id"
        end

        qty = item[:quantity].to_i
        if qty <= 0
          @errors << "Item at index #{idx} must have quantity greater than 0"
        end
      end
    end
  end
end
