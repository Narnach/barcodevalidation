require "barcodevalidation/mixin/value_object"
require "barcodevalidation/error/argument_error_class"
require "barcodevalidation/digit"
require "barcodevalidation/digit_sequence"

RSpec.describe BarcodeValidation::DigitSequence do
  subject(:sequence) { described_class.new(input) }
  let(:input) { 123_456 }

  describe "#initialize" do
    it "caches equivalent instances" do
      first = described_class.new(123_456)
      second = described_class.new("123456")
      third = described_class.new([1, 2, 3, 4, 5, 6])
      expect(first).to be second
      expect(second).to be third
      expect(first).to be third
    end

    context "after creating many instances" do
      before { described_class.new(input) }
      let(:inputs) do
        [
          "123", "456", "789",
          123, 456, 789,
          [1, 2, 3], [4, 5, 6], [7, 8, 9],
          described_class.new(123), described_class.new(456)
        ]
      end

      subject(:every_instance) do
        cache = described_class.instance_variable_get(:@__new_cache)
        (cache || {}).values
      end

      specify "none of them are equal to any other" do
        every_instance.to_a.permutation(2) do |a, b|
          expect(a).to_not eq b
        end
      end
    end
  end

  context "in comparison to another sequence" do
    let(:other) { described_class.new(other_input) }

    context "with an equivalent sequence" do
      let(:other_input) { input }
      it { is_expected.to eq other }
      it { is_expected.to eql other }
      its(:hash) { is_expected.to eq other.hash }
      its(:object_id) { is_expected.to eq other.object_id }
    end

    context "with a different sequence" do
      let(:other_input) { 987_654 }
      it { is_expected.to_not eq other }
      it { is_expected.to_not eql other }
      its(:hash) { is_expected.to_not eq other.hash }
      its(:object_id) { is_expected.to_not eq other.object_id }
    end

    context "when the other is unrelated" do
      let(:other) { false }
      it { is_expected.to_not eq other }
      it { is_expected.to_not eql other }
      its(:hash) { is_expected.to_not eq other.hash }
      its(:object_id) { is_expected.to_not eq other.object_id }
    end
  end

  describe "#==" do
    let(:other) { described_class.new(other_input) }
    subject(:result) { sequence == other }

    context "when the other is equivalent" do
      let(:other_input) { input }
      it { is_expected.to be true }
    end

    context "when the other is different" do
      let(:other_input) { 234_567 }
      it { is_expected.to be false }
    end

    context "when the other is unrelated" do
      let(:other) { false }
      it { is_expected.to be false }
    end
  end

  describe "#*" do
    subject(:result) { sequence * times }
    let(:times) { 3 }
    it { is_expected.to be_an_instance_of described_class }
  end

  describe "#+" do
    subject(:result) { sequence + other }

    context "with an array containing valid digits" do
      let(:other) { [1, 3] }
      it { is_expected.to be_an_instance_of described_class }
    end

    context "with an array containing invalid digits" do
      let(:other) { [1, "a"] }
      it "fails" do
        expect { result }.to raise_error \
          ArgumentError,
          %(invalid value for BarcodeValidation::Digit(): "a")
      end
    end

    context "with an array containing out of range digits" do
      let(:other) { [1, 19] }
      it "fails" do
        expect { result }.to raise_error \
          BarcodeValidation::Digit::ArgumentError,
          "invalid value for BarcodeValidation::Digit(): 19"
      end
    end
  end

  describe "#slice" do
    context "with an index" do
      subject(:result) { sequence.slice(index) }
      let(:index) { 3 }
      it { is_expected.to be_an_instance_of BarcodeValidation::Digit }
      it { is_expected.to eq 4 }
    end

    context "with start and length" do
      subject(:result) { sequence.slice(start, length) }
      let(:start) { 2 }
      let(:length) { 3 }
      it { is_expected.to be_an_instance_of described_class }
      it { is_expected.to eq [3, 4, 5] }
      it { is_expected.to eq 345 }
      its(:to_s) { is_expected.to eq "345" }
      its(:inspect) { is_expected.to eq "#<#{described_class}(345)>" }
    end

    context "with a range" do
      subject(:result) { sequence.slice(range) }
      let(:range) { 2..3 }
      it { is_expected.to be_an_instance_of described_class }
      it { is_expected.to eq [3, 4] }
      it { is_expected.to eq 34 }
      its(:to_s) { is_expected.to eq "34" }
      its(:inspect) { is_expected.to eq "#<#{described_class}(34)>" }
    end
  end

  {
    "String of digits" => "2345",
    "Fixnum" => 2_345,
  }.each do |type, value|
    context "with a #{type} of '#{value}'" do
      let(:input) { value }
      its(:to_s) { is_expected.to eq "2345" }
      its(:inspect) { is_expected.to eq "#<#{described_class}(2345)>" }
      its(:length) { is_expected.to eq 4 }
      its(:first) { is_expected.to eq 2 }
      its(:last) { is_expected.to eq 5 }
    end
  end

  {
    "String including a leading zero" => "0123",
    "array of Fixnums" => [0, 1, 2, 3],
    "array of String digits" => %w(0 1 2 3),
  }.each do |type, value|
    context "with the #{type} of '#{value}'" do
      let(:input) { value }
      its(:to_s) { is_expected.to eq "0123" }
      its(:inspect) { is_expected.to eq "#<#{described_class}(0123)>" }
      its(:length) { is_expected.to eq 4 }
      its(:first) { is_expected.to eq 0 }
      its(:last) { is_expected.to eq 3 }
    end
  end

  context "with an invalid input" do
    let(:input) { nil }
    it "fails" do
      expect { sequence }.to raise_error(
        BarcodeValidation::DigitSequence::ArgumentError,
        "invalid value for BarcodeValidation::DigitSequence(): nil",
      )
    end
  end
end
