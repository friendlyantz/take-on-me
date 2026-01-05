# frozen_string_literal: true

module Email
  class SessionsController < ApplicationController
    def new
      # GET request - show the email sign-in form
    end

    def create
      email = session_params[:email]&.strip&.downcase
      username = session_params[:username]&.strip

      # Find or initialize user
      user = User.find_or_initialize_by(email: email) do |u|
        u.username = username || generate_username_from_email(email)
      end

      # Validate before proceeding
      unless user.valid?
        @error = user.errors.full_messages.join(", ")
        render :new, status: :unprocessable_content
        return
      end

      # Rate limiting
      if user.persisted? && user.email_login_recently_sent?
        @error = "An email was recently sent. Please wait before requesting another."
        render :new, status: :too_many_requests
        return
      end

      # Save new users
      user.save! if user.new_record?

      # Generate and send magic link
      token = user.generate_email_login_token!
      UserMailer.magic_link_email(user, token).deliver_later

      @email_sent = true
      @is_new_user = user.previous_changes.key?(:id)
      render :new
    end

    def verify
      token = params[:token]

      if token.blank?
        redirect_to new_webauthn_session_path, alert: "Invalid sign-in link"
        return
      end

      user = User.find_by_email_login_token(token)

      if user.nil?
        redirect_to new_webauthn_session_path, alert: "Invalid or expired sign-in link"
        return
      end

      unless user.verify_email_login_token(token)
        redirect_to new_webauthn_session_path, alert: "This sign-in link has expired"
        return
      end

      # Token is valid - sign in the user
      user.clear_email_login_token!
      user.verify_email!
      sign_in(user)

      redirect_to root_path, notice: "Signed in successfully!"
    end

    private

    def session_params
      params.require(:session).permit(:email, :username)
    end

    def generate_username_from_email(email)
      base = email.split("@").first.gsub(/[^a-z0-9]/i, "")
      username = base
      counter = 1

      while User.exists?(username: username)
        username = "#{base}#{counter}"
        counter += 1
      end

      username
    end
  end
end
