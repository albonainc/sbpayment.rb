require_relative '../../request'
require_relative '../../response'

# NOTE: https://developer.sbpayment.jp/system-specifications/api-type/5904/#tag/%E6%B0%B8%E4%B9%85%E3%83%88%E3%83%BC%E3%82%AF%E3%83%B3%E6%A9%9F%E8%83%BD/paths/~1api~1xmlapi.do%20(MG12-00131-101)/post
module Sbpayment
  module API
    module Credit
      class CreateCustomerTokenizedPanRequest < Request
        class PayMethodInfo
          include ParameterDefinition

          tag 'pay_method_info'
          # 備考欄１
          key :resrv1,        encrypt: true, type: :M
          # 備考欄2
          key :resrv2,        encrypt: true, type: :M
          # 備考欄3
          key :resrv3,        encrypt: true, type: :M
        end
        class PayOptionManage
          include ParameterDefinition

          tag 'pay_option_manage'
          # トークン
          key :token
          # トークンキー
          key :token_key
          # クレジットカードブランド返却フラグ
          key :cardbrand_return_flg, default: '1'
        end

        tag 'sps-api-request', id: 'MG12-00131-101'
        # マーチャントID
        key :merchant_id, default: -> { Sbpayment.config.merchant_id }
        # サービスID
        key :service_id,  default: -> { Sbpayment.config.service_id }
        # 顧客ID
        key :cust_code
        # SBPS顧客情報返却フラグ
        key :sps_cust_info_return_flg, default: '1'
        # pay_method_info
        key :pay_method_info, class: PayMethodInfo
        # pay_option_manage
        key :pay_option_manage, class: PayOptionManage
        # 3DES暗号化フラグ
        key :encrypted_flg, default: '1'
        # リクエスト日時
        key :request_date, default: -> { TimeUtil.format_current_time }
        # リクエスト許容時間
        key :limit_second
        # チェックサム
        key :sps_hashcode
      end

      class CreateCustomerTokenizedPanResponse < Response
        DECRYPT_PARAMETERS = %i(res_pay_method_info.cardbrand_code).freeze
      end
    end
  end
end
