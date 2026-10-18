require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  it "sends a same-origin policy with a per-request nonce and no unsafe-inline" do
    get new_session_path
    first = response.headers["Content-Security-Policy"]
    get new_session_path
    second = response.headers["Content-Security-Policy"]

    expect(first).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'none'")
    expect(first).to match(/script-src 'self' 'nonce-[^']+'/)
    expect(first).not_to include("unsafe-inline")
    expect(first[/nonce-[^']+/]).not_to eq(second[/nonce-[^']+/])
  end
end
