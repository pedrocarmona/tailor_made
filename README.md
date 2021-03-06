# TailorMade

Currently in development.

Business intelligence for humans. This gem allows to create dashboards, based on query objects and plot one measure of the grouped data. Makes it easy for people without sql knowledge to explore data. Uses active record.

It uses metaprogramming to allow developers to easily build dashboards. The main reasons:
- Data users usually require the data as soon as possible, building dashboards should be fast;
- Developers can control access to data, decide which columns can be used - it makes it simpler to maintain the dashboards because its easier to detect when those columns are removed.

![Screenshot 2019-03-23 at 14 56 05](https://user-images.githubusercontent.com/2815199/54867179-876f9b80-4d7d-11e9-8c71-208df1aa8c0d.png)

([demo application](https://github.com/pedrocarmona/tailor_made_example))

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tailor_made'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tailor_made

Add pagy in app/helpers/application_helper.rb

```ruby
module ApplicationHelper
  include Pagy::Frontend
```

Two ways:

1. Add assets gems:

```ruby
# gem "selectize-rails" # and follow its instruction
# gem "chartkick" # and follow its instruction
# gem "flatpickr" # include also rangePlugin
```
Then you need to add statments to application.scss.

Otherwise:

2. Webpacker packages

```
  $ yarn add chartkick chart.js flatpickr selectize
```

2. Webpacker: /app/javascript/packs/application.js

```js
// tailor_made
import jquery from 'jquery'
import Chartkick from 'chartkick'
import Chart from 'chart.js'
import 'flatpickr'
import rangePlugin from 'flatpickr/dist/plugins/rangePlugin'
import "flatpickr/dist/flatpickr.css";
import 'selectize'
import "selectize/dist/css/selectize.css";
import "selectize/dist/css/selectize.bootstrap3.css";
Chartkick.addAdapter(Chart)
window.Chartkick = Chartkick
window.rangePlugin = rangePlugin
window.jquery = jquery
window.$ = jquery
```

2. Webpack: /app/assets/stylesheets/application.scss

```scss
@import "flatpickr/dist/flatpickr.css";
@import "selectize/dist/css/selectize.css";
@import "selectize/dist/css/selectize.bootstrap3.css";
```
## Usage

Create your first dashboard:

    $ bin/rails g tailor_made:dashboard Ahoy::Visit

The "DSL" to create dashboards is defined in a query object. There are dimensions (columns that can be grouped and filtered) and there are measures (columns where we aply a mathematical formula - sum, count, avg, etc). You need to specify the default dimensions and measures and also the from method is an active record relation - the rails model which we are querying.

In this example you can see that there are 2 types of dimensions: `dimension` and `datetime_dimension` - the form will create specific fields for datetime, and also several filters: `started_at_day`, `started_at_day``started_at_week`, etc.

Then you can add the following statements to your query `rails_root/app/queries/tailor_made/ahoy/visit_query.rb`:


```ruby
  module TailorMade
    class Ahoy::VisitQuery < TailorMade::Query
      # creates attr_accessors for dimensions, measures and filters
      include TailorMade::Methods

      datetime_dimension :started_at, permit: [:day, :day_of_week, :day_of_month, :week, :month_of_year]
      dimension(
        :device_type,
        domain: -> { Ahoy::Visits.all.pluck("DISTINCT device_type") }
      )
      dimension :referring_domain
      dimension :utm_campaign
      dimension :utm_content
      dimension :utm_medium
      dimension :utm_source
      dimension :utm_term
      measure :users_count, formula: "COUNT(user_id)"
      measure :visits_count, formula: "COUNT(id)"

      def default_dimensions
        [:device_type]
      end

      def default_measures
        [:visits_count, :users_count]
      end

      def initialize(attributes={})
        super
        @started_at_starts_at ||= Date.today.beginning_of_month
        @started_at_ends_at   ||= Date.today
      end

      def from
        ::Ahoy::Visit.all
      end
    end
  end
```

Visit `http://localhost:3000/tailor_made/ahoy/visits`.

## Credits

This project is a remake from a project developed by [@archan937](https://github.com/archan937), I am glad I could see it running. Since I saw Paul's project, I have tried to replicate it in another tools, but the in the end, there was always something missing. I really like the idea to allow users to build dynamic queries without need of sql or excel skills.

Also, thank you [Andrew](https://github.com/ankane) for building Blazer, Groupdate and Chartkick.

## Similar Projects

- [datagrid](https://github.com/bogdan/datagrid)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pedrocarmona/tailor_made.

## TODO:

- [ ] select in different request (caching, etc)
- [ ] show row with totals (unique dimensions, sum without grouping)
- [ ] improve datetime fields display format (missing datetime_format types week month in methods.rb)
- [ ] ability to compare with previous period side by side
- [ ] change select js lib to choices.js to be able to sort the order of dimensions
- [ ] action view component query `_filters` (bootstrap jquery/ bootstrap stimulus/ tailwind stimulus)
- [ ] to_csv
- [ ] lots of documentation and examples
