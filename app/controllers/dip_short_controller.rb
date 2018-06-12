class DipShortController < ApplicationController
  def guide
    radius = dip_short_params[:radius] ? dip_short_params[:radius].to_i : 60
    rings = dip_short_params[:rings] ? dip_short_params[:rings].to_i : 5

    send_file(DipShort.guide(radius, rings), disposition: :inline)
  end

  private

  def dip_short_params
    params.permit(:radius, :rings)
  end
end
