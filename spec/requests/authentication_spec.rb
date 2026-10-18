require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user) }

  it "sends a visitor who is not signed in to the sign-in page" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "shows the library once signed in" do
    sign_in_as user

    expect(response).to redirect_to(root_url)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Library")
  end

  it "returns to the page first asked for after signing in" do
    get root_path(from: "bookmark")
    sign_in_as user

    expect(response).to redirect_to(root_url(from: "bookmark"))
  end

  it "refuses a wrong password" do
    sign_in_as user, password: "not the passphrase"

    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to eq("Try another email address or password.")
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "ends the session on sign-out" do
    sign_in_as user
    delete session_path

    expect(response).to redirect_to(new_session_path)
    expect(user.sessions).to be_empty
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "rate-limits repeated sign-in attempts" do
    10.times { sign_in_as user, password: "not the passphrase" }
    sign_in_as user

    expect(flash[:alert]).to eq("Try again later.")
    expect(user.sessions).to be_empty
  end

  it "has no password reset" do
    get "/passwords/new"

    expect(response).to have_http_status(:not_found)
  end

  it "only shows a signed-in user their own records, never another user's by id"
end
