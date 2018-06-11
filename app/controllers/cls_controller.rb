class ClsController < ApplicationController
  def sheet
    return unless sheet_params.present?

    if sheet_params[:latitude].to_d > 55
      redirect_to root_path, alert: "Latitude #{sheet_params[:latitude]} is too high – must be below 55 degrees."
      return
    end

    cls = Cls.new(sheet_params)

    send_file cls.draw(JSON.parse(sheet_params[:sight])), disposition: :inline
  end

  private

  def sheet_params
    params.permit(:latitude, :longitude, :increment, :name, :squadron, :sight_number, :sight_error, :sight)
  end

  def demo_plot
    <<~JSON
      [{
        "fix": ["42 33.8", "82 47.1"]
      }, {
        "intercept": [130, 1.7, "42 33.8", "82 47.1"]
      }, {
        "track": [110, "42 33.8", "82 47.1"]
      }]
    JSON
  end
  helper_method :demo_plot
end
