# TailorMade

Currently in development.

Business intelligence for humans. This gem allows to create dashboards, based on query objects and plot one measure of the grouped data. Makes it easy for people without sql knowledge to explore data. Uses active record.

You will:

  - Build and edit reports in minutes ([view usage](#usage))

You should:

  - Build reports on top of materialized views for performance
  - Create a dedicated rails app for analytics (blazer, tailor_made, smashing, scenic).
  - Test your dashboards data, for visibility when they start failing

You could:

  - And custom external data for correlation (advertising campaign spent, etc)
  - Add input tables - pull data to input tables, or let it be pushed
  - Join data in a materialized view in scenic. Refresh daily


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tailor_made'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tailor_made

## Usage

Create your first dashboard:

    $ bin/rails g tailor_made:dashboard Ahoy::Visit


Then you can add the following statments to your query `rails_root/app/queries/tailor_made/ahoy/visit_query.rb`:


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


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pedrocarmona/tailor_made.

## TODO:

- [ ] fix plot group by (n+1 queries not required).
- [ ] plot and selectize in different request (caching, etc)
- [ ] show row with totals (unique dimensions, sum without grouping)
