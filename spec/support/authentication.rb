module AuthenticationHelpers
  def sign_in_as(user, password: "a long passphrase")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request

  config.before do
    ActionController::Base.cache_store.clear
  end
end
