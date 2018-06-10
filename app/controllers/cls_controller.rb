class ClsController < ApplicationController
  def sheet
    return unless sheet_params.present?

    Cls.new(sheet_params).draw
  end

  private

  def sheet_params
    params.permit(:latitude)
  end
end
