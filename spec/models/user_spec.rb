require "rails_helper"

RSpec.describe User, type: :model do
  describe "#can_delete_credentials?" do
    let(:user) { create(:user) }

    it "returns false when user has only one credential" do
      create(:credential, user: user)

      expect(user.can_delete_credentials?).to be false
    end

    it "returns true when user has more than one credential" do
      create_list(:credential, 2, user: user)

      expect(user.can_delete_credentials?).to be true
    end
  end

  describe "#latest_active_participation" do
    let(:user) { create(:user) }

    it "returns nil when user has no participations" do
      expect(user.latest_active_participation).to be_nil
    end

    it "returns nil when all participations are inactive" do
      create(:challenge_participant, :inactive, user: user)

      expect(user.latest_active_participation).to be_nil
    end

    it "returns nil when all stories are completed" do
      story = create(:challenge_story, :completed)
      create(:challenge_participant, user: user, challenge_story: story)

      expect(user.latest_active_participation).to be_nil
    end

    it "returns the most recently updated active participation" do
      old_story = create(:challenge_story, updated_at: 2.days.ago)
      new_story = create(:challenge_story, updated_at: 1.day.ago)

      create(:challenge_participant, user: user, challenge_story: old_story)
      latest = create(:challenge_participant, user: user, challenge_story: new_story)

      expect(user.latest_active_participation).to eq(latest)
    end
  end

  describe "callbacks" do
    it "sets webauthn_id on initialize" do
      user = User.new

      expect(user.webauthn_id).to be_present
    end
  end

  describe "email authentication" do
    let(:user) { create(:user, email: "test@example.com") }

    describe "#generate_email_login_token!" do
      it "generates a token and sets expiry" do
        token = user.generate_email_login_token!

        expect(token).to be_present
        expect(token.length).to be > 20
        expect(user.email_login_token).to be_present
        expect(user.email_login_token_expires_at).to be_present
      end

      it "sets last_email_sent_at" do
        user.generate_email_login_token!

        expect(user.last_email_sent_at).to be_within(1.second).of(Time.current)
      end

      it "token expires in 24 hours" do
        token = user.generate_email_login_token!

        expect(user.email_login_token_expires_at).to be_within(1.second).of(24.hours.from_now)
      end
    end

    describe "#verify_email_login_token" do
      it "returns true for a valid token" do
        token = user.generate_email_login_token!

        expect(user.verify_email_login_token(token)).to be true
      end

      it "returns false for an invalid token" do
        user.generate_email_login_token!

        expect(user.verify_email_login_token("invalid-token")).to be false
      end

      it "returns false when token is expired" do
        token = user.generate_email_login_token!
        user.update!(email_login_token_expires_at: 1.hour.ago)

        expect(user.verify_email_login_token(token)).to be false
      end

      it "returns false when no token is set" do
        user.generate_email_login_token!
        token = user.email_login_token
        user.update!(email_login_token: nil)

        expect(user.verify_email_login_token(token)).to be false
      end
    end

    describe "#clear_email_login_token!" do
      it "clears token and expiry" do
        user.generate_email_login_token!
        user.clear_email_login_token!

        expect(user.email_login_token).to be_nil
        expect(user.email_login_token_expires_at).to be_nil
      end
    end

    describe "#email_login_recently_sent?" do
      it "returns true if email was sent recently" do
        user.update!(last_email_sent_at: 5.minutes.ago)

        expect(user.email_login_recently_sent?).to be true
      end

      it "returns false if no email was sent" do
        user.update!(last_email_sent_at: nil)

        expect(user.email_login_recently_sent?).to be false
      end

      it "returns false if email was sent over 15 minutes ago" do
        user.update!(last_email_sent_at: 20.minutes.ago)

        expect(user.email_login_recently_sent?).to be false
      end
    end

    describe "#email_verified?" do
      it "returns true when email_verified_at is set" do
        user.update!(email_verified_at: Time.current)

        expect(user.email_verified?).to be true
      end

      it "returns false when email_verified_at is nil" do
        expect(user.email_verified?).to be false
      end
    end

    describe "#verify_email!" do
      it "sets email_verified_at" do
        user.verify_email!

        expect(user.email_verified_at).to be_present
        expect(user.email_verified_at).to be_within(1.second).of(Time.current)
      end
    end

    describe ".find_by_email_login_token" do
      it "finds user by valid token" do
        token = user.generate_email_login_token!

        found_user = User.find_by_email_login_token(token)

        expect(found_user).to eq(user)
      end

      it "returns nil for invalid token" do
        found_user = User.find_by_email_login_token("invalid-token")

        expect(found_user).to be_nil
      end
    end
  end
end
