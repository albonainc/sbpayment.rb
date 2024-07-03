require_relative '../../request'
require_relative '../../response'

module Sbpayment
  module API
    module Credit
      class CreateCustomerTokenizedPanRequest < Request
        class PayMethodInfo
          include ParameterDefinition

          tag 'pay_method_info'
          key :resrv1,        encrypt: true, type: :M
          key :resrv2,        encrypt: true, type: :M
          key :resrv3,        encrypt: true, type: :M
        end
        class PayOptionManage
          include ParameterDefinition

          tag 'pay_option_manage'
          key :token
          key :token_key
          key :cardbrand_return_flg, default: '1'
        end

        tag 'sps-api-request', id: 'MG12-00131-101'
        key :merchant_id, default: -> { Sbpayment.config.merchant_id }
        key :service_id,  default: -> { Sbpayment.config.service_id }
        key :cust_code
        key :sps_cust_info_return_flg, default: '1'
        key :pay_method_info, class: PayMethodInfo
        key :pay_option_manage, class: PayOptionManage
        key :encrypted_flg, default: '1'
        key :request_date, default: -> { TimeUtil.format_current_time }
        key :limit_second
        key :sps_hashcode
      end

      class CreateCustomerTokenizedPanResponse < Response
        DECRYPT_PARAMETERS = %i(res_pay_method_info.cardbrand_code).freeze
      end
    end
  end
end
