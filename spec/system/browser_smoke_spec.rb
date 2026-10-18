require "rails_helper"

RSpec.describe "System spec browser", type: :system do
  it "loads a page from the app in headless Chromium" do
    visit rails_health_check_path

    expect(page).to have_css("body")
  end
end
