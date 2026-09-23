require "sidekiq/web"

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "heartbeat" => "pages#heartbeat", as: :heartbeat

  # The Sidekiq dashboard has no authentication, so it is development-only.
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  # Chart queue demo (/queue). The module is ChartQueue because Ruby's ::Queue
  # would shadow a Queue:: namespace.
  namespace :queue, module: :chart_queue do
    root "board#show"
    get "columns", to: "board#columns", as: :columns
    resources :charts, only: [] do
      post :claim_next, on: :collection
      member do
        post :claim
        post :complete
        post :release
      end
    end
    resource :reset, only: :create
  end

  # Review workflow demo: a coded chart through QA review (aasm + PaperTrail).
  namespace :review do
    root "charts#index"
    resource :role, only: :update
    resource :reset, only: :create
    resources :charts, only: %i[index show] do
      member do
        patch :submit
        patch :return_to_coder
        patch :approve
      end
      resources :codes, only: %i[show edit update]
    end
  end

  # Coding assistant + evals demo.
  namespace :assistant do
    root "suggestions#new"
    resources :suggestions, only: :create
    resources :eval_runs, only: %i[index create show]
    resources :prompt_versions, only: :create
    resource :reset, only: :create
  end

  # Defines the root path route ("/")
  root "pages#home"
end
