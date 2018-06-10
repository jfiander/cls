Rails.application.routes.draw do
  root 'cls#sheet'

  post '/cls', to: 'cls#sheet'
end
