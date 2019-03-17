module TailorMade
  module Methods
    def self.included(base) # :nodoc:
      const_set('CANONICAL_DIMENSIONS', [])
      const_set('CANONICAL_DOMAIN', {})
      const_set('CANONICAL_ANCHORS', {})
      const_set('TAILOR_MADE_MEASURES', [])
      const_set('TAILOR_MADE_MEASURE_FORMULA', {})
      const_set('DATETIME_COLUMNS', [])
      const_set('DATETIME_DIMENSIONS', {})
      const_set('TAILOR_MADE_MEASURES_DATETIME_PERMITED', {})
      base.extend ClassMethods
    end

    module ClassMethods
      def dimension(*attributes)
        dimension = attributes[0]
        return if CANONICAL_DIMENSIONS.include?(dimension)
        CANONICAL_DIMENSIONS << dimension

        attr_accessor dimension
        CANONICAL_DOMAIN[dimension] = attributes[1][:domain] if attributes[1] && attributes[1][:domain]
        CANONICAL_ANCHORS[dimension] = attributes[1][:anchor] if attributes[1] && attributes[1][:anchor]
      end

      def measure(*attributes)
        measure = attributes[0]
        return if TAILOR_MADE_MEASURES.include?(measure)
        TAILOR_MADE_MEASURES << measure

        if attributes[1] && attributes[1][:formula]
          TAILOR_MADE_MEASURE_FORMULA[measure] = attributes[1][:formula]
        end
      end

      def datetime_dimension(*attributes)
        dimension = attributes[0]
        return if DATETIME_COLUMNS.include?(dimension)
        DATETIME_COLUMNS << dimension
        attr_accessor "#{dimension.to_s}_starts_at".to_sym
        attr_accessor "#{dimension.to_s}_ends_at".to_sym

        if attributes[1] && attributes[1][:permit]
          permit = attributes[1][:permit]
        else
          permit = Groupdate::PERIODS
        end

        TAILOR_MADE_MEASURES_DATETIME_PERMITED[dimension] = permit

        DATETIME_DIMENSIONS[dimension] = permit.map do |period|
          [dimension, period].join("_").to_sym
        end
        # groups (day, month, year..)
      end
    end
  end
end
