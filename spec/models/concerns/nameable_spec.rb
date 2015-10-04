require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Nameable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Nameable
    end
  end

  let :object do
    klass.new
  end

  describe '#other_names' do
    it 'should symbolize keys' do
      object.other_names = [{'name' => 'Mr. Ziggy Q. Public, Esq.', 'note' => 'Birth name'}]
      expect(object.other_names).to eq([{name: 'Mr. Ziggy Q. Public, Esq.', note: 'Birth name'}])
    end
  end

  describe '#add_name' do
    it 'should add a name' do
      object.add_name('Mr. Ziggy Q. Public, Esq.', start_date: '1920-01', end_date: '1949-12-31', note: 'Birth name', family_name: 'Public', given_name: 'John', additional_name: 'Quinlan', honorific_prefix: 'Mr.', honorific_suffix: 'Esq.')
      expect(object.other_names).to eq([{name: 'Mr. Ziggy Q. Public, Esq.', start_date: '1920-01', end_date: '1949-12-31', note: 'Birth name', family_name: 'Public', given_name: 'John', additional_name: 'Quinlan', honorific_prefix: 'Mr.', honorific_suffix: 'Esq.'}])
    end

    it 'should not add a name without a name' do
      object.add_name(nil)
      object.add_name('')
      expect(object.other_names.blank?).to eq(true)
    end
  end
end
