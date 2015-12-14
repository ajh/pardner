

          .-~-~-\-~\
         /       ~~ \
         |           ;
     ,--------,______|---.
    /          \-----`    \ _
    `.__________`-_______-'| |_ __   ___ _ __
       | '_ \ / _` | '__/ _` | '_ \ / _ \ '__|
       | |_) | (_| | | | (_| | | | |  __/ |
       | .__/ \__,_|_|  \__,_|_| |_|\___|_|
       |_|

# pardner

A decorator library for ActiveRecord that has features to fit in nicely with the ActiveModel world

## Use cases

1. Presenters for views
2. Handle form params and translate them to what the modal understands
3. Creating or updating multiple ActiveRecord models atomically
4. Adding optional validations
5. And more!

## 1. Presenters

A presenter can be used as an alternative to a view helper to add logic
to a view. In this example we add a `description` method to a decorator
for the view:

    # app/models/conestoga_wagon.rb
    class ConestogaWagon < ActiveRecord::Base
      attr_accessor :wheels_count, :covered
    end

    # app/presenters/conestoga_wagon_presenter.rb
    class ConestogaWagonPresenter < Pardner::Base
      howdy_pardner ConestogaWagon

      def description
        covered_string = covered ? "covered" : "uncovered"
        "a #{wheels_count} wheeled #{covered_string} wagon"
      end
    end

    # app/view/conestoga_wagons/show.html.haml
    ...
    span.description= @conestoga_wagon.description
    ...

## 2. Handle form params

In this example, the `GoldRush` model has separate `city` and `state`
fields, but we want to present that to the user as a single form field.
The decorator will split the incoming `location` param into `city` and
`state` fields.

    # app/models/gold_rush.rb
    class GoldRush < ActiveRecord::Base
      attr_accessor :city, :state
    end

    # app/decorators/gold_rush_form.rb
    class GoldRushForm < Pardner::Base
      howdy_pardner GoldRush

      def location
        "#{city}, #{state}"
      end

      def location=(val)
        self.city, self.state = val.split ','
      end
    end

    # app/controllers/gold_rushes_controller.rb
    def new
      @gold_rush = GoldRushForm.new GoldRush.new
    end

    # app/view/gold_rushes/new.html.haml
    = form_for @gold_rush do |form|
      form.text :location

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pardner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pardner

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pardner. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

