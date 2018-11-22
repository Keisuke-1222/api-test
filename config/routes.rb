Rails.application.routes.draw do
  root to: 'addresses#search'
  get 'addresses', to: 'addresses#search'
  resources :addresses, only: [:index, :show]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
