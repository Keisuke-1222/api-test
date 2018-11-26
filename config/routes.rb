Rails.application.routes.draw do
  # root to: 'addresses#search'
  # resources :addresses, only: :show
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'top' => 'zaimauth#top'
  get 'callback' => 'zaimauth#callback'
  get 'login' => 'zaimauth#login'
  namespace 'money' do
    get 'index' => 'zaimauth#index'
    get 'average' => 'zaimauth#average'
    get 'payment' => 'zaimauth#payment'
    get 'category' => 'zaimauth#category'
  end
end
