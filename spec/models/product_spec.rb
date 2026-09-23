require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    subject { build(:product) }

    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'requires a name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'requires a sku' do
      subject.sku = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:sku]).to include("can't be blank")
    end

    it 'enforces uppercase SKU and uniqueness' do
      create(:product, sku: 'PROD-100')
      duplicate = build(:product, sku: 'prod-100')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sku]).to include('has already been taken')
    end

    it 'does not allow negative price' do
      subject.price_cents = -100
      expect(subject).not_to be_valid
      expect(subject.errors[:price_cents]).to include('must be greater than or equal to 0')
    end

    it 'does not allow negative stock' do
      subject.stock = -5
      expect(subject).not_to be_valid
      expect(subject.errors[:stock]).to include('must be greater than or equal to 0')
    end
  end

  describe 'scopes and helper methods' do
    it 'filters active products' do
      active_prod = create(:product, active: true)
      inactive_prod = create(:product, :inactive)

      expect(Product.active).to include(active_prod)
      expect(Product.active).not_to include(inactive_prod)
    end

    it 'filters products in stock' do
      in_stock_prod = create(:product, stock: 10)
      out_of_stock_prod = create(:product, :out_of_stock)

      expect(Product.in_stock).to include(in_stock_prod)
      expect(Product.in_stock).not_to include(out_of_stock_prod)
    end

    it 'checks stock availability with in_stock?' do
      product = create(:product, stock: 5)
      expect(product.in_stock?(3)).to be true
      expect(product.in_stock?(5)).to be true
      expect(product.in_stock?(6)).to be false
    end

    it 'converts price_cents to float decimal' do
      product = build(:product, price_cents: 2999)
      expect(product.price_in_currency).to eq(29.99)
    end
  end
end
