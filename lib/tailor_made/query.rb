require "active_model"

module TailorMade
  class Query
    include ActiveModel::Model
    include ::TailorMade::Methods
    include ::TailorMade::DatetimeHelpers

    attr_accessor :measures
    attr_accessor :dimensions
    attr_accessor :sort_column
    attr_accessor :sort_direction
    attr_reader :options_for_select
    attr_reader :sort_column
    attr_reader :sort_direction

    def initialize(attributes={})
      @dimensions     ||= default_dimensions
      @dimensions       = @dimensions.reject(&:blank?).map(&:to_sym)
      @measures       ||= default_measures
      @measures         = @measures.reject(&:blank?).map(&:to_sym)

      set_datetime_ranges
    end

    def default_dimensions
      self.class.tailor_made_default_dimensions
      self.class.tailor_made_canonical_dimensions
    end

    def default_measures
      self.class.tailor_made_default_measures
    end

    def self.column_names
      (tailor_made_measures.compact || []) +
      (tailor_made_dimensions.compact || [])
    end

    def options_for_select
      @options_for_select ||= begin
        options = {
          domain: self.class.tailor_made_dimensions,
          dimensions: self.class.tailor_made_dimensions,
          measures: self.class.tailor_made_measures
        }
        self.class.tailor_made_canonical_domain.each do |field, proc|
          if self.class.tailor_made_canonical_domain[field]
            options = options.merge({ field => proc.call })
          end
        end
        options
      end
    end


    def all # return into a record
      scope = build_scope(from, dimensions)
      scope = scope.order(order)
      scope.select(table_formulas(scope))
    end

    def to_params
      array = [
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
      if datetime_dimensions_with_formula.include?(dimension)
        return add_datetime_dimension_group(scope, dimension)
      else
        return scope.group(arel_table(dimension, scope)[dimension])
      end
    end

    def build_canonical_scope(scope)
      self.class.tailor_made_canonical_dimensions.each do |dimension|
        dimension_values = (send(dimension) || []).select{|v| !v.blank? }
        next if dimension_values.empty?
        scope = scope.where(dimension => dimension_values)
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

    def arel_table(dimension, scope)
      table = self.class.tailor_made_table[dimension]
      if table
        Arel::Table.new(table)
      else
        scope.arel_table
      end
    end

    def dimensions_formulas(scope, dimensions)
      groupdate_indexes = (scope.groupdate_values || []).map(&:group_index)
      aliases = scope.group_values.map.with_index do |group, index|
        if groupdate_indexes.include?(index)
          table = arel_table(dimensions[index], scope)
          table_column = table[dimensions[index]]
          Arel::Nodes::As.new(
            Arel.sql(group.to_s),
            Arel.sql(table_column.name)
          )
        else
          group
        end
      end
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

    def datetime_dimensions_with_formula
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
