class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.string :invoice_number, null: false
      t.string :currency, null: false, default: "USD"
      t.string :target_currency, null: false, default: "EUR"
      t.decimal :exchange_rate, precision: 10, scale: 4, null: false, default: 1.0000
      t.integer :total_cents, null: false, default: 0
      t.integer :total_target_currency_cents, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :issued_at

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
  end
end
