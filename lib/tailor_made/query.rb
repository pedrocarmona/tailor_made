module TailorMade
  class Query
    include ActiveModel::Model
    include ::TailorMade::DatetimeHelpers

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
    end

    def from
      fail(NotImplementedError) # required to implement in subclass
    end

    def options_for_select
      @options_for_select ||= begin
        options = {
          domain: self.class.tailor_made_canonical_dimensions + self.class.tailor_made_datetime_dimensions.values().flatten,
          dimensions: self.class.tailor_made_canonical_dimensions + self.class.tailor_made_datetime_dimensions.values().flatten,
          measures: self.class.tailor_made_measures,
          plot_measure: self.class.tailor_made_measures,
          chart: CHARTS
        }
        self.class.tailor_made_canonical_domain.each do |field|
          if self.class.tailor_made_canonical_domain[field]
            options = options.merge({ field => self.class.tailor_made_canonical_domain[field].call })
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
      result.map { |row| row[1...-1] }.uniq.map { |combination|
        {
          name: combination.join("#"),
          data: combination_data(dimensions, combination, view_context)
        }
      }
    end

    def combination_data(dimensions, combination, view_context)
      scope = from
      combination.each_with_index.each { |param, index|
        scope = scope.where("#{dimensions[index + 1]} = ?", param)
      }
      plot_dimension = dimensions[0]
      scope = build_scope(scope, [plot_dimension])
      raw_result = scope.order(
        { plot_dimension => :asc }
      ).pluck(
        plot_formulas([plot_dimension], scope)
      )
      comb_dimensions = dimensions.dup
      comb_dimensions.pop
      columns = plot_header(comb_dimensions, scope)
      result = raw_result.map { |raw_row|
        row = Struct.new(*columns).new(*raw_row)
        columns.map { |column|
          graph_format(row, column) { |l| l.call(view_context, row.send(column)) }
        }
      }
    end

    def all
      @scope = build_scope(from, dimensions)
      scope.order(order).select(table_formulas)
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

    private

    def build_scope(scope, dimensions)
      scope = build_canonical_scope(scope)
      scope = build_datetime_dimensions_scope(scope, dimensions)

      dimensions.each do |dimension|
        if avaliable_datetime_dimensions.include?(dimension)
          datetime_dimension_periods(dimension, dimensions).each do |datetime_dimension|
            period_type = get_datetime_dimension_period(dimension, datetime_dimension)
            scope = scope.group_by_period(period_type, dimension, permit: permit)
          end
        else
          scope = scope.group(dimensions - datetime_dimensions)
        end
      end
      scope
    end

    def build_canonical_scope(scope)
      self.class.tailor_made_canonical_dimensions.each do |dimension|
        next if send(dimension).nil?
        scope = scope.where(
          ':dimension LIKE :pattern',
          dimension: dimension,
          pattern: "%#{send(dimension)}%"
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

    def order(order)
      order || @order || { @dimensions.first => :asc }
    end

    def dimensions_formulas(scope, dimensions)
      groupdate_indexes = scope.groupdate_values.map(&:group_index)
      aliases = scope.group_values.map.with_index do |group, index|
        if groupdate_indexes.include?(index)
          Arel::Nodes::As.new(
            Arel.sql(dimensions[index].to_s),
            Arel.sql(group.to_s)
          )
        else
          Arel.sql(group.to_s)
        end
      end
    end

    def plot_header(dimensions, scope)
      dimensions + [plot_measure.to_sym]
    end

    def plot_formulas(dimensions, scope)
      (dimensions_formulas(scope, dimensions) + measure_formulas([plot_measure.to_sym]))
    end

    def table_formulas
      (dimensions_formulas(scope, dimensions) + measure_formulas(measures))
    end

    def measure_formulas(measures)
      measures.map { |measure|
        formula = self.class.tailor_made_measure_formula[measure]
        if formula.nil?
          fail("Tailor Made mesasure #{measure.to_s} formula not set")
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
  end
end
