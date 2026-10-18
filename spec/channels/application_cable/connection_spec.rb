require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "connects with a signed session cookie and identifies the user" do
    session = create(:user).sessions.create!
    cookies.signed[:session_id] = session.id

    connect "/cable"

    expect(connection.current_user).to eq(session.user)
  end

  it "rejects a connection without a session" do
    expect { connect "/cable" }.to have_rejected_connection
  end
end
