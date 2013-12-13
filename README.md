Twitter Search powered by Algolia
==================

This is the Rails 4 application providing [Twitter Search](http://twittersearch.algolia.io). It's based on [algoliasearch-rails](https://github.com/algolia/algoliasearch-rails) and uses [Twitter's Streaming API](https://dev.twitter.com/docs/streaming-apis) to crawl new users.

Configuration
--------------

```ruby
class Handle < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true do
    # add an extra score attribute
    add_attribute :score

    # `screen_name` is more important than `name`, `name` more than `description`
    attributesToIndex [:screen_name, :name, :description]

    # use followers_count OR mentions_count to sort results (last sort criteria)
    customRanking ['desc(score)']

    # perform prefix matching on all words
    queryType 'prefixAll'

    # @I_love_you
    separatorsToIndex '_'
  end

  # the custom score
  def score
    followers_count > 0 ? followers_count : mentions_count
  end

end
```
