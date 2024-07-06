require 'faraday'
require 'faraday_middleware'
require_relative 'parameter_definition'

module Sbpayment
  class Request
    RETRY_INTERVAL  = 1
    DEFAULT_HEADERS = { 'content-type' => 'text/xml' }

    include ParameterDefinition

    def response_class
      self.class.const_get self.class.name.sub(/Request\z/, 'Response')
    end

    def perform
      config = Sbpayment.config

      url = config.sandbox ? Sbpayment::SANDBOX_URL : Sbpayment::PRODUCTION_URL

      faraday_options = {
        url: url,
        request: {
          open_timeout: config.open_timeout,
          timeout: config.timeout
        }
      }
      connection = Faraday.new(faraday_options) do |builder|
        builder.use Faraday::Request::Retry, max: config.retry_max_counts, interval: RETRY_INTERVAL, exceptions: [Errno::ETIMEDOUT, Timeout::Error, Faraday::TimeoutError, Faraday::ConnectionFailed]
        builder.request :basic_auth, config.basic_auth_user, config.basic_auth_password
        builder.adapter Faraday.default_adapter

        if config.proxy_uri
          options = { uri: config.proxy_uri, user: config.proxy_user, password: config.proxy_password }
          builder.proxy = options
        end
      end

      update_sps_hashcode

      # リクエストデータを出力
      puts connection

      response = connection.post Sbpayment::API_PATH, to_sbps_xml(need_encrypt: need_encrypt?), DEFAULT_HEADERS
      response_class.new response.status, response.headers, response.body, need_decrypt: need_encrypt?
    end

    private

    def need_encrypt?
      keys.key?('encrypted_flg') && read_params('encrypted_flg').to_s == '1'
    end
  end
end
