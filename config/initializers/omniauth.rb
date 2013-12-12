Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_OAUTH_KEY'], ENV['TWITTER_OAUTH_SECRET']
end
