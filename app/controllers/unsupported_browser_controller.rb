class UnsupportedBrowserController < ApplicationController
  def index
    @unsupported_url = params[:url] || request.referer || root_url

    if likely_webview?
      @webview_again = true
    elsif params[:url].present?
      redirect_to @unsupported_url
    end
  end
end
