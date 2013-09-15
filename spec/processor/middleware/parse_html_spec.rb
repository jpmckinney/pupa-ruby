require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# @see spec/helper.rb and spec/parse_xml_spec.rb in faraday_middleware
describe Pupa::Processor::Middleware::ParseHtml do
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

  let(:html)  { '<html><head><title>foo</title></head><body>bar</body></html>' }
  let(:title) { 'foo' }
  let(:body) { 'bar' }

  context "no type matching" do
    it "doesn't change nil body" do
      expect(process(nil).body).to be_nil
    end

    it "turns empty body into nil" do
      expect(process('').body).to be_nil
    end

    it "parses html body" do
      response = process(html)
      expect(response.body.at_css('title').text).to eq(title)
      expect(response.body.at_css('body').text).to eq(body)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with preserving raw" do
    let(:options) { {:preserve_raw => true} }

    it "parses html body" do
      response = process(html)
      expect(response.body.at_css('title').text).to eq(title)
      expect(response.body.at_css('body').text).to eq(body)
      expect(response.env[:raw_body]).to eq(html)
    end

    it "can opt out of preserving raw" do
      response = process(html, nil, :preserve_raw => false)
      expect(response.env[:raw_body]).to be_nil
    end
  end

  context "with regexp type matching" do
    let(:options) { {:content_type => /\bhtml$/} }

    it "parses html body of correct type" do
      response = process(html, 'text/html')
      expect(response.body.at_css('title').text).to eq(title)
      expect(response.body.at_css('body').text).to eq(body)
    end

    it "ignores html body of incorrect type" do
      response = process(html, 'application/xml')
      expect(response.body).to eq(html)
    end
  end

  context "with array type matching" do
    let(:options) { {:content_type => %w[a/b c/d]} }

    it "parses html body of correct type" do
      expect(process(html, 'a/b').body).to be_a(Nokogiri::HTML::Document)
      expect(process(html, 'c/d').body).to be_a(Nokogiri::HTML::Document)
    end

    it "ignores html body of incorrect type" do
      expect(process(html, 'a/d').body).not_to be_a(Nokogiri::HTML::Document)
    end
  end

  it "doesn't choke on invalid html" do
    ['{!', '"a"', 'true', 'null', '1'].each do |data|
      expect{ process(data) }.to_not raise_error
    end
  end
end
