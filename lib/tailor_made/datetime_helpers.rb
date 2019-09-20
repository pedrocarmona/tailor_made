module TailorMade
  module DatetimeHelpers
    def tailor_made_datetime_columns
      fail(NotImplementedError)
    end

    def tailor_made_measures_datetime_permited
      fail(NotImplementedError)
    end

    def tailor_made_datetime_dimensions
      fail(NotImplementedError)
    end

    def build_datetime_dimensions_scope(scope, dimensions)
      tailor_made_datetime_columns.each do |dimension|
        scope = build_datetime_dimension_scope(scope, dimension, dimensions)
      end
      scope
    end

    def datetime_dimension_where(scope, dimension, value)
      dimension_data = datetime_dimension_data[dimension]
      datetime_dimension = dimension_data[:datetime_dimension]
      scope.where(datetime_dimension => value..value)
    end

    def build_datetime_dimension_scope(scope, dimension, dimensions)
      starts_at = instance_variable_get("@#{dimension}_starts_at")
      ends_at = instance_variable_get("@#{dimension}_ends_at")

      if !starts_at.blank? && !ends_at.blank?
        scope = scope.where(dimension => starts_at..ends_at)
      end
      scope
    end

    def datetime_dimension_data
      mapping = tailor_made_measures_datetime_permited.map { |datetime_dimension, dimension_periods|
        dimension_periods.map {|period|
          [
            [datetime_dimension.to_s, period.to_s].join("_").to_sym,
            { datetime_dimension: datetime_dimension, period: period }
          ]
        }
      }.flatten
      Hash[*mapping]
    end


    def add_datetime_dimension_group(scope, dimension)
      permitted = tailor_made_measures_datetime_permited[dimension]
      dimension_data = datetime_dimension_data[dimension]
      table = arel_table(dimension_data[:datetime_dimension], scope)
      scope.group_by_period(
        dimension_data[:period],
        table[dimension_data[:datetime_dimension]],
        permit: permitted
      )
    end

    def datetime_dimension_periods(datetime_dimension, dimensions)
      dimensions.select { |dimension|
        tailor_made_datetime_dimensions[datetime_dimension].include?(dimension)
      }
    end

    def get_datetime_dimension_period(dimension, datetime_dimension)
      datetime_dimension
        .to_s
        .reverse
        .chomp((dimension.to_s + "_").reverse)
        .reverse
        .to_sym
    end

    def set_datetime_ranges
      tailor_made_datetime_columns.each do |dimension|
        set_datetime_range(dimension)
      end
    end

    def set_datetime_range(dimension)
      starts_at = "@#{dimension}_starts_at"
      ends_at = "@#{dimension}_ends_at"

      instance_variable_set(
        starts_at,
        Date.parse(instance_variable_get(starts_at))
      ) unless instance_variable_get(starts_at).blank?

      instance_variable_set(
        ends_at,
        Date.parse(instance_variable_get(ends_at))
      ) unless instance_variable_get(ends_at).blank?

      return unless instance_variable_get(starts_at).blank?
      return unless instance_variable_get(ends_at).blank?
      return if datetime_dimension_periods(dimension, dimensions).empty?
      set_datetime_default(dimension)
    end

    def set_datetime_default(dimension)
      starts_at_options = datetime_dimension_periods(dimension, dimensions).map do |period|
        default_range_start(dimension)
      end

      ends_at_options = datetime_dimension_periods(dimension, dimensions).map do |period|
        default_range_start(dimension)
      end

      instance_variable_set("@#{dimension}_starts_at", starts_at_options.min)
      instance_variable_set("@#{dimension}_ends_at", ends_at_options.max)
    end

    def default_range_start(period)
      case period
      when :second
        Time.now.utc.to_date.beginning_of_day
      when :minute
        Time.now.utc.to_date.beginning_of_day
      when :hour
        Time.now.utc.to_date.beginning_of_day
      when :day
        Time.now.utc.to_date.beginning_of_week
      when :week
        Time.now.utc.to_date.beginning_of_month
      when :month
        Time.now.utc.to_date.beginning_of_year
      when :quarter
        Time.now.utc.to_date.beginning_of_year
      when :year
        Time.now.utc.to_date.beginning_of_year - 5.years
      when :day_of_week
        Time.now.utc.to_date.beginning_of_week
      when :hour_of_day
        Time.now.utc.to_date.beginning_of_day
      when :minute_of_hour
        Time.now.utc.to_date.beginning_of_day
      when :day_of_month
        Time.now.utc.to_date.beginning_of_month
      when :month_of_year
        Time.now.utc.to_date.beginning_of_year
      else
        nil
      end
    end

    def default_range_end(period)
      case period
      when :second
        Time.now.utc
      when :minute
        Time.now.utc
      when :hour
        Time.now.utc
      when :day
        Time.now.utc.to_date
      when :week
        Time.now.utc.to_date
      when :month
        Time.now.utc.to_date
      when :quarter
        Time.now.utc.to_date
      when :year
        Time.now.utc.to_date
      when :day_of_week
        Time.now.utc.to_date
      when :hour_of_day
        Time.now.utc.to_date
      when :minute_of_hour
        Time.now.utc.to_date
      when :day_of_month
        Time.now.utc.to_date
      when :month_of_year
        Time.now.utc.to_date
      else
        nil
      end
    end

  end
end
