Twitterhandlesearch::Application.routes.draw do
  get '/auth/:provider/callback' => 'sessions#create'
  root "welcome#index"
end
