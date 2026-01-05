class WebPushNotificationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    return head :unauthorized unless current_user

    subscription = JSON.parse(request.body.read)

    notification = current_user.web_push_notifications.find_or_create_by(
      endpoint: subscription["endpoint"]
    ) do |n|
      n.auth_key = subscription.dig("keys", "auth")
      n.p256dh_key = subscription.dig("keys", "p256dh")
      n.device_name = detect_device_name
      n.user_agent = request.user_agent
    end

    render json: {success: true, id: notification.id}, status: :created
  end

  def unsubscribe
    return head :unauthorized unless current_user

    # Find subscription by endpoint from request body
    subscription = JSON.parse(request.body.read)
    endpoint = subscription["endpoint"]

    notification = current_user.web_push_notifications.find_by(endpoint: endpoint)
    notification&.destroy

    head :ok
  end

  private

  def detect_device_name
    ua = request.user_agent.to_s.downcase

    # Mobile devices first
    return "iPhone" if ua.include?("iphone")
    return "iPad" if ua.include?("ipad")
    return "Android Phone" if ua.include?("android") && ua.include?("mobile")
    return "Android Tablet" if ua.include?("android")

    # Desktop browsers (order matters - check specific before generic)
    return "Chrome Desktop" if ua.include?("chrome")
    return "Brave Desktop" if ua.include?("brave")
    return "Firefox Desktop" if ua.include?("firefox")
    return "Safari Desktop" if ua.include?("safari") && !ua.include?("chrome")
    return "Edge Desktop" if ua.include?("edg")
    return "Arc Desktop" if ua.include?("arc")
    return "Opera Desktop" if ua.include?("opr") || ua.include?("opera")
    return "Vivaldi Desktop" if ua.include?("vivaldi")
    return "Tor Browser" if ua.include?("tor")

    "Unknown Device"
  end
end
