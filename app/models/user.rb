# frozen_string_literal: true

class User < ApplicationRecord
  CREDENTIAL_MIN_AMOUNT = 1

  has_many :credentials, dependent: :destroy
  has_many :challenge_story_likes, dependent: :destroy
  has_many :liked_challenge_stories, through: :challenge_story_likes, source: :challenge_story

  validates :username, presence: true, uniqueness: true

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def can_delete_credentials?
    credentials.size > CREDENTIAL_MIN_AMOUNT
  end
end
