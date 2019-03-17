module TailorMade
  class Query
    include ActiveModel::Model
    include TailorMade::Methods # creates accesors for dimensions and measures

    attr_accessor :measures
    attr_accessor :dimensions
    attr_accessor :plot_measure
    attr_accessor :chart
    attr_reader :options_for_select
    attr_reader :scope

    CHARTS = [
      :pie_chart,
      :line_chart,
      :column_chart,
      :bar_chart,
      :area_chart,
      :scatter_chart,
      :geo_chart,
      :timeline,
    ]

    def initialize(attributes={})
      super
      @dimensions     ||= default_dimensions
      @dimensions       = @dimensions.reject(&:blank?).map(&:to_sym)
      @measures       ||= default_measures
      @measures         = @measures.reject(&:blank?).map(&:to_sym)
      @plot_measure   ||= measures.first

      set_datetime_ranges
      @scope = build_scope(from, dimensions)
    end

    def from
      fail(NotImplementedError) # required to implement in subclass
    end

    def options_for_select
      fail(NotImplementedError) # required in beta version
    end

    def chart
      @chart ||= :pie_chart
    end

    def plot
      result = scope.order(order).pluck(plot_formulas(dimensions, scope))
      return result if dimensions.size < 2
      result.map { |row| row[1...-1] }.uniq.map { |combination|
        {
          name: combination.join("#"),
          data: combination_data(dimension_groups_sorted(dimensions, scope), combination)
        }
      }
    end

    def combination_data(groups, combination)
      # combination.each_with_index.map { |param, index| [groups[index + 1].to_sym , param] }
      scope = from
      combination.each_with_index.each { |param, index|
        scope = scope.where("#{groups[index + 1]} = ?", param)
      }
      plot_dimension = groups[0]
      scope = build_scope(scope, [plot_dimension])
      scope.order(
        { dimension_alias(plot_dimension, scope).to_sym => :asc }
      ).pluck(
        plot_formulas([plot_dimension], scope)
      )
    end

    def all
      scope.order(order).select(table_formulas)
    end

    def table_columns
      @table_columns ||= begin
        group_values = @scope.group_values.map { |column|
          (column.respond_to? :name) ? group_alias(column) : column
        }
        group_values + measures
      end
    end



    def tabelize(row, column)
      if CANONICAL_ANCHORS[column].nil?
        row.send(column)
      else
        if CANONICAL_ANCHORS[column].respond_to? :call
          CANONICAL_ANCHORS[column] = CANONICAL_ANCHORS[column].call
        end
        result = CANONICAL_ANCHORS[column][row.send(column)]
        result = [row.send(column), result] if result
        result ||= row.send(column)
      end
    end

    private

    def build_scope(scope, dimensions)
      scope = build_canonical_scope(scope)

      scope = build_datetime_dimensions_scope(scope, dimensions)

      datetime_dimensions = DATETIME_DIMENSIONS.values().flatten
      unless (dimensions - datetime_dimensions).empty?
        scope = scope.group(dimensions - datetime_dimensions)
      end
      scope
    end

    def build_canonical_scope(scope)
      CANONICAL_DIMENSIONS.each do |dimension|
        scope = scope.where('#{dimension} LIKE ?', "%#{send(dimension)}%") if send(dimension).present?
      end
      scope
    end

    # Datetime

    def build_datetime_dimensions_scope(scope, dimensions)
      DATETIME_COLUMNS.each do |dimension|
        scope = build_datetime_dimension_scope(scope, dimension, dimensions)
      end
      scope
    end

    def build_datetime_dimension_scope(scope, dimension, dimensions)
      starts_at = instance_variable_get("@#{dimension}_starts_at")
      ends_at = instance_variable_get("@#{dimension}_ends_at")
      permit = TAILOR_MADE_MEASURES_DATETIME_PERMITED[dimension]

      if !starts_at.blank? && !ends_at.blank?
        scope = scope.where(dimension.to_sym => starts_at..ends_at)
      end

      datetime_dimension_periods(dimension, dimensions).each do |datetime_dimension|
        period_type = get_datetime_dimension_period(dimension, datetime_dimension)
        scope = scope.group_by_period(period_type, dimension, permit: permit)
      end
      scope
    end

    def datetime_dimension_periods(datetime_dimension, dimensions)
      dimensions.select { |dimension|
        DATETIME_DIMENSIONS[datetime_dimension].include?(dimension)
      }
    end

    def get_datetime_dimension_period(dimension, datetime_dimension)
      datetime_dimension.to_s.reverse.chomp((dimension.to_s + "_").reverse).reverse.to_sym
    end

    def set_datetime_ranges
      DATETIME_COLUMNS.each do |dimension|
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

    # Order and selects

    def order(scope = @scope)
      col = scope.group_values.map { |column|
        (column.respond_to? :name) ? group_alias(column) : column
      }.first
      { col.to_sym => :asc }
    end

    def group_alias(group)
      aliaz = "#{group.relation.name}.#{group.name}"
      scope.connection.table_alias_for(aliaz)
    end

    def dimension_alias(dimension, scope)
      group = find_group(dimension, scope.group_values)
      if group.respond_to? :name
        group_alias(group)
      else
        group
      end
    end

    def dimensions_formulas(groups)
      groups.map { |group|
        if group.respond_to? :name
          "#{group} AS #{group_alias(group)}"
        else
          group
        end
      }
    end

    def dimension_groups_sorted(dimensions, scope)
      dimensions.map do |dimension|
        find_group(dimension, scope.group_values)
      end
    end

    def plot_formulas(dimensions, scope)
      groups = dimension_groups_sorted(dimensions, scope)
      (dimensions_formulas(groups) + measure_formulas([plot_measure.to_sym]))
    end

    def table_formulas
      groups = dimension_groups_sorted(dimensions, scope)
      (dimensions_formulas(groups) + measure_formulas(measures))
    end

    def measure_formulas(measures)
      measures.map { |measure|
        [TAILOR_MADE_MEASURE_FORMULA[measure], measure].join(" AS ")
      }
    end

    def find_group(dimension, groups)
      groups.find {|group|
        dimension == group ||
          (
            group.respond_to?(:name) &&
            dimension == group.name.to_sym
          )
      }
    end
  end
end
