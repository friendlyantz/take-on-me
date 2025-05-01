module ChallengeRewardsHelper
  def reward_status_class(status)
    case status
    when "pending"
      "badge-warning"
    when "fulfilled"
      "badge-success"
    when "canceled"
      "badge-error"
    end
  end
end
