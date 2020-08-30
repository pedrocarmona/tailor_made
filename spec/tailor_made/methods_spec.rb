require "action_view"

RSpec.describe TailorMade::Methods do
  describe ".default_chart" do
    subject(:base_class) do
      Class.new do
        include ::TailorMade::Methods

        default_chart :line_chart
      end
    end

    it { expect(subject.default_chart).to eq(:line_chart) }
  end

  describe ".table" do
    subject(:base_class) do
      Class.new do
        include ::TailorMade::Methods

        table :movies_ratings
      end
    end

    it { expect(subject.table).to eq(Arel::Table.new(:movies_ratings)) }
    it { expect(subject.from).to eq(Arel::Table.new(:movies_ratings)) }

    context "when argument is a string" do
      subject(:base_class) do
        Class.new do
          include ::TailorMade::Methods

          table 'movies_ratings'
        end
      end

      it { expect(subject.table).to eq(Arel::Table.new(:movies_ratings)) }
      it { expect(subject.from).to eq(Arel::Table.new(:movies_ratings)) }
    end

    context "when argument is an arel table" do
      subject(:base_class) do
        Class.new do
          include ::TailorMade::Methods

          table Arel::Table.new(:movies_ratings)
        end
      end

      it { expect(subject.table).to eq(Arel::Table.new(:movies_ratings)) }
      it { expect(subject.from).to eq(Arel::Table.new(:movies_ratings)) }
    end

    context "when argument is an arel select manager" do
      subject(:base_class) do
        Class.new do
          include ::TailorMade::Methods

          table Arel::Table.new(:users).project(Arel::Table.new(:users)[Arel.star])
        end
      end

      it { expect(subject.table).to eq(Arel::Table.new(:query)) }
      it { expect(subject.from).to eq(Arel::Table.new(:users).project(Arel::Table.new(:users)[Arel.star]).as('query')) }
    end
  end

  describe ".sortable" do
    let(:base_class) do
      Class.new do
        include ::TailorMade::Methods
      end
    end
    subject(:sortable) { base_class.sortable(view_context, query_instance, 'ratings_count') }
    let(:view_context) { ActionView::Base.new }
    let(:query_instance) { instance_double(TailorMade::Query) }

    before do
      allow(query_instance).to receive(:sort_column).and_return('ratings_count')
      allow(query_instance).to receive(:sort_direction).and_return('asc')
      allow(query_instance).to receive(:to_params).and_return({})
      allow(view_context).to receive(:url_for).and_return('')
    end
    it { expect(subject).to eq("<a class=\"current asc\" data-turbolinks-action=\"replace\" href=\"\">Ratings Count</a>") }
  end

  describe ".dimension" do
    subject(:base_class) do
      Class.new do
        include ::TailorMade::Methods

        default_chart :line_chart
      end
    end

    it { expect(subject.default_chart).to eq(:line_chart) }
  end
end
