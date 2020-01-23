# frozen_string_literal: true

RSpec.describe Neo4j::Driver::Types::Node do
  subject(:node) do
    session = driver.session
    session.write_transaction do |tx|
      tx.run('CREATE (p:Person{name: "John", created: $date}) RETURN p', date: date).single.first
    end
  ensure
    session&.close
  end

  let(:date) { Date.today }

  it { is_expected.to be_a_kind_of described_class }
  its(:labels) { is_expected.to eq(%i[Person]) }
  its(:id) { is_expected.to be_a(Integer) }
  its(:properties) { is_expected.to eq(name: 'John', created: date) }
  it 'properties types should be correct' do
    expect(node.properties[:created]).to be_a(date.class)
  end
end
