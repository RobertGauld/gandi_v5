# frozen_string_literal: true

describe GandiV5::Domain::Contact do
  subject { described_class.new type: :person, reachability: :yes, validation: :yes }

  describe '#name' do
    it 'Joins given and family for a person' do
      subject = described_class.new type: :person, given: 'John', family: 'Smith'
      expect(subject.name).to eq 'John Smith'
    end

    describe 'Gives organisation name for other types' do
      described_class::TYPES.keys.reject { |type| type == :person }.each do |type|
        it type.to_s.capitalize do
          subject = described_class.new type: type, organisation_name: 'Organisation Name'
          expect(subject.name).to eq 'Organisation Name'
        end
      end
    end
  end

  describe '#to_s' do
    it 'Joins type and name' do
      subject = described_class.new type: :person, given: 'Jane', family: 'Doe'
      expect(subject.to_s).to eq "Person\tJane Doe"
    end
  end

  describe '#to_gandi' do
    it('Is a person') { expect(described_class.new(type: :person).to_gandi['type']).to eq 0 }
    it('Is a company') { expect(described_class.new(type: :company).to_gandi['type']).to eq 1 }
    it('Is an association') { expect(described_class.new(type: :association).to_gandi['type']).to eq 2 }
    it('Is a public body') { expect(described_class.new(type: :'public body').to_gandi['type']).to eq 3 }
    it('Is a reseller') { expect(described_class.new(type: :reseller).to_gandi['type']).to eq 4 }
  end
end
