require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'validations' do
    subject { build(:customer) }

    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'requires a name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'requires an email' do
      subject.email = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("can't be blank")
    end

    it 'validates format of email' do
      subject.email = 'invalid-email-address'
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("is invalid")
    end

    it 'enforces case-insensitive email uniqueness' do
      create(:customer, email: 'john.doe@example.com')
      duplicate = build(:customer, email: 'JOHN.DOE@example.com')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'restricts deletion if it has associated orders' do
      customer = create(:customer)
      create(:order, customer: customer)

      expect { customer.destroy }.not_to change(Customer, :count)
      expect(customer.errors[:base]).to be_present
    end
  end
end
