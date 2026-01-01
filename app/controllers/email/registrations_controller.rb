# frozen_string_literal: true

module Email
  class RegistrationsController < ApplicationController
    def new
      # GET request - show email registration form
    end

    def create
      email = registration_params[:email]&.strip&.downcase
      username = registration_params[:username]&.strip

      # Check if email already exists
      if User.exists?(email: email)
        @error = "This email is already registered. Try signing in instead."
        render :new, status: :unprocessable_content
        return
      end

      # Check if username already exists
      if User.exists?(username: username)
        @error = "This username is already taken. Please choose another."
        render :new, status: :unprocessable_content
        return
      end

      # Create user with email (no WebAuthn yet)
      user = User.new(email: email, username: username)

      if user.save
        # Generate and send magic link for email verification
        token = user.generate_email_login_token!
        UserMailer.magic_link_email(user, token).deliver_later

        @email_sent = true
        render :new
      else
        @error = user.errors.full_messages.join(", ")
        render :new, status: :unprocessable_content
      end
    end

    private

    def registration_params
      params.require(:registration).permit(:email, :username)
    end
  end
end
