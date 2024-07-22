require 'spec_helper'

RSpec.describe WebValve::FakeServiceConfig do
  let(:fake_service) do
    Class.new(described_class) do
      def self.service_name
        'dummy'
      end

      def self.name
        'FakeDummy'
      end
    end
  end

  before do
    stub_const('FakeDummy', fake_service)
  end

  subject { described_class.new service_class_name: fake_service.name }

  describe 'initialization' do
    it 'accepts a custom url' do
      config = described_class.new(service_class_name: fake_service.name, url: 'http://custom.dev')
      expect(config.full_url).to eq 'http://custom.dev'
    end

    it 'accepts request_matcher' do
      request_matcher = { foo: 'bar' }
      config = described_class.new(service_class_name: fake_service.name, request_matcher: request_matcher)
      expect(config.request_matcher).to eq request_matcher
    end
  end

  describe '.explicitly_enabled?' do
    it 'returns false when DUMMY_ENABLED is unset' do
      expect(subject.explicitly_enabled?).to eq false
    end

    it 'returns true when DUMMY_ENABLED is truthy' do
      with_env 'DUMMY_ENABLED' => '1' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 't' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'true' do
        expect(subject.explicitly_enabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'not true or false' do
        expect(subject.explicitly_enabled?).to eq false
      end
    end
  end

  describe '.explicitly_disabled?' do
    it 'returns false when DUMMY_ENABLED is unset' do
      expect(subject.explicitly_disabled?).to eq false
    end

    it 'returns true when DUMMY_ENABLED is falsey' do
      with_env 'DUMMY_ENABLED' => '0' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'f' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'false' do
        expect(subject.explicitly_disabled?).to eq true
      end

      with_env 'DUMMY_ENABLED' => 'not true or false' do
        expect(subject.explicitly_disabled?).to eq false
      end
    end
  end

  describe '.service_url' do
    it 'raises if the url is not present' do
      expect { subject.service_url }.to raise_error <<~MESSAGE
        There is no URL defined for FakeDummy.
        Configure one by setting the ENV variable "DUMMY_API_URL"
        or by using WebValve.register "FakeDummy", url: "http://something.dev"
      MESSAGE
    end

    it 'discovers url via ENV based on fake service name' do
      with_env 'DUMMY_API_URL' => 'http://thingy.dev' do
        expect(subject.service_url).to eq 'http://thingy.dev'
      end
    end

    it 'removes embedded basic auth credentials' do
      with_env 'DUMMY_API_URL' => 'http://foo:bar@thingy.dev' do
        expect(subject.service_url).to eq 'http://thingy.dev'
      end
    end
  end

  describe '.path_prefix' do
    it 'raises if the url is not present' do
      expect { subject.path_prefix }.to raise_error(/There is no URL defined for FakeDummy/)
    end

    it 'returns root when there is no path in the service URL' do
      with_env 'DUMMY_API_URL' => 'http://bananas.test/' do
        expect(subject.path_prefix).to eq '/'
      end
      with_env 'DUMMY_API_URL' => 'https://some:auth@bananas.test//' do
        expect(subject.path_prefix).to eq '/' # Parses funkier URL
      end
    end

    it 'returns the path when there is one in the service URL' do
      with_env 'DUMMY_API_URL' => 'http://zombo.com/welcome' do
        expect(subject.path_prefix).to eq '/welcome'
      end
      with_env 'DUMMY_API_URL' => 'http://zombo.com/welcome/' do
        expect(subject.path_prefix).to eq '/welcome' # Ignores trailing '/'
      end
    end
  end

  describe '.full_url' do
    it 'returns the custom service url when provided' do
      with_env 'DUMMY_API_URL' => 'http://default.dev' do
        config = described_class.new(service_class_name: fake_service.name, url: 'http://custom.dev')
        expect(config.full_url).to eq 'http://custom.dev'
      end
    end

    it 'returns the default service url when custom url is not provided' do
      with_env 'DUMMY_API_URL' => 'http://default.dev' do
        expect(subject.full_url).to eq 'http://default.dev'
      end
    end
  end

  describe '.request_matcher' do
    it 'returns the provided request params' do
      params = { foo: 'bar' }
      config = described_class.new(service_class_name: fake_service.name, request_matcher: params)
      expect(config.request_matcher).to eq params
    end

    it 'returns nil when no request params are provided' do
      expect(subject.request_matcher).to be_nil
    end
  end
end
