module Groupdate
  module GroupAlias
    attr_accessor :alias, :relation

    def name
      @alias
    end

    def as(other)
      Arel::Nodes::As.new(
        Arel.sql(sql),
        Arel::Nodes::SqlLiteral.new(other)
      )
    end

    def sql
      to_str
    end

    def to_s
      [relation.name, @alias].join("_")
    end
  end
end
