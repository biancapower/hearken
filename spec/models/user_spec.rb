require "rails_helper"

RSpec.describe User, type: :model do
  it "stores the email address stripped and lowercased" do
    user = create(:user, email_address: "  Listener@Example.COM ")

    expect(user.email_address).to eq("listener@example.com")
  end

  it "authenticates with the right password and not with a wrong one" do
    user = create(:user, email_address: "listener@example.com", password: "a long passphrase")

    expect(User.authenticate_by(email_address: "Listener@example.com", password: "a long passphrase")).to eq(user)
    expect(User.authenticate_by(email_address: "listener@example.com", password: "wrong")).to be_nil
  end

  it "needs an email address that looks like one" do
    expect(build(:user, email_address: "")).not_to be_valid
    expect(build(:user, email_address: "not an address")).not_to be_valid
  end

  it "needs a password of at least 12 characters" do
    expect(build(:user, password: "x" * 11)).not_to be_valid
    expect(build(:user, password: "x" * 12)).to be_valid
  end

  it "refuses a second account with the same email address" do
    create(:user, email_address: "listener@example.com")

    expect { create(:user, email_address: "LISTENER@example.com") }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
