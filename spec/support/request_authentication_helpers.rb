# frozen_string_literal: true

# Authentication helpers for request specs
# Uses the test-only sign in route to authenticate users
module RequestAuthenticationHelpers
  def sign_in_as(user)
    get test_sign_in_path(user_id: user.id)
  end
end

RSpec.configure do |config|
  config.include RequestAuthenticationHelpers, type: :request
end
