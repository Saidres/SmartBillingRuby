puts "== Seeding Smart Billing & Inventory Database =="

# 1. Customers
customers_data = [
  { name: "Carlos Mendoza", email: "carlos.mendoza@techcorp.com", status: "active" },
  { name: "Mariana Silva", email: "mariana.silva@innovatech.io", status: "active" },
  { name: "Alejandro Gomez", email: "alejandro.gomez@globaldev.co", status: "active" },
  { name: "Lucia Fernandez", email: "lucia.fernandez@cloudsystems.net", status: "inactive" }
]

customers = customers_data.map do |data|
  Customer.find_or_create_by!(email: data[:email]) do |customer|
    customer.name = data[:name]
    customer.status = data[:status]
  end
end
puts " Created #{customers.size} Customers"

# 2. Products
products_data = [
  { name: "MacBook Pro 16' M3", sku: "TECH-MBP-16", description: "Apple M3 Pro 36GB RAM 512GB SSD", price_cents: 249900, stock: 15, active: true },
  { name: "Dell UltraSharp 27' 4K", sku: "TECH-MON-27", description: "Monitor IPS UHD USB-C Hub", price_cents: 59900, stock: 25, active: true },
  { name: "Logitech MX Master 3S", sku: "TECH-MOU-MX3", description: "Ergonomic wireless mouse with quiet clicks", price_cents: 9999, stock: 40, active: true },
  { name: "Keychron Q1 Pro Mechanical", sku: "TECH-KB-Q1", description: "Wireless custom mechanical keyboard QMK/VIA", price_cents: 19999, stock: 30, active: true },
  { name: "Sony WH-1000XM5", sku: "TECH-HEAD-XM5", description: "Premium noise cancelling wireless headphones", price_cents: 39999, stock: 0, active: true }, # Out of stock demo
  { name: "Legacy USB Hub 2.0", sku: "TECH-HUB-LEGACY", description: "Discontinued USB hub", price_cents: 1500, stock: 5, active: false } # Inactive demo
]

products = products_data.map do |data|
  Product.find_or_create_by!(sku: data[:sku]) do |product|
    product.name = data[:name]
    product.description = data[:description]
    product.price_cents = data[:price_cents]
    product.stock = data[:stock]
    product.active = data[:active]
  end
end
puts " Created #{products.size} Products"

# 3. Demo Initial Order using CreateOrderService
demo_customer = customers.first
mbp = Product.find_by!(sku: "TECH-MBP-16")
mx3 = Product.find_by!(sku: "TECH-MOU-MX3")

if Order.none?
  result = Orders::CreateOrderService.call(
    customer_id: demo_customer.id,
    items: [
      { product_id: mbp.id, quantity: 1 },
      { product_id: mx3.id, quantity: 2 }
    ],
    currency: "USD"
  )

  if result.success?
    order = result.data[:order]
    # Perform background job synchronously for seeding
    GenerateInvoiceJob.perform_now(order.id, "EUR")
    puts " Created initial Order #{order.order_number} ($#{order.total_in_currency} USD) with Invoice #{order.invoice.invoice_number}"
  end
end

puts "== Seeding complete! Database ready =="
