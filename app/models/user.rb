# frozen_string_literal: true

class User < ApplicationRecord
  CREDENTIAL_MIN_AMOUNT = 1
  EMAIL_TOKEN_EXPIRY = 24.hours
  RATE_LIMIT_WINDOW = 15.minutes
  MAX_EMAIL_ATTEMPTS = 3

  # Associations
  has_many :credentials, dependent: :destroy
  has_many :challenge_story_likes, dependent: :destroy
  has_many :liked_challenge_stories, through: :challenge_story_likes, source: :challenge_story
  has_many :challenge_participants, dependent: :destroy
  has_many :challenge_stories, through: :challenge_participants
  has_many :web_push_notifications, dependent: :destroy

  # Validations
  validates :username, presence: true, uniqueness: true,
    length: {minimum: 3, maximum: 20},
    format: {
      with: /\A[a-zA-Z0-9_-]+\z/,
      message: "can only contain letters, numbers, underscores, and hyphens"
    }
  validates :email, presence: false, uniqueness: {allow_nil: true}, format: {with: URI::MailTo::EMAIL_REGEXP, allow_nil: true}

  # Callbacks
  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  # Public methods
  def can_delete_credentials?
    credentials.size > CREDENTIAL_MIN_AMOUNT
  end

  def latest_active_participation
    challenge_participants.active
      .joins(:challenge_story)
      .merge(ChallengeStory.active)
      .order("challenge_stories.updated_at DESC")
      .first
  end

  # Email authentication methods
  def generate_email_login_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    hashed_token = Digest::SHA256.hexdigest(raw_token)

    update!(
      email_login_token: hashed_token,
      email_login_token_expires_at: EMAIL_TOKEN_EXPIRY.from_now,
      last_email_sent_at: Time.current
    )

    raw_token
  end

  def verify_email_login_token(raw_token)
    return false if email_login_token.blank?
    return false if email_login_token_expires_at.blank?
    return false if email_login_token_expires_at < Time.current

    hashed_provided = Digest::SHA256.hexdigest(raw_token)
    hashed_provided == email_login_token
  end

  def clear_email_login_token!
    update!(email_login_token: nil, email_login_token_expires_at: nil)
  end

  def self.find_by_email_login_token(raw_token)
    hashed_token = Digest::SHA256.hexdigest(raw_token)
    find_by(email_login_token: hashed_token)
  end

  def email_login_recently_sent?
    last_email_sent_at.present? && last_email_sent_at > RATE_LIMIT_WINDOW.ago
  end

  def email_login_attempts_exceeded?
    # Count how many times email_login_token was set in the last window
    # Simple rate limit: last_email_sent_at indicates a send attempt
    email_login_recently_sent?
  end

  def email_verified?
    email_verified_at.present?
  end

  def verify_email!
    update!(email_verified_at: Time.current)
  end
end
