require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Refinements do
  let(:schema) do
    {
      'properties' => {
        'email' => {
          'type' => ['string', 'null'],
          'format' => 'email',
        },
        'uri' => {
          'type' => ['string', 'null'],
          'format' => 'uri',
        },
      }
    }
  end

  context 'email validation' do
    it 'should not raise an error if valid' do
      expect{JSON::Validator.validate!(schema, 'email' => 'ceo@example.com')}.to_not raise_error
    end

    it 'should raise an error if invalid' do
      expect{JSON::Validator.validate!(schema, 'email' => 'example.com')}.to raise_error(JSON::Schema::ValidationError)
    end
  end

  context 'uri validation' do
    it 'should not raise an error if valid' do
      expect{JSON::Validator.validate!(schema, 'uri' => 'scheme://user:pass@host/path?query#fragment')}.to_not raise_error
    end

    it 'should raise an error if invalid' do
      expect{JSON::Validator.validate!(schema, 'uri' => 'example.com')}.to raise_error(JSON::Schema::ValidationError)
    end
  end
end
