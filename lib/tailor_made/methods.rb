module TailorMade
  module Methods
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def sortable(view_context, query, column)
        title = column.to_s.titleize
        css_class = column.to_s == query.sort_column ? "current #{query.sort_direction}" : nil
        direction = column.to_s == query.sort_column && query.sort_direction == "asc" ? "desc" : "asc"
        q = query.to_params.merge(
          sort_column: column,
          sort_direction: direction
        )
        html_tags =  {:class => css_class, data: { turbolinks_action: 'replace' } }
        view_context.link_to title, {q: q}, html_tags
      end

      def dimension(*attributes)
        dimension = attributes[0]
        return if tailor_made_canonical_dimensions.include?(dimension)
        tailor_made_canonical_dimensions << dimension

        attr_accessor dimension
        tailor_made_canonical_domain[dimension] = attributes[1][:domain] if attributes[1] && attributes[1][:domain]
        tailor_made_canonical_anchors[dimension] = attributes[1][:anchor] if attributes[1] && attributes[1][:anchor]
        tailor_made_canonical_graph_format[dimension] = attributes[1][:graph_format] if attributes[1] && attributes[1][:graph_format]
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

        tailor_made_measure_formula[measure] = attributes[1][:formula] if attributes[1] && attributes[1][:formula]
        tailor_made_canonical_format[measure] = attributes[1][:format] if attributes[1] && attributes[1][:format]
        tailor_made_canonical_graph_format[measure] = attributes[1][:graph_format] if attributes[1] && attributes[1][:graph_format]
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

        add_datetime_dimension_formats(dimension, permit)
        # groups (day, month, year..)
      end

      def add_datetime_dimension_formats(dimension, permitted)
        permitted.each do |period|
          dimension_period = [dimension, period].join("_").to_sym
          tailor_made_canonical_format[dimension_period] = datetime_format(period.to_sym)
        end
      end

      def datetime_format(period)
        case period
        when :second
          -> (view_context, time) { time.to_formatted_s(:db) }
        when :minute
          -> (view_context, time) { time.to_formatted_s(:db) }
        when :hour
          -> (view_context, time) { time.to_formatted_s(:db) }
        when :day
          -> (view_context, time) { time.to_date.to_formatted_s(:db) }
        when :week
          -> (view_context, time) { time }
        when :month
          -> (view_context, time) { time }
        when :quarter
          -> (view_context, time) { time }
        when :year
          -> (view_context, time) { time }
        when :day_of_week
          -> (view_context, time) { time }
        when :hour_of_day
          -> (view_context, time) { time }
        when :minute_of_hour
          -> (view_context, time) { time }
        when :day_of_month
          -> (view_context, time) { time }
        when :month_of_year
          -> (view_context, time) { time }
        else
          nil
        end
      end

      def permitted_attributes
        [
          :chart,
          :plot_measure,
          :sort_column,
          :sort_direction,
          measures: [],
          dimensions: [],
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

      def tailor_made_canonical_format
        @tailor_made_canonical_format ||= {}
      end

      def tailor_made_canonical_graph_format
        @tailor_made_canonical_graph_format ||= {}
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
