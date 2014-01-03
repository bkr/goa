# Goa

This Gem aids in creating a Rails Engine that has access to models in a separate database than the
hosting application.

## Installation

Add this line to your application's Gemfile:

    gem 'goa'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install goa

## Usage

* Create a Rails engine:

```sh
rails plugin new my_goa_gem --mountable
```

* Configure your database as you would a Rails application:

TODO

* Create a Rakefile in your Rails Engine's lib/tasks folder:

    lib/tasks/my_goa_gem.rake

```ruby
require 'goa'

GOA::RakeTasks.new.add_rake_tasks
```

You can now execute this in either your Rails engine or Rails application:
```ruby
bundle exec app:db:drop app:db:create app:db:schema:load app:db:migrate app:db:test:prepare
```

* Add Models to your gem as you would a Rails application, except make sure they share a common base class (and common database connection):

    app/models/my_goa_gem/base.rb

```ruby
require 'goa'

class MyGoaGem::Base < ActiveRecord::Base
  self.abstract_class = true

  # Establish connection in a base class so all models will share the connection
  establish_connection GOA::Config.database_config(MyGoaGem::Engine.root)
end
```

* Add to your test_helper.rb/spec_helper.rb to clean your database in both your Engine and Application:

Add this into both your client Engine Gem and the application that uses your Engine Gem where MyGoaGem::Base is the ActiveRecord base class for your models.

```ruby
require 'goa'
require 'goa/database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    GOA::DatabaseCleaner.truncate_database(MyGoaGem::Base)
  end

  config.before(:each) do
    GOA::DatabaseCleaner.begin_transaction(MyGoaGem::Base)
  end

  config.after(:each) do
    GOA::DatabaseCleaner.end_transaction(MyGoaGem::Base)
  end

  # ...
end
```

