class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_one :invoice, dependent: :destroy

  enum :status, { pending: 0, paid: 1, failed: 2, cancelled: 3 }, default: :pending

  validates :order_number, presence: true, uniqueness: true
  validates :currency, presence: true
  validates :total_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_order_number, on: :create

  def recalculate_total!
    self.total_cents = order_items.sum(&:subtotal_cents)
    save!
  end

  def total_in_currency
    (total_cents / 100.0).round(2)
  end

  private

  def generate_order_number
    return if order_number.present?

    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
      break unless Order.exists?(order_number: order_number)
    end
  end
end
