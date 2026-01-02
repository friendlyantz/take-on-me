# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "noreply@strivo.me")

  def magic_link_email(user, token)
    @user = user
    @token = token
    @magic_link_url = verify_email_session_url(token: token)

    mail(to: user.email, subject: "Your Strivo Sign In Link")
  end
end
