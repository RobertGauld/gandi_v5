# frozen_string_literal: true

describe GandiV5::Data do
  around(:each) do |example|
    # Class used for testing GandiV5::Data by including it.
    class DataTestClass
      include GandiV5::Data

      members :basic
      member :str_to_sym, converter: GandiV5::Data::Converter::Symbol
      member :arr_of_str_to_sym, converter: GandiV5::Data::Converter::Symbol, array: true
      member :diff_name, gandi_key: 'DiffName'
    end

    example.run

    Object.send(:remove_const, :DataTestClass)
  end

  subject { DataTestClass.new }

  describe '#initialize' do
    describe 'Given expected data' do
      subject { DataTestClass.new basic: :a, str_to_sym: :b, arr_of_str_to_sym: [:c], diff_name: :d }

      its('basic') { should be :a }
      its('str_to_sym') { should be :b }
      its('arr_of_str_to_sym') { should match_array [:c] }
      its('diff_name') { should be :d }
    end

    it 'Given unexpected data' do
      expect { DataTestClass.new no_member_by_this_name: :a }.to raise_error(
        ArgumentError,
        'unknown keyword: no_member_by_this_name'
      )
    end
  end

  describe '#to_h' do
    it 'Everything is blank' do
      expect(subject.to_h).to eq basic: nil, str_to_sym: nil, arr_of_str_to_sym: nil, diff_name: nil
    end

    it ':basic contains an enumerable with #transform_keys' do
      subject = DataTestClass.new basic: { a: 'a' }
      expect(subject.to_h).to include(basic: { a: 'a' })
    end

    it ':basic contains an enumerable with #map' do
      subject = DataTestClass.new basic: ['a']
      expect(subject.to_h).to include(basic: ['a'])
    end

    it ':basic contains an enumerable with values with #to_h' do
      value = double Object
      expect(value).to receive(:to_h).and_return('a' => 'a')
      subject = DataTestClass.new basic: [value]
      expect(subject.to_h).to include(basic: [{ 'a' => 'a' }])
    end

    it ':basic contains an enumerable with values without #to_h' do
      subject = DataTestClass.new basic: ['a']
      expect(subject.to_h).to include(basic: ['a'])
    end

    it ':basic contains a value with #to_h' do
      value = double Object
      expect(value).to receive(:to_h).and_return('a' => 'a')
      subject = DataTestClass.new basic: value
      expect(subject.to_h).to include(basic: { 'a' => 'a' })
    end

    it ':str_to_sym is not converted' do
      subject = DataTestClass.new str_to_sym: :a
      expect(subject.to_h).to include(str_to_sym: :a)
    end

    it ':arr_of_str_to_sym is not converted' do
      subject = DataTestClass.new arr_of_str_to_sym: [:a]
      expect(subject.to_h).to include(arr_of_str_to_sym: [:a])
    end

    it ':diff_name has correct key' do
      subject = DataTestClass.new diff_name: 'a'
      expect(subject.to_h).to include(diff_name: 'a')
    end
  end

  describe '#to_gandi' do
    it 'Everything is blank' do
      expect(subject.to_gandi).to eq 'basic' => nil, 'str_to_sym' => nil, 'arr_of_str_to_sym' => nil, 'DiffName' => nil
    end

    it ':basic contains an enumerable with #transform_keys' do
      subject = DataTestClass.new basic: { a: 'a' }
      expect(subject.to_gandi).to include('basic' => { a: 'a' })
    end

    it ':basic contains an enumerable with #map' do
      subject = DataTestClass.new basic: ['a']
      expect(subject.to_gandi).to include('basic' => ['a'])
    end

    it ':basic contains a value with #to_gandi' do
      value = double Object
      expect(value).to receive(:to_gandi).and_return('a' => 'a')
      subject = DataTestClass.new basic: value
      expect(subject.to_gandi).to include('basic' => { 'a' => 'a' })
    end

    it ':str_to_sym is converted' do
      subject = DataTestClass.new str_to_sym: :a
      expect(subject.to_gandi).to include('str_to_sym' => 'a')
    end

    it ':arr_of_str_to_sym is converted' do
      subject = DataTestClass.new arr_of_str_to_sym: [:a]
      expect(subject.to_gandi).to include('arr_of_str_to_sym' => ['a'])
    end

    it ':diff_name has correct key' do
      subject = DataTestClass.new diff_name: 'a'
      expect(subject.to_gandi).to include('DiffName' => 'a')
    end
  end

  describe '#values_at' do
    let(:basic) { DataTestClass.new basic: :basic }
    subject { DataTestClass.new basic: basic, arr_of_str_to_sym: [:a] }

    it 'basic' do
      expect(subject.basic).to be basic
    end

    it 'basic.basic' do
      expect(subject.basic.basic).to be :basic
    end

    it 'no_member_by_this_name' do
      expect { subject.values_at(:no_member_by_this_name) }.to raise_error(
        ArgumentError,
        'no_member_by_this_name is not a member.'
      )
    end

    it 'basic.no_member_by_this_name' do
      expect { subject.values_at('basic.no_member_by_this_name') }.to raise_error(
        ArgumentError,
        'no_member_by_this_name is not a member.'
      )
    end
  end

  describe '#from_gandi' do
    describe 'Everything is blank' do
      subject { DataTestClass.new.from_gandi({}) }

      its('basic') { should be nil }
      its('str_to_sym') { should be nil }
      its('arr_of_str_to_sym') { should be nil }
      its('diff_name') { should be nil }
    end

    it ':basic is left alone' do
      subject.from_gandi 'basic' => 'left_alone'
      expect(subject.basic).to be 'left_alone'
    end

    it ':str_to_sym is converted' do
      subject.from_gandi 'str_to_sym' => 'converted'
      expect(subject.str_to_sym).to be :converted
    end

    it ':arr_of_str_to_sym is converted' do
      subject.from_gandi 'arr_of_str_to_sym' => ['converted']
      expect(subject.arr_of_str_to_sym).to match_array [:converted]
    end

    it ':diff_name has correct key' do
      subject.from_gandi 'DiffName' => 'left_alone'
      expect(subject.diff_name).to be 'left_alone'
    end

    it 'returns self' do
      expect(subject.from_gandi({})).to be subject
    end
  end

  describe '.from_gandi' do
    it 'Given nothing' do
      expect(DataTestClass.from_gandi(nil)).to be nil
    end

    describe 'Everything is blank' do
      subject { DataTestClass.from_gandi({}) }

      its('basic') { should be nil }
      its('str_to_sym') { should be nil }
      its('arr_of_str_to_sym') { should be nil }
      its('diff_name') { should be nil }
    end

    it ':basic is left alone' do
      subject = DataTestClass.from_gandi 'basic' => 'left_alone'
      expect(subject.basic).to be 'left_alone'
    end

    it ':str_to_sym is converted' do
      subject = DataTestClass.from_gandi 'str_to_sym' => 'converted'
      expect(subject.str_to_sym).to be :converted
    end

    it ':arr_of_str_to_sym is converted' do
      subject = DataTestClass.from_gandi 'arr_of_str_to_sym' => ['converted']
      expect(subject.arr_of_str_to_sym).to match_array [:converted]
    end

    it ':diff_name has correct key' do
      subject = DataTestClass.from_gandi 'DiffName' => 'left_alone'
      expect(subject.diff_name).to be 'left_alone'
    end

    it 'returns a DataTestClass' do
      expect(DataTestClass.from_gandi({})).to be_a DataTestClass
    end
  end

  describe 'Attribute methods' do
    it '#basic=' do
      expect(subject.instance_variable_get(:@basic)).to be nil
      subject.send :basic=, :a
      expect(subject.instance_variable_get(:@basic)).to be :a
    end

    describe 'Is nil' do
      before(:each) { subject.send :basic=, nil }

      it('#basic?') { expect(subject.basic?).to be false }
      it('#basic') { expect(subject.basic).to be nil }
    end

    describe 'Is something' do
      let(:value) { double Object }
      before(:each) { subject.send :basic=, value }

      it('#basic?') { expect(subject.basic?).to be true }
      it('#basic') { expect(subject.basic).to be value }
    end
  end

  describe 'Internal API methods' do
    it '#data_members' do
      expect(subject.send(:data_members)).to match_array %i[basic str_to_sym arr_of_str_to_sym diff_name]
    end

    it '#data_member?' do
      expect(subject.send(:data_member?, :basic)).to be true
      expect(subject.send(:data_member?, :no_member_by_this_name)).to be false
    end

    it '#data_gandi_key_to_member' do
      expect(subject.send(:data_gandi_key_to_member, 'basic')).to be :basic
      expect(subject.send(:data_gandi_key_to_member, 'DiffName')).to be :diff_name
      expect { subject.send(:data_gandi_key_to_member, 'no_member_by_this_name') }.to raise_error KeyError
    end

    it '#data_member_to_gandi_key' do
      expect(subject.send(:data_member_to_gandi_key, :basic)).to eq 'basic'
      expect(subject.send(:data_member_to_gandi_key, :diff_name)).to eq 'DiffName'
      expect { subject.send(:data_member_to_gandi_key, :no_member_by_this_name) }.to raise_error KeyError
    end

    it '#data_converter_for' do
      expect(subject.send(:data_converter_for, :basic)).to be nil
      expect(subject.send(:data_converter_for, :str_to_sym)).to be GandiV5::Data::Converter::Symbol
      expect(subject.send(:data_converter_for, :no_member_by_this_name)).to be nil
    end

    it '#data_converter_for?' do
      expect(subject.send(:data_converter_for?, :basic)).to be false
      expect(subject.send(:data_converter_for?, :str_to_sym)).to be true
      expect(subject.send(:data_converter_for?, :no_member_by_this_name)).to be false
    end

    it '.data_members' do
      expect(DataTestClass.send(:data_members)).to match_array %i[basic str_to_sym arr_of_str_to_sym diff_name]
    end

    it '.data_member?' do
      expect(DataTestClass.send(:data_member?, :basic)).to be true
      expect(DataTestClass.send(:data_member?, :no_member_by_this_name)).to be false
    end

    it '.data_gandi_key_to_member' do
      expect(DataTestClass.send(:data_gandi_key_to_member, 'basic')).to be :basic
      expect(DataTestClass.send(:data_gandi_key_to_member, 'DiffName')).to be :diff_name
      expect { DataTestClass.send(:data_gandi_key_to_member, 'no_member_by_this_name') }.to raise_error KeyError
    end

    it '.data_member_to_gandi_key' do
      expect(DataTestClass.send(:data_member_to_gandi_key, :basic)).to eq 'basic'
      expect(DataTestClass.send(:data_member_to_gandi_key, :diff_name)).to eq 'DiffName'
      expect { DataTestClass.send(:data_member_to_gandi_key, :no_member_by_this_name) }.to raise_error KeyError
    end

    it '.data_converter_for' do
      expect(DataTestClass.send(:data_converter_for, :basic)).to be nil
      expect(DataTestClass.send(:data_converter_for, :str_to_sym)).to be GandiV5::Data::Converter::Symbol
      expect(DataTestClass.send(:data_converter_for, :no_member_by_this_name)).to be nil
    end

    it '.data_converter_for?' do
      expect(DataTestClass.send(:data_converter_for?, :basic)).to be false
      expect(DataTestClass.send(:data_converter_for?, :str_to_sym)).to be true
      expect(DataTestClass.send(:data_converter_for?, :no_member_by_this_name)).to be false
    end

    describe '.translate_gandi' do
      it 'Not given a Hash' do
        expect(DataTestClass.send(:translate_gandi, [])).to be_nil
      end

      it 'Does name mapping' do
        data = { 'basic' => 'a', 'DiffName' => 'b' }
        expect(DataTestClass.send(:translate_gandi, data).keys).to match_array %i[basic diff_name]
      end

      it 'Does value conversion' do
        data = { 'basic' => 'a', 'str_to_sym' => 'b', 'arr_of_str_to_sym' => ['c'] }
        expect(DataTestClass.send(:translate_gandi, data).values).to match_array ['a', :b, [:c]]
      end

      it 'Has worked on a clone' do
        data = {}
        expect(DataTestClass.send(:translate_gandi, data)).to_not be hash
      end
    end
  end
end
