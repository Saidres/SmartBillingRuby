class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :order_number, null: false
      t.integer :status, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
  end
end
