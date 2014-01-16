class Handle < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch
  algoliasearch per_environment: true, auto_index: false, auto_remove: false do
    add_attribute :score
    add_attribute :full_name
    attributesToIndex ['unordered(full_name)', :description]
    attributesToHighlight [:screen_name, :name, :description]
    separatorsToIndex '_'
    customRanking ['desc(score)']
    tags do
      followers_count > 10000000 ? ['top'] : []
    end
  end

  def full_name
    # consider screen_name and name equal
    # the name should not match exact so we concatenate it with the screen_name
    [screen_name, "#{screen_name} #{name}"]
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

  def self.create_from_user(user)
    h = Handle.find_or_initialize_by(screen_name: user.screen_name)
    puts h.screen_name if h.new_record?
    h.name = user.name
    h.description = (user.description || "")[0..255]
    h.followers_count = user.followers_count
    h.updated_at ||= DateTime.now
    h.save
    h
  end

  def self.create_from_status(status)
    Handle.create_from_user(status.user)
    status.user_mentions.each do |mention|
      m = Handle.find_or_initialize_by(screen_name: mention.screen_name)
      m.updated_at ||= DateTime.now
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
    h.updated_at ||= DateTime.now
    h.save
    ids = [h.id]
    friends = Twitter::Client.new(consumer_key: ENV['TWITTER_CONSUMER_KEY'], consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      oauth_token: auth['credentials']['token'], oauth_token_secret: auth['credentials']['secret']).friends.all rescue []
    friends.each do |u|
      ids << Handle.create_from_user(u).id
    end
    Handle.where(id: ids).reindex!
  end

  def self.crawl_important!(min_mentions, limit = 1000)
    client = Twitter::Client.new consumer_key: ENV['TWITTER_CONSUMER_KEY'], consumer_secret: ENV['TWITTER_CONSUMER_SECRET']
    Handle.where(followers_count: 0).where('mentions_count >= ?', min_mentions).order('id DESC').limit(limit).each do |h|
      user = client.user(h.screen_name) rescue nil
      next if user.nil?
      Handle.create_from_user(user)
    end
  end

  def self.create_from_screen_name(screen_name)
    client = Twitter::Client.new consumer_key: ENV['TWITTER_CONSUMER_KEY'], consumer_secret: ENV['TWITTER_CONSUMER_SECRET']
    h = Handle.create_from_user client.user(screen_name)
    ids = [h.id]
    (client.friends(screen_name).all rescue []).each do |u|
      ids << Handle.create_from_user(u).id
    end
    Handle.where(id: ids).reindex!
  end

end
