module TailorMade
  class Query
    include ActiveModel::Model
    include ::TailorMade::DatetimeHelpers

    attr_accessor :measures
    attr_accessor :dimensions
    attr_accessor :plot_measure
    attr_accessor :chart
    attr_accessor :sort_column
    attr_accessor :sort_direction
    attr_reader :options_for_select
    attr_reader :sort_column
    attr_reader :sort_direction

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
    end

    def self.column_names
      (tailor_made_measures.compact || []) +
      (tailor_made_dimensions.compact || [])
    end

    def from
      fail(NotImplementedError) # required to implement in subclass
    end

    def options_for_select
      @options_for_select ||= begin
        options = {
          domain: self.class.tailor_made_dimensions,
          dimensions: self.class.tailor_made_dimensions,
          measures: self.class.tailor_made_measures,
          plot_measure: self.class.tailor_made_measures,
          chart: CHARTS
        }
        self.class.tailor_made_canonical_domain.each do |field, proc|
          if self.class.tailor_made_canonical_domain[field]
            options = options.merge({ field => proc.call })
          end
        end
        options
      end
    end

    def chart
      @chart ||= :pie_chart
    end

    def plot(view_context)
      scope = build_scope(from, dimensions)
      raw_result = scope.order(order).pluck(plot_formulas(dimensions, scope))
      columns = plot_header(dimensions, scope)
      result = raw_result.map { |raw_row|
        row = Struct.new(*columns).new(*raw_row)
        columns.map { |column|
          graph_format(row, column) { |l| l.call(view_context, row.send(column)) }
        }
      }
      return result if dimensions.size < 2
      result.inject({}) { |hash, row|
        key = row[0..-3]
        hash[key] = [] if hash[key].nil?
        hash[key] << [row[-2],row[-1]]
        hash
      }.map { |combination, data|
        {
          name: combination_title(columns, combination),
          data: data.to_h
        }
      }
    end

    def combination_title(columns, combination)
      if combination.size > 1
        columns[0..-3].map(&:to_s).map(&:titleize).zip(combination).map{|com| com.join(":") }.join("#")
      else
        combination
      end
    end

    def all
      scope = build_scope(from, dimensions)
      scope = scope.order(order)
      scope.select(table_formulas(scope))
    end

    def table_columns
      dimensions + measures
    end

    def graph_format(row, column)
      only_column = column.to_s.gsub([self.from.arel_table.name, "_"].join(""), "").to_sym
      if !(self.class.tailor_made_canonical_graph_format[column].nil?)
        lambding = self.class.tailor_made_canonical_graph_format[column]
        result = yield(lambding)
      elsif !(self.class.tailor_made_canonical_graph_format[only_column].nil?)
        lambding = self.class.tailor_made_canonical_graph_format[only_column]
        result = yield(lambding)
      end
      result || row.send(column)
    end

    def tabelize(row, column)
      only_column = column.to_s.gsub([self.from.arel_table.name, "_"].join(""), "").to_sym
      if !(self.class.tailor_made_canonical_anchors[column].nil?)
        if self.class.tailor_made_canonical_anchors[column].respond_to? :call
          lambding = self.class.tailor_made_canonical_anchors[column]
          result = yield(lambding)
        else
          lambding = ->(value) { self.class.tailor_made_canonical_anchors[column][value] }
          result = yield(lambding)
        end
      elsif !(self.class.tailor_made_canonical_format[column].nil?)
        lambding = self.class.tailor_made_canonical_format[column]
        result = yield(lambding)
      elsif !(self.class.tailor_made_canonical_format[only_column].nil?)
        lambding = self.class.tailor_made_canonical_format[only_column]
        result = yield(lambding)
      end
      result || row.send(column)
    end

    def to_params
      array = [
          :chart,
          :plot_measure,
          :measures,
          :dimensions
        ] +
        self.class.tailor_made_datetime_columns.map { |a| "#{a.to_s}_starts_at".to_sym } +
        self.class.tailor_made_datetime_columns.map { |a| "#{a.to_s}_ends_at".to_sym } +
        self.class.tailor_made_canonical_dimensions +
        self.class.tailor_made_filters
      Hash[array.uniq.map {|key| [key, send(key)]}].compact
    end

    private

    def build_scope(scope, dimensions)
      scope = build_canonical_scope(scope)
      scope = build_datetime_dimensions_scope(scope, dimensions)

      dimensions.each do |dimension|
        scope = build_dimension_scope(scope, dimension)
      end
      scope
    end

    def build_dimension_scope(scope, dimension)
      if avaliable_datetime_dimensions.include?(dimension)
        return add_datetime_dimension_group(scope, dimension)
      else
        return scope.group(dimension)
      end
    end

    def build_canonical_scope(scope)
      self.class.tailor_made_canonical_dimensions.each do |dimension|
        next if send(dimension).blank?
        scope = scope.where(
          scope.arel_table[dimension].send(:eq,send(dimension))
        )
      end
      self.class.tailor_made_filters.each do |filter|
        next if send(filter).blank?
        scope = scope.where(
          scope.arel_table[filter].send(:matches, send(filter))
        )
      end
      scope
    end

    def tailor_made_datetime_columns
      self.class.tailor_made_datetime_columns
    end

    def tailor_made_measures_datetime_permited
      self.class.tailor_made_measures_datetime_permited
    end

    def tailor_made_datetime_dimensions
      self.class.tailor_made_datetime_dimensions
    end

    # Order and selects

    def order(custom_order = nil)
      parse_order
      { @sort_column => @sort_direction }
    end

    def dimensions_formulas(scope, dimensions)
      groupdate_indexes = (scope.groupdate_values || []).map(&:group_index)
      aliases = scope.group_values.map.with_index do |group, index|
        if groupdate_indexes.include?(index)
          Arel::Nodes::As.new(
            Arel.sql(group.to_s),
            Arel.sql(dimensions[index].to_s)
          )
        else
          scope.arel_table[group]
        end
      end
    end

    def plot_header(dimensions, scope)
      dimensions + [plot_measure.to_sym]
    end

    def plot_formulas(dimensions, scope)
      (dimensions_formulas(scope, dimensions) + measure_formulas([plot_measure.to_sym]))
    end

    def table_formulas(scope)
      (dimensions_formulas(scope, dimensions) + measure_formulas(measures))
    end

    def measure_formulas(measures)
      measures.map { |measure|
        formula = self.class.tailor_made_measure_formula[measure]
        if formula.nil?
          fail("Tailor Made measure #{measure.to_s} formula not set")
        elsif formula.class <= Arel::Nodes::Node
          formula
        else
          Arel::Nodes::As.new(
            formula,
            Arel.sql(measure.to_s)
          )
        end
      }
    end

    def dimension_aliases(scope, dimensions)
      dimensions.zip(dimensions_formulas(scope, dimensions))
    end

    def avaliable_datetime_dimensions
      self.class.tailor_made_datetime_dimensions.values().flatten
    end

    def parse_order
      if @sort_column && self.class.column_names.include?(sort_column.to_sym)
        @sort_direction = %w[asc desc].include?(sort_direction) ? sort_direction : :asc
      else
        @sort_column = @dimensions.first
        @sort_direction = :asc
      end
    end
  end
end
