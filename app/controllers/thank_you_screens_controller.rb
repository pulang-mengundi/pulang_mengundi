class ThankYouScreensController < ApplicationController
  def show
    @request = Request.find(params[:request_id])
  end
end