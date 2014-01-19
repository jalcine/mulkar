require 'bundler'
Bundler.require(:default)

require 'rack-livereload'
require 'sinatra/json'
require 'dotenv'

Dotenv.load

class Muklar < Sinatra::Base
  # Middle-AWESOME!
  use Rack::LiveReload
  helpers Sinatra::JSON
  enable :logging

  def wanted_tags
    [
      'martinlutherking', 'martinlutherkingjr',
      'civil-rights-movement'
    ]
  end

  def filtered_tags
    [
      'ihaveadreambitch',
      'martinlutherkingjrjr', 'ihaveadreamstupid',
      'i-have-a-dream14', 'party',
      'martin-luther-king-jrs-dick', 'martinlutherkingband',
      'martinlutherkingjunior', 'martin-lutherking-love',
      'martinlutherking84', 'johnfkennedyofficial'
    ]
  end

  def has_invalid_tags?(data)
    blacklisted_tags.each do | tag |
      return false if data['tags'].include? tag
    end

    return true
  end

  def a_client
    Tumblr::Client.new consumer_key: ENV['TUMBLR_CONSUMER_KEY']
  end

  def search_magic(query, options = {})
    params = { api_key: ENV['TUMBLR_CONSUMER_KEY'], limit: 60 }
    params.merge!(options)
    a_client.get("v2/search/#{query}", params)
  end

  def pull_images_from_blogs(blogs)
    images = []
    blogs.each do | blog |
      blog_name = blog['url'].gsub /http:\/\//, ''
      blog_name = blog_name.gsub /.com\//, '.com'
      username  = blog_name.gsub /\.tumblr\.com/, ''
      next if filtered_tags.include? username

      posts = a_client.posts(blog_name, {type: :photo})
      posts['posts'].each do | post |
        next unless post.include? 'photos'
        photos = post['photos']
        photos.each do | photo |
          images << {
            id: Time.now.to_i + post['id'] + Random.rand(Time.now.to_i),
            image: photo['original_size'],
            link: post['post_url'],
            user: post['blog_name'],
            text: URI.unescape(post['caption']),
            time: post['timestamp']
          }
        end
      end
    end

    images
  end

  enable :logging
  get('/') { haml :index }

  get '/images' do
    images = []

    wanted_tags.each do | tag |
      search_results = search_magic(tag)
      blogs = search_results['blogs']
      more_images = pull_images_from_blogs(blogs)
      images.concat more_images
    end

    json images
  end
end
