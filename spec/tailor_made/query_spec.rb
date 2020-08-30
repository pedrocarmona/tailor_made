RSpec.describe TailorMade::Query do
  let(:query_class) do
    Class.new(TailorMade::Query) do
      dimension :movie_id
      datetime_dimension :rated_at, default: true

      measure :average_rating, function: ->{ table[:rating].average }, default: true, plot: true
      measure :rating_count, function: ->{ table[:rating].count }, default: true

      default_chart :line_chart

      table :movies_ratings
    end
  end

  let(:query_instance) do
    query_class.new
  end

  fdescribe ".dimensions" do
    subject(:dimensions) { query_instance.dimensions }

    it {
        expect(subject).to eq([
          :movie_id,
          :rated_at,
          :rated_on
        ]
      )
    }
  end

  it "has measures" do
    expect(subject.measures).to eq([
        :average_rating,
        :rating_count
      ]
    )
  end

  it "has filters" do
    expect(subject.measures).to eq(
      [
        :rated_at_starts_at,
        :rated_at_ends_at,
        :created_at_starts_on,
        :created_at_ends_on,
        :movie_id
      ]
    )
  end
end
