require "arel"

module TailorMade
  module QueryMethods
    def self.included(base) # :nodoc:
      base.extend QueryClassMethods
    end

    module QueryClassMethods

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
    end

    def table_columns
      dimensions + measures
    end

    def tabelize(view_context, row, column)
      if !(self.class.tailor_made_canonical_anchors[column].nil?)
        lambding = self.class.tailor_made_canonical_anchors[column]
        result = lambding.call(view_context, row, column)
      elsif !(self.class.tailor_made_canonical_format[column].nil?)
        lambding = self.class.tailor_made_canonical_format[column]
        result = lambding.call(view_context, row, column)
      end

      result || row.send(column)
    end


  end
end
