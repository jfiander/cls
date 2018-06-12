class DipShortController < ApplicationController
  def guide
    radius = dip_short_params[:radius] ? dip_short_params[:radius].to_d : 60
    rings = dip_short_params[:rings] ? dip_short_params[:rings].to_i : 5
    offset = dip_short_params[:offset] ? dip_short_params[:offset].to_i : 0

    send_file(DipShort.guide(radius, rings, offset), disposition: :inline)
  end

  private

  def dip_short_params
    params.permit(:radius, :rings, :offset)
  end
end
