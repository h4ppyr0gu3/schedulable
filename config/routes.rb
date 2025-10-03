Schedulable::Engine.routes.draw do
  namespace :v1 do
    resources :schedulables, only: [ :index, :create, :update, :destroy ]
    post :bulk_replace, to: "schedulables#bulk_replace"
  end
end
