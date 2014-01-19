require 'bundler'
Bundler.require(:default)

require 'sinatra/json'
require 'dotenv'

Dotenv.load

class Muklar < Sinatra::Base
  # Middle-AWESOME!
  use Rack::LiveReload
  helpers Sinatra::JSON

  def parse_images_from_tumblr(data)
    results = []
    data.each do | datum |
      results << {
        id: datum['id'],
        image: datum['photos'][0]['original_size'],
        link: datum['link_url'],
        user: datum['blog_name'],
        text: datum['caption'],
        time: datum['timestamp']
      } if datum.include? 'photos'
    end
    puts ap(results)
    results
  end

  enable :logging
  get('/') { haml :index }

  get '/images' do
    tumblient = Tumblr::Client.new consumer_key: ENV['TUMBLR_CONSUMER_KEY']
    data = tumblient.tagged('martinlutherking')
    images = parse_images_from_tumblr(data)
    json images
  end
end
