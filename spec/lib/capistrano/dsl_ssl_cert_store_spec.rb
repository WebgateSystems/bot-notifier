# frozen_string_literal: true

require "spec_helper"
require "openssl"

RSpec.describe Capistrano::BotNotifier::DSL do
  # Minimal host that provides `fetch` and includes the DSL under test.
  let(:host_class) do
    Class.new do
      include Capistrano::BotNotifier::DSL
      def initialize(opts = {})
        @opts = opts
      end

      def fetch(key, default = nil)
        @opts.fetch(key, default)
      end
    end
  end

  let(:store) { instance_double(OpenSSL::X509::Store) }

  before do
    allow(store).to receive(:set_default_paths)
    allow(store).to receive(:add_file)
    allow(store).to receive(:add_path)
    allow(store).to receive(:flags=)

    # Only the check used by the implementation:
    allow(store).to receive(:respond_to?).with(:flags=).and_return(true)

    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  def expected_flag_for(mode)
    case mode
    when :leaf
      defined?(OpenSSL::X509::V_FLAG_CRL_CHECK) ? OpenSSL::X509::V_FLAG_CRL_CHECK : 0
    when :all
      defined?(OpenSSL::X509::V_FLAG_CRL_CHECK_ALL) ? OpenSSL::X509::V_FLAG_CRL_CHECK_ALL : 0
    else
      0
    end
  end

  it "sets flags= 0 when :bn_ssl_crl_check => :none" do
    host = host_class.new(bn_ssl_crl_check: :none)
    host.ssl_cert_store
    expect(store).to have_received(:flags=).with(0)
  end

  it "sets flags= 0 when legacy :bn_ssl_disable_crl => true and no explicit mode" do
    host = host_class.new(bn_ssl_disable_crl: true)
    host.ssl_cert_store
    expect(store).to have_received(:flags=).with(0)
  end

  it "sets flags appropriate for :leaf mode" do
    host = host_class.new(bn_ssl_crl_check: :leaf)
    host.ssl_cert_store
    expect(store).to have_received(:flags=).with(expected_flag_for(:leaf))
  end

  it "sets flags appropriate for :all mode" do
    host = host_class.new(bn_ssl_crl_check: :all)
    host.ssl_cert_store
    expect(store).to have_received(:flags=).with(expected_flag_for(:all))
  end

  it "gives precedence to :bn_ssl_crl_check over legacy :bn_ssl_disable_crl" do
    host = host_class.new(bn_ssl_crl_check: :leaf, bn_ssl_disable_crl: true)
    host.ssl_cert_store
    expect(store).to have_received(:flags=).with(expected_flag_for(:leaf))
  end

  context "when store does not support flags=" do
    before do
      allow(store).to receive(:respond_to?).with(:flags=).and_return(false)
    end

    it "does not attempt to set flags" do
      host = host_class.new(bn_ssl_crl_check: :all)
      host.ssl_cert_store
      expect(store).not_to have_received(:flags=)
    end
  end
end
