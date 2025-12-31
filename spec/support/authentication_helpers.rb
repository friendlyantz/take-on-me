module AuthenticationHelpers
  def sign_in(user)
    post session_path, params: {session: {username: user.username}}, as: :json
    # For WebAuthn apps, we simulate the session directly
    # since WebAuthn flow is complex to test
  end

  def sign_in_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
