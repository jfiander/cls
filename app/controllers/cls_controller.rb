class ClsControllerController < ApplicationController
  def sheet
    Cls.new(sheet_params)
  end

  private

  def sheet_params
    params.permit()
  end
end
