class AddEmailAuthenticationToUsers < ActiveRecord::Migration[8.0]
  def change
    # Email field for magic link authentication
    add_column :users, :email, :string
    add_index :users, :email, unique: true, where: "email IS NOT NULL"

    # Tracks when email was verified (optional verification)
    add_column :users, :email_verified_at, :datetime

    # Magic link token (hashed) - for secure passwordless auth
    add_column :users, :email_login_token, :string
    add_column :users, :email_login_token_expires_at, :datetime

    # Track last email sent for rate limiting
    add_column :users, :last_email_sent_at, :datetime
  end
end
