module TailorMade
  module Methods
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def dimension(*attributes)
        dimension = attributes[0]
        return if tailor_made_canonical_dimensions.include?(dimension)
        tailor_made_canonical_dimensions << dimension

        attr_accessor dimension
        tailor_made_canonical_domain[dimension] = attributes[1][:domain] if attributes[1] && attributes[1][:domain]
        tailor_made_canonical_anchors[dimension] = attributes[1][:anchor] if attributes[1] && attributes[1][:anchor]
      end

      def filter(*attributes)
        filter = attributes[0]
        return if tailor_made_filters.include?(filter)
        TAILOR_MADE_FILTERS << filter

        attr_accessor filter
        tailor_made_canonical_domain[dimension] = attributes[1][:domain] if attributes[1] && attributes[1][:domain]
        tailor_made_canonical_anchors[dimension] = attributes[1][:anchor] if attributes[1] && attributes[1][:anchor]
      end

      def measure(*attributes)
        measure = attributes[0]
        return if tailor_made_measures.include?(measure)
        tailor_made_measures << measure

        if attributes[1] && attributes[1][:formula]
          tailor_made_measure_formula[measure] = attributes[1][:formula]
        end
      end

      def datetime_dimension(*attributes)
        dimension = attributes[0]
        return if tailor_made_datetime_columns.include?(dimension)
        tailor_made_datetime_columns << dimension
        attr_accessor "#{dimension.to_s}_starts_at".to_sym
        attr_accessor "#{dimension.to_s}_ends_at".to_sym

        if attributes[1] && attributes[1][:permit]
          permit = attributes[1][:permit]
        else
          permit = Groupdate::PERIODS
        end

        tailor_made_measures_datetime_permited[dimension] = permit

        tailor_made_datetime_dimensions[dimension] = permit.map do |period|
          [dimension, period].join("_").to_sym
        end
        # groups (day, month, year..)
      end

      def permitted_attributes
        [
          :chart,
          :plot_measure,
          measures: [],
          dimensions: []
        ] +
        tailor_made_datetime_columns.map { |a| "#{a.to_s}_starts_at".to_sym } +
        tailor_made_datetime_columns.map { |a| "#{a.to_s}_ends_at".to_sym } +
        tailor_made_canonical_dimensions +
        tailor_made_filters

      end

      def tailor_made_canonical_dimensions
        @tailor_made_canonical_dimensions ||= []
      end

      def tailor_made_canonical_domain
        @tailor_made_canonical_domain ||= {}
      end

      def tailor_made_canonical_anchors
        @tailor_made_canonical_anchors ||= {}
      end

      def tailor_made_measures
        @tailor_made_measures ||= []
      end

      def tailor_made_measure_formula
        @tailor_made_measure_formula ||= {}
      end

      def tailor_made_datetime_columns
        @tailor_made_datetime_columns ||= []
      end

      def tailor_made_datetime_dimensions
        @tailor_made_datetime_dimensions ||= {}
      end

      def tailor_made_measures_datetime_permited
        @tailor_made_measures_datetime_permited ||= {}
      end

      def tailor_made_filters
        @tailor_made_filters ||= []
      end
    end
  end
end
