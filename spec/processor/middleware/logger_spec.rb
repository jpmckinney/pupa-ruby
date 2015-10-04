require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# @see test/adapters/logger_test.rb in faraday
describe Pupa::Processor::Middleware::Logger do
  let :io do
    StringIO.new
  end

  context 'with DEBUG log level' do
    let :logger do
      logger = Logger.new(io)
      logger.level = Logger::DEBUG
      logger
    end

    let :connection do
      Faraday.new do |connection|
        connection.use Pupa::Processor::Middleware::Logger, logger
        connection.adapter :test do |stubs|
          stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
        end
      end
    end

    before :each do
      @response = connection.get('/hello', nil, :accept => 'text/html')
    end

    it 'should still return output' do
      expect(@response.body).to eq('hello')
    end

    it 'should log the method and URL' do
      expect(io.string).to match('get http:/hello')
    end

    it 'should log request headers' do
      expect(io.string).to match('Accept: "text/html')
    end
  end

  context 'with INFO log level' do
    let :logger do
      logger = Logger.new(io)
      logger.level = Logger::INFO
      logger
    end

    let :connection do
      Faraday.new do |connection|
        connection.use Pupa::Processor::Middleware::Logger, logger
        connection.adapter :test do |stubs|
          stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
          stubs.post('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
        end
      end
    end

    context 'with GET request' do
      before :each do
        connection.get('/hello', nil, :accept => 'text/html')
      end

      it 'should log the method and URL' do
        expect(io.string).to match('get http:/hello')
      end

      it 'should not log request headers' do
        expect(io.string).not_to match('Accept: "text/html')
      end
    end

    context 'with POST request' do
      before :each do
        connection.post('/hello', 'foo=bar', :accept => 'text/html')
      end

      it 'should log the method and URL' do
        expect(io.string).to match('post http:/hello foo=bar')
      end

      it 'should not log request headers' do
        expect(io.string).not_to match('Accept: "text/html')
      end
    end
  end
end
