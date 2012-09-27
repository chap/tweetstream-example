require 'rubygems'
require 'bundler/setup'
require 'tweetstream'
require 'httparty'

# need to stop pidfile creation on heroku (read only file-system)
# class TweetStream::Daemon
#   def start(path, query_parameters = {}, &block) #:nodoc:
#     # Because of a change in Ruvy 1.8.7 patchlevel 249, you cannot call anymore
#     # super inside a block. So I assign to a variable the base class method before
#     # the Daemons block begins.
#     startmethod = super.start
#     Daemons.run_proc(@app_name || 'tweetstream', :multiple => true, :no_pidfiles => true) do
#       startmethod(path, query_parameters, &block)
#     end
#   end
# end

TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
  config.auth_method        = :oauth
end

@client = TweetStream::Client.new

puts @client.inspect

# @client.on_delete do |status_id, user_id|
#   # Tweet.delete(status_id)
# end

# @client.on_limit do |skip_count|
#   # do something
# end

# @client.on_enhance_your_calm do
#   # do something
# end

terms = ENV['TRACK_TERMS'].split(',')

puts "Starting tracking #{terms.inspect}"

@client.track(terms) do |status|
  puts "-"

  if status.retweeted_status.nil?
    puts "[NEW TWEET]"
    puts status.inspect

    options = {:body => status.attrs}
    options = options.merge({:basic_auth => {:username => ENV['BASIC_AUTH_USERNAME'], :password => ENV['BASIC_AUTH_PASSWORD']}})
    response = HTTParty.post(ENV['POST_URL'], options)
  else
    puts "[RE TWEET] (not broadcasting)"
    puts status.inspect
  end
  
  puts ''
end

# The third argument is an optional process name
# TweetStream::Daemon.new('track', {:no_pidfiles => true}).track('bieber') do |status|
#   puts status.inspect
#   # puts status.text
#   # do something in the background
# end
