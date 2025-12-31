# frozen_string_literal: true

class User < ApplicationRecord
  CREDENTIAL_MIN_AMOUNT = 1

  # Associations
  has_many :credentials, dependent: :destroy
  has_many :challenge_story_likes, dependent: :destroy, counter_cache: true
  has_many :liked_challenge_stories, through: :challenge_story_likes, source: :challenge_story
  has_many :challenge_participants, dependent: :destroy, counter_cache: true
  has_many :challenge_stories, through: :challenge_participants

  # Validations
  validates :username, presence: true, uniqueness: true

  # Callbacks
  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  # Public methods
  def can_delete_credentials?
    credentials.size > CREDENTIAL_MIN_AMOUNT
  end
end
