module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [ :show ]

      def index
        products = Product.all

        if params[:active].present?
          products = ActiveRecord::Type::Boolean.new.cast(params[:active]) ? products.active : products.where(active: false)
        end

        if params[:in_stock].present? && ActiveRecord::Type::Boolean.new.cast(params[:in_stock])
          products = products.in_stock
        end

        render_success(products.order(created_at: :desc))
      end

      def show
        render_success(@product)
      end

      def create
        product = Product.new(product_params)

        if product.save
          render_success(product, status: :created)
        else
          render_error(product.errors.full_messages, status: :unprocessable_entity)
        end
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(:name, :sku, :description, :price_cents, :stock, :active)
      end
    end
  end
end
