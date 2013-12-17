class Handle < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch
  algoliasearch per_environment: true, auto_index: false, auto_remove: false do
    add_attribute :score
    add_attribute :full_name
    attributesToIndex ['unordered(full_name)', :followers_count]
    attributesToHighlight [:screen_name, :name]
    separatorsToIndex '_'
    customRanking ['desc(score)']
  end

  def full_name
    "#{screen_name} #{name}"
  end

  def score
    return followers_count if followers_count > 0
    if mentions_count < 10
      mentions_count
    elsif mentions_count < 100
      mentions_count * 10
    elsif mentions_count < 1000
      mentions_count * 100
    else
      mentions_count * 1000
    end
  end

  def self.create_from_status(status)
    h = Handle.find_or_initialize_by(screen_name: status.user.screen_name)
    h.name = status.user.name
    h.description = (status.user.description || "")[0..255]
    h.followers_count = status.user.followers_count
    h.save
    status.user_mentions.each do |mention|
      m = Handle.find_or_initialize_by(screen_name: mention.screen_name)
      m.name = mention.name
      m.mentions_count ||= 0
      m.mentions_count += 1
      m.save
    end
  end

  def self.create_with_omniauth(auth)
    h = Handle.find_or_initialize_by(screen_name: auth['extra']['raw_info']['screen_name'])
    h.name = auth['extra']['raw_info']['name']
    h.followers_count = auth['extra']['raw_info']['followers_count']
    h.description = (auth['extra']['raw_info']['description'] || "")[0..255]
    h.save!
    h.index!
  end

  def self.crawl_important!(min_mentions, limit = 1000)
    client = Twitter::Client.new consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      oauth_token: ENV['TWITTER_OAUTH_KEY'],
      oauth_token_secret: ENV['TWITTER_OAUTH_SECRET']
    Handle.where(followers_count: 0).where('mentions_count >= ?', min_mentions).order('id DESC').limit(limit).each do |h|
      user = client.user(h.screen_name) rescue nil
      next if user.nil?
      puts h.screen_name
      h.name = user.name
      h.followers_count = user.followers_count
      h.description = (user.description || "")[0..255]
      h.save
    end
  end

end
