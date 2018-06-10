class ClsController < ApplicationController
  def sheet
    return unless sheet_params.present?

    send_file Cls.new(sheet_params).draw, disposition: :inline
  end

  private

  def sheet_params
    params.permit(:latitude)
  end
end
