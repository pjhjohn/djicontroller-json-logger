Rails.application.routes.draw do

  # Root
  root :to => 'episodes#index'

  # Tajectory Optimization
  get '/trajectory_optimization/:id/init' => 'trajectory_optimization#init'
  get '/trajectory_optimization/:id/continue' => 'trajectory_optimization#continue'

  # Additional Update Routes
  get '/episodes/:id/update_states' => 'episodes#update_states'
  get '/episodes/:id/update_diff_states' => 'episodes#update_diff_states'
  get '/episodes/:id/update_commands' => 'episodes#update_commands'
  post '/episodes/:id/update_simulator_log' => 'episodes#update_simulator_log'

  # Base RESTful Routes
  post '/episodes/:id' => 'episodes#update'
  resources :episodes, constraints: { id: /[0-9]+/ }

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
