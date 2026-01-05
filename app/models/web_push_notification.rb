class WebPushNotification < ApplicationRecord
  belongs_to :user

  def send_notification(title:, body: nil, icon: nil, badge: nil)
    message = JSON.generate({
      title: title,
      options: {
        body: body,
        icon: icon,
        badge: badge
      }.compact
    })

    ::WebPush.payload_send(
      message: message,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        private_key: Rails.application.credentials.dig(:web_push, :vapid_private_key),
        public_key: Rails.application.credentials.dig(:web_push, :vapid_public_key)
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    # Subscription expired or invalid, clean it up
    Rails.logger.info("Removing expired push subscription: #{id}")
    destroy
    nil
  end
end
