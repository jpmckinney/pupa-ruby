require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# @see spec/helper.rb and spec/parse_xml_spec.rb in faraday_middleware
describe Pupa::Processor::Middleware::ParseJson do
  let(:options) { Hash.new }
  let(:headers) { Hash.new }
  let(:middleware) {
    described_class.new(lambda {|env|
      Faraday::Response.new(env)
    }, options)
  }

  def process(body, content_type = nil, options = {})
    env = {
      :body => body, :request => options,
      :response_headers => Faraday::Utils::Headers.new(headers)
    }
    env[:response_headers]['content-type'] = content_type if content_type
    middleware.call(env)
  end

  let(:json)  { '{"title":"foo","body":"bar"}' }
  let(:title) { 'foo' }
  let(:body) { 'bar' }

  context "no type matching" do
    it "doesn't change nil body" do
      expect(process(nil).body).to be_nil
    end

    it "turns empty body into nil" do
      expect(process('').body).to be_nil
    end

    it "parses json body" do
      response = process(json)
      expect(response.body['title']).to eq(title)
      expect(response.body['body']).to eq(body)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with preserving raw" do
    let(:options) { {:preserve_raw => true} }

    it "parses json body" do
      response = process(json)
      expect(response.body['title']).to eq(title)
      expect(response.body['body']).to eq(body)
      expect(response.env[:raw_body]).to eq(json)
    end

    it "can opt out of preserving raw" do
      response = process(json, nil, :preserve_raw => false)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with regexp type matching" do
    let(:options) { {:content_type => /\bjson$/} }

    it "parses json body of correct type" do
      response = process(json, 'application/json')
      expect(response.body['title']).to eq(title)
      expect(response.body['body']).to eq(body)
    end

    it "ignores json body of incorrect type" do
      response = process(json, 'application/xml')
      expect(response.body).to eq(json)
    end
  end

  context "with array type matching" do
    let(:options) { {:content_type => %w[a/b c/d]} }

    it "parses json body of correct type" do
      expect(process(json, 'a/b').body).to be_a(Hash)
      expect(process(json, 'c/d').body).to be_a(Hash)
    end

    it "ignores json body of incorrect type" do
      expect(process(json, 'a/d').body).not_to be_a(Hash)
    end
  end

  it "chokes on invalid json" do
    expect{ process('{') }.to raise_error(Faraday::ParsingError)
  end
end
