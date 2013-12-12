class Handle < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch
  algoliasearch per_environment: true, auto_index: false, auto_remove: false do
    add_attribute :score
    attributesToIndex [:screen_name, :name, :description]
    separatorsToIndex '_'
    customRanking ['desc(score)']
  end

  def score
    followers_count > 0 ? followers_count : mentions_count
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

end
