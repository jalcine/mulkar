guard :bundler do
  watch('Gemfile')
end

guard :coffeescript, input: 'src/coffee', output: 'public/assets' do
  watch(%r{^src/coffee/*.coffee$})
end

guard :compass, configuration_file: 'compass.rb' do
  watch('compass.rb')
  watch(%r{^src/sass/*.sass$})
end

guard :livereload do
  watch(%r{^public/*})
  watch(%r{^views/*})
end

guard 'shotgun' do
  watch('mlk.rb')
  watch('config.ru')
  watch('Gemfile.lock')
end
