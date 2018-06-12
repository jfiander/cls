Rails.application.routes.draw do
  root 'cls#sheet'

  post '/cls', to: 'cls#sheet'

  get '/ds_guide', to: 'dip_short#guide'
end
