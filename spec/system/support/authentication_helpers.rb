# frozen_string_literal: true

# Authentication helpers for system tests
# WebAuthn is complex to test in browser, so we use a test-only route
module AuthenticationHelpers
  # Sign in a user using the test-only route
  # This avoids needing to test WebAuthn flow in every spec
  def sign_in_as(user)
    visit test_sign_in_path(user_id: user.id)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :system
end
