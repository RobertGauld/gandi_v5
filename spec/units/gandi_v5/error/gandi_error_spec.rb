# frozen_string_literal: true

describe GandiV5::Error::GandiError::GandiError do
  describe 'Generate from Hash returned by Gandi' do
    it 'Single error' do
      hash = {
        'errors' => [
          { 'location' => 'body', 'name' => 'field', 'description' => 'message' }
        ]
      }
      error = described_class.from_hash hash
      expect(error.message).to eq 'body->field: message'
    end

    it 'Multiple errors' do
      hash = {
        'errors' => [
          { 'location' => 'body', 'name' => 'field', 'description' => 'message 1' },
          { 'location' => 'body', 'name' => 'field.sub', 'description' => 'message 2' },
          { 'location' => 'body', 'name' => 'field2', 'description' => 'message 3' }
        ]
      }
      error = described_class.from_hash hash
      expect(error.message).to eq "\n" \
                                  "body->field: message 1\n" \
                                  "body->field.sub: message 2\n" \
                                  'body->field2: message 3'
    end
  end
end
