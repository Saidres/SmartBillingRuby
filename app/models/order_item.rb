class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :subtotal_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_pricing, on: :create

  private

  def set_pricing
    if product
      self.unit_price_cents ||= product.price_cents
      self.subtotal_cents ||= unit_price_cents * (quantity || 1)
    end
  end
end
