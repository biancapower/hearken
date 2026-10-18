require "rails_helper"

RSpec.describe "Signing in", type: :system do
  it "signs in, lands on the library and signs out" do
    user = create(:user)

    visit root_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "a long passphrase"
    click_on "Sign in"

    expect(page).to have_css("h1", text: "Library")
    # The importmap's modules ran, so the Content Security Policy let them through.
    expect(page.evaluate_script("typeof window.Turbo")).to eq("object")

    click_on "Sign out"

    expect(page).to have_css("h1", text: "Sign in")
  end
end
