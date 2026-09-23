class Invoice < ApplicationRecord
  belongs_to :order

  enum :status, { draft: 0, issued: 1, paid: 2 }, default: :draft

  validates :invoice_number, presence: true, uniqueness: true
  validates :currency, presence: true
  validates :target_currency, presence: true
  validates :exchange_rate, presence: true, numericality: { greater_than: 0 }
  validates :total_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_target_currency_cents,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_invoice_number, on: :create

  def total_in_currency
    (total_cents / 100.0).round(2)
  end

  def total_in_target_currency
    (total_target_currency_cents / 100.0).round(2)
  end

  private

  def generate_invoice_number
    return if invoice_number.present?

    loop do
      self.invoice_number = "INV-#{Time.current.strftime('%Y%m')}-#{SecureRandom.hex(3).upcase}"
      break unless Invoice.exists?(invoice_number: invoice_number)
    end
  end
end
