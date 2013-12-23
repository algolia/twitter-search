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

    # add an extra full_name attribute: screen_name + name
    add_attribute :full_name

    # do not take `full_name`'s words order into account, `full_name` is more important than `description`
    attributesToIndex ['unordered(full_name)', :description, :followers_count]

    # list of attributes to highlight
    attributesToHighlight [:screen_name, :name, :description]

    # use followers_count OR mentions_count to sort results (last sort criteria)
    customRanking ['desc(score)']

    # perform prefix matching on all words
    queryType 'prefixAll'

    # @I_love_you
    separatorsToIndex '_'
  end

  def full_name
    "#{screen_name} #{name}"
  end

  # the custom score
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

end
```
