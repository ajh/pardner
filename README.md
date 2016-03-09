

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

A decorator library for ActiveRecord that has features to fit in nicely
with the ActiveModel world

## Use cases

1. Presenters for views
2. Translate between form params and model attributes
3. Save multiple ActiveRecord models atomically
4. Adding optional validations
5. And more!

## Usage

``` ruby
# Decorate an ActiveRecord or ActiveModel class by creating a subclass
# of Pardner::Base. In this example we'll pretend a User active record
# class exists.

class SilverMiner < Pardner::Base
  howdy_pardner User
end

# Instantiate it by calling `.new` and passing in a User object:
miner = SilverMiner.new User.find(123)
miner.new_record? # => true
miner.id          # => 123

# Behavior can be added to the decorator by defining methods:
class SilverMiner < Pardner::Base
  # Add the title 'Silver miner' to the user name
  def name
    "Silver miner #{super}"
  end
end

miner.name # => 'Silver miner Sam'

# by adding callbacks:
class SilverMiner < Pardner::Base
  before_destroy :retirement_party

  private

  def retirement_party
    years_worked = Time.now.year - self.start_year
    Cake.create! candles_count: years_worked
  end
end

miner.destroy # creates a Cake

# by adding validations:
class SilverMiner < Pardner::Base
  validates_inclusion_of :favorite_ore, in: ['silver']
end

miner.favorite_ore = 'gold'
miner.valid?     # => false
```

## More examples

### Presenters

A presenter a way to add logic to a view. It's an alternative to a view
helper. In this example a ConestogaWagon model is decorated to have a
`description` method.

```ruby
# app/models/conestoga_wagon.rb
# The table has columns is_covered:boolean and wheels_count:integer
class ConestogaWagon < ActiveRecord::Base
end

# app/presenters/conestoga_wagon_presenter.rb
class ConestogaWagonPresenter < Pardner::Base
  howdy_pardner ConestogaWagon

  def description
    covered_string = is_covered ? "covered" : "uncovered"
    "a #{wheels_count} wheeled #{covered_string} wagon"
  end
end

# app/controllers/conestoga_wagons_controller.rb
class ConestogaWagonsController < ApplicationController
  def show
    @wagon = ConestogaWagonPresenter.new ConestogaWagon.find(params[:id])
  end
end
```

```haml
-# app/views/conestoga_wagons/show.html.haml
span.description= @conestoga_wagon.description
```

### Translating between form params and model attributes

In this example, the `GoldRush` model has separate `city` and `territory`
fields, but we want to present that to the user as a single form field.
The decorator will split the incoming `location` param into `city` and
`territory` fields, and vice versa.

```ruby
    # app/models/gold_rush.rb
    # The table gold_rushes has columns city:string and territory:string
    class GoldRush < ActiveRecord::Base
    end

    # app/decorators/gold_rush_form.rb
    class GoldRushForm < Pardner::Base
      howdy_pardner GoldRush

      def location
        "#{city}, #{territory}"
      end

      def location=(val)
        self.city, self.territory = val.split ','
      end
    end

    # app/controllers/gold_rushes_controller.rb
    class GoldRushesController < ApplicationController
      def new
        @gold_rush = GoldRushForm.new GoldRush.new
      end

      def create
        @gold_rush = GoldRushForm.new GoldRush.new
        @gold_rush.attributes = params[:gold_rush]

        if @gold_rush.save
          flash[:notice] = "There's gold in them thar hills"
        else
          render :new
        end
      end
    end
```

```haml
    -# app/view/gold_rushes/new.html.haml
    = form_for @gold_rush do |form|
      form.text :location
      form.submit
```

### Saving multiple ActiveRecord models atomically

A decorator can be a convenient way to coordinate changes to several
models atomically. Model callbacks can also be used for this but have
some downsides:

* sometimes its not clear which model should have the callback,
* decorators can opt-in more easily than callbacks,
* and extensive use of callbacks can lead to infinite loops.

In this example, when a gold rush is declared a bunch of supporting
models need to be created.

```ruby
# app/controllers/gold_rushes_controller.rb
class GoldRushesController < ApplicationController
  def create
    @gold_rush = GoldRushDeclared.new GoldRush.new
    @gold_rush.attributes = params[:gold_rush]

    if @gold_rush.save
      flash[:notice] = "There's gold in them thar hills"
    else
      render :new
    end
  end
end

# app/services/gold_rush_declared.rb
class GoldRushDeclared < Pardner::Base
  howdy_pardner GoldRush
  before_validate :build_infrastructure
  validate :mining_town_must_exist
  validate :transport_must_exist

  private

  def build_infrastructure
    if MiningTown.where(territory: self.territory).is_nearby(self).empty?
      MiningTown.create! territory: self.territory, name: "Town near #{self.name}"
    end

    if Railroad.is_nearby(self).empty? && WagonTrail.is_nearby(self).empty?
      WagonTrail.create! territory: self.territory, destination: self.location
    end
  end

  def mining_town_must_exist
    return if MiningTown.is_nearby(self)
    errors.add :base, 'no mining town exists'
  end

  def transport_must_exist
    return if Railroad.is_nearby(self) || WagonTrail.is_nearby(self)
    errors.add :base, 'no transport exists'
  end
end
```

### Adding optional validations

In this example, we have two controllers for the same resource. One
supports an admin interface and one is customer facing. We want the
customer facing one to do more validation than the admin one.

```ruby
# app/decorators/small_posse.rb
class SmallPosse < Pardner::Base
  howdy_pardner Posse
  validate :must_be_small

  MAX_SIZE = 5

  private

  def must_be_small
    if deputies_count > MAX_SIZE
      errors.add :deputies, "must be less than #{MAX_SIZE}"
    end
  end
end

# app/controllers/posses_controller.rb
class PossesController < ApplicationController
  def create
    # This controller is customer facing so they can only create small posses
    @posse = SmallPosse.new Posse.new
    @posse.attributes = params[:posse]

    if @posse.save
      flash[:notice] = 'Get a rope'
    else
      render :new
    end
  end
end

# app/controllers/admin/posses_controller.rb
module Admin
  class PossesController < ApplicationController
    def create
      # This controller is for admins so they can do what they want
      @posse = Posse.new params[:posse]

      if @posse.save
        flash[:notice] = 'Every day above ground is a good day'
      else
        render :new
      end
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pardner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pardner

## Similar projects

* draper https://github.com/drapergem/draper
* informal https://github.com/joshsusser/informal
* more https://www.ruby-toolbox.com/categories/rails_presenters

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ajh/pardner.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
