class ConvertCredentialsToBase64url < ActiveRecord::Migration[8.0]
  def up
    Credential.find_each do |credential|
      # Decode from base64 and re-encode as base64url (no padding)
      raw_bytes = Base64.strict_decode64(credential.external_id)
      credential.update_column(:external_id, Base64.urlsafe_encode64(raw_bytes, padding: false))
    rescue ArgumentError
      # Already base64url or invalid encoding, skip
      Rails.logger.info "Skipping credential #{credential.id}: already base64url or invalid"
    end
  end

  def down
    Credential.find_each do |credential|
      # Decode from base64url and re-encode as base64
      raw_bytes = Base64.urlsafe_decode64(credential.external_id)
      credential.update_column(:external_id, Base64.strict_encode64(raw_bytes))
    rescue ArgumentError
      # Already base64 or invalid encoding, skip
      Rails.logger.info "Skipping credential #{credential.id}: already base64 or invalid"
    end
  end
end
