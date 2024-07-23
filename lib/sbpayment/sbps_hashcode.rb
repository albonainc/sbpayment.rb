module Sbpayment
  module SbpsHashcode
    def update_sps_hashcode
      write_params :sps_hashcode, generate_sps_hashcode
    end

    def generate_sps_hashcode(encoding: 'Shift_JIS', hashkey: Sbpayment.config.hashkey)
      Digest::SHA1.hexdigest((values_for_sps_hashcode.map(&:to_s).map(&:strip).join + hashkey).encode(encoding, undef: :replace, replace: '?'))
    end

    def values_for_sps_hashcode
      keys.values.reject(&:exclude).sort_by(&:position).flat_map do |key|
        value = read_params key.name
        case
        when key.klass == String
          key.cast_for_hashcode value
        when key.klass == Array
          value.flat_map(&:values_for_sps_hashcode)
        else
          value.values_for_sps_hashcode
        end
      end
    end
  end
end
