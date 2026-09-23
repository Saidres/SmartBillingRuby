class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items

  validates :name, presence: true, length: { maximum: 150 }
  validates :sku,
            presence: true,
            length: { maximum: 50 },
            uniqueness: { case_sensitive: false }
  validates :price_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock > 0") }

  before_save { sku.upcase! }

  def in_stock?(quantity = 1)
    stock >= quantity
  end

  def price_in_currency
    (price_cents / 100.0).round(2)
  end
end
