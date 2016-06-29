# Rails Application Template
#
# 2015/07/05
#
# FunnyQ

# 支援此 application template 相對位置的檔案操作
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

# clean file
run 'rm README.rdoc'

# 加入安裝需要的 GEMS

# 移除舊版 sass-rails，改用 5.0.1，因為需要使用 susy2 and compass
gsub_file 'Gemfile', /.+'sass-rails'.+\n/, ''

# for test and development ENV
gem_group :development, :test do
  # RSpec
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'spring-commands-rspec'

  # Time Mock
  gem 'timecop'

  # mock data for 3rd party API
  gem 'vcr'
  gem 'webmock'

  # Capybara 整合測試
  gem 'capybara'
  gem 'capybara-screenshot'

  # 使用 Guard 將開發流程的雜事自動化
  gem 'guard-livereload'
  gem 'guard-rspec', require: false
  gem 'guard-pow'
  gem 'terminal-notifier-guard'

  # 在 model 檔案中註釋 schema
  gem 'annotate'

  # 增強錯誤畫面
  gem 'better_errors'

  # 支援 chrome 的 rails panel
  gem 'meta_request'

  # 移除 log 中不必要的部份
  gem 'quiet_assets'

  # 取代 fixture 來製作假資料
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'faker'

  # Linter
  gem 'rubocop'

  # 偵測 N+1 問題
  gem 'bullet'

  # Deploy 工具
  gem 'capistrano', '~> 3.4.0'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1.1'
  gem 'capistrano-rbenv', github: 'capistrano/rbenv'
  gem 'slackistrano'
end

# mysql adapter
gem 'mysql2'

# 使用者系統
gem 'devise'

# API 開發工具組
if yes?("是否進行開發 API？ (yes/no)")

  # API 開發工具
  gem 'grape'
  gem 'grape-entity'
  gem 'grape-swagger-rails'

  # 跨站請求
  gem 'rack-cors', require: 'rack/cors'

end

# 前端相關
gem 'sprockets-rails'
gem 'sass-rails'
gem 'font-awesome-sass'
gem 'sassc-rails'
gem 'bourbon'
gem 'neat'
gem 'bootstrap-sass' if yes?('是否安裝 bootstrap-sass gem？（yes/no）')

gem 'bower-rails'
gem 'modernizr-rails'

if yes?('是否使用 React.js？（yes/no）')
  gem 'react-rails', '~> 1.0'
  gem 'sprockets-coffee-react'
end

# Debug 工具
gem 'awesome_rails_console'

# notifications
gem 'growlyflash'
gem 'rails-assets-sweetalert', source: 'https://rails-assets.org'
gem 'sweet-alert-confirm'

# App settings function
gem 'rails-settings-cached', '0.4.1'
gem 'settingslogic'

# for View components and cache
gem 'cells'
gem 'cells-erb'

# 檔案上傳與影像處理
gem 'carrierwave'
gem 'mini_magick'

# SEO
gem 'meta-tags'

# 權限管理
gem 'pundit'

if yes?("是否使用 Facebook oauth 登入 (yes/no)")
  gem 'omniauth'
  gem 'omniauth-facebook'
  gem 'koala', '~> 2.2'
end

# 設定動作
#===============================================================================

after_bundle do
  application  do
    %q{
      # Set bower components path and precompile type
      config.assets.paths << Rails.root.join("vendor","assets","bower_components")
      config.assets.precompile += %w(.svg .eot .woff .ttf .woff2 .otf)

      # Set timezone
      config.time_zone = 'Taipei'
      config.active_record.default_timezone = :local

      # Set locale
      config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
      config.i18n.default_locale = "zh-TW"
      config.i18n.available_locales = [:"zh-TW", :en]

      # Set generator
      config.generators do |g|
        g.orm :active_record
        g.view_specs false
        g.routing_specs false
        g.helper_specs false
        g.request_specs false
        g.assets false
        g.helper false
      end
    }
  end

  # 透過 Bower 安裝前端 lib
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/Bowerfile', 'Bowerfile'

  run 'bundle exec rake bower:install'

  # 安裝 Rspec
  generate 'rspec:install'

  insert_into_file 'spec/rails_helper.rb', %(
  config.before(:suite) do
    DatabaseCleaner.clean_with(:deletion)
  end
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :deletion
  end
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/vcr'
    c.hook_into :webmock
    c.allow_http_connections_when_no_cassette = true
  end
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      # Choose a test framework:
      with.test_framework :rspec

      # Or, choose the following (which implies all of the above):
      with.library :rails
    end
  end

  Capybara.javascript_driver = :webkit

  ), after: 'RSpec.configure do |config|'

  insert_into_file 'spec/rails_helper.rb', %(
    require 'capybara/rails'
    Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
  ), after: "require 'rspec/rails'"

  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/spec/support/api_helpers.rb', 'spec/support/api_helpers.rb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/spec/support/factory_girl.rb', 'spec/support/factory_girl.rb'

  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/.rubocop.yml', '.rubocop.yml'

  run 'bundle exec guard init'

  # 移除 test folder
  run 'rm -rf test'

  # 使用建議的 ignore 設定
  remove_file '.gitignore'
  file '.gitignore', <<-CODE
################################################################################
## 參考 https://github.com/github/gitignore/blob/master/Rails.gitignore       ##
################################################################################

*.rbc
capybara-*.html
.rspec
/log
/tmp
/db/*.sqlite3
/public/system
/public/uploads
/public/assets/ckeditor
/coverage/
/spec/tmp
**.orig
rerun.txt
pickle-email-*.html

# TODO Comment out these rules if you are OK with secrets being uploaded to the repo
/config/initializers/secret_token.rb
/config/secrets.yml
/config/application.yml
/config/database.yml
/shared/

## Environment normalisation:
/.bundle
/vendor/bundle

# these should all be checked in to normalise the environment:
# Gemfile.lock, .ruby-version, .ruby-gemset

# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:
.rvmrc

# if using bower-rails ignore default bower_components path bower.json files
/vendor/assets/bower_components
*.bowerrc
bower.json

################################################################################
## 參考 https://github.com/github/gitignore/blob/master/Ruby.gitignore        ##
################################################################################


*.gem
*.rbc
/.config
/coverage/
/InstalledFiles
/pkg/
/spec/reports/
/test/tmp/
/test/version_tmp/
/tmp/

## Specific to RubyMotion:
.dat*
.repl_history
build/

## Documentation cache and generated files:
/.yardoc/
/_yardoc/
/doc/
/rdoc/
  CODE

  # 建立資料庫
  run 'bundle exec rake db:create'
  run 'bundle exec rake db:migrate'

  # 建立 prototype controller for prototyping
  route "root 'prototype#index'"

  file 'app/controllers/prototype_controller.rb', <<-CODE
class PrototypeController < ApplicationController

  def index
  end

end
  CODE

  # 前端基本環境建立
  #===============================================================================

  # Javascript
  remove_file 'app/assets/javascripts/application.js'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/application.js.coffee', 'app/assets/javascripts/application.js.coffee'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/_plugins.js.coffee', 'app/assets/javascripts/_plugins.js.coffee'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/_app-base.js.coffee', 'app/assets/javascripts/_app-base.js.coffee'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/_flash-style.js.coffee', 'app/assets/javascripts/_flash-style.js.coffee'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/vendor/_console_err.js', 'app/assets/javascripts/vendor/_console_err.js'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/javascripts/classes/.js_objects', 'app/assets/javascripts/classes/.js_objects'

  # Sass
  remove_file 'app/assets/stylesheets/application.css'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/application.css.sass', 'app/assets/stylesheets/application.css.sass'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/pages/_index.css.sass', 'app/assets/stylesheets/pages/_index.css.sass'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_base.scss', 'app/assets/stylesheets/base/_base.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_buttons.scss', 'app/assets/stylesheets/base/_buttons.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_forms.scss', 'app/assets/stylesheets/base/_forms.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_grid-settings.scss', 'app/assets/stylesheets/base/_grid-settings.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_helpers.sass', 'app/assets/stylesheets/base/_helpers.sass'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_layout.sass', 'app/assets/stylesheets/base/_layout.sass'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_lists.scss', 'app/assets/stylesheets/base/_lists.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_mixins.sass', 'app/assets/stylesheets/base/_mixins.sass'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_tables.scss', 'app/assets/stylesheets/base/_tables.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_typography.scss', 'app/assets/stylesheets/base/_typography.scss'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/assets/stylesheets/base/_variables.scss', 'app/assets/stylesheets/base/_variables.scss'

  # Helper
  remove_file 'app/helpers/application_helper.rb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/helpers/application_helper.rb', 'app/helpers/application_helper.rb'

  # View
  remove_file 'app/views/layouts/application.html.erb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/views/layouts/application.html.erb', 'app/views/layouts/application.html.erb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/views/common/_header.html.erb', 'app/views/common/_header.html.erb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/views/common/_footer.html.erb', 'app/views/common/_footer.html.erb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/views/prototype/index.html.erb', 'app/views/prototype/index.html.erb'

  # 其他設定
  #===============================================================================

  # SittingsLogic
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/app/models/settings.rb', 'app/models/settings.rb'

  # i18n
  get 'https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/zh-TW.yml', 'config/locales/zh-TW.yml'
  get 'https://raw.githubusercontent.com/tigrish/devise-i18n/master/rails/locales/zh-TW.yml', 'config/locales/devise_i18n.yml'

  # adding staging env"
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/config/environments/staging.rb', 'config/environments/staging.rb'

  # setting up Bullet
  insert_into_file 'config/environments/development.rb', after: '# config.action_view.raise_on_missing_translations = true' do
    "
      config.after_initialize do
        Bullet.enable = true
        Bullet.console = true
      end
    "
  end

  # capistrano
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/Capfile', 'Capfile'

  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/config/deploy.rb', 'config/deploy.rb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/config/deploy/production.rb', 'config/deploy/production.rb'
  get 'https://raw.githubusercontent.com/oracle-design/Q-Rails-Application-Template/master/config/deploy/staging.rb', 'config/deploy/staging.rb'

  file 'shared/config/application.yml', <<-CODE
# config/application.yml
defaults: &defaults
  mysql:
    database:
    password:
    username:
  secret_key: '4190de7294576817164261152b2a5d36d61ec6be54d336e514e15f662618df30bf3c33502853aa8c1321263bc4a90702c0205e110ee1f61f177cbfde9ae36a05'

development:
  <<: *defaults

test:
  <<: *defaults

staging:
  <<: *defaults
  secret_key: '' # `rake secret` to generate one

production:
  <<: *defaults
  secret_key: '' # `rake secret` to generate one
  CODE

  run 'ln shared/config/application.yml config/application.yml'

  file 'shared/config/database.yml', <<-CODE
default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

  # adapter: mysql2
  # encoding: utf8
  # database: <%= Settings.mysql.database %>
  # username: <%= Settings.mysql.username %>
  # password: <%= Settings.mysql.password %>
  # host: 127.0.0.1
  # port: 3306

development:
  <<: *default
  database: db/development.sqlite3


# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: db/test.sqlite3

staging:
  <<: *default
  database: db/staging.sqlite3

production:
  <<: *default
  database: db/production.sqlite3
  CODE

  run 'rm config/database.yml'
  run 'ln shared/config/database.yml config/database.yml'

  file 'shared/config/secrets.yml', <<-CODE
development:
  secret_key_base: <%= Settings.secret_key %>

test:
  secret_key_base: <%= Settings.secret_key %>

staging:
  secret_key_base: <%= Settings.secret_key %>

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  secret_key_base: <%= Settings.secret_key %>
  CODE
  run 'rm config/secrets.yml'
  run 'ln shared/config/secrets.yml config/secrets.yml'

  # 詢問是否安裝 Devise
  if yes?("要不要順便幫你安裝 Devise？(yes/no)")
    generate 'devise:install'
    model_name = ask("你的使用者 model 名稱要設定為？ [預設為 user]")
    model_name = 'user' if model_name.blank?
    generate 'devise', model_name
  end
end

# git 初始化
#===============================================================================
after_bundle do
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end
