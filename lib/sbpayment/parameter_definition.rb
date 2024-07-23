require 'base64'
require 'digest/sha1'
require_relative 'crypto'
require_relative 'sbps_xml'
require_relative 'encoding'
require_relative 'sbps_hashcode'

module Sbpayment
  module ParameterDefinition
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def keys
        @keys ||= {}
      end

      def key(name, options={})
        Key.new(name, { position: keys.size + 1 }.merge(options)).tap do |key|
          keys[key.name] = key

          define_method key.rname do
            if instance_variable_defined? key.ivar
              instance_variable_get key.ivar
            else
              instance_variable_set key.ivar, key.default
            end
          end

          define_method key.wname do |value|
            instance_variable_set key.ivar, value
          end
        end
      end

      def many(name, options={})
        key name, { class: Array }.merge(options)
      end

      attr_reader :xml_tag, :xml_attributes

      def tag(name, attributes={})
        @xml_tag = name
        @xml_attributes = attributes
      end
    end

    include SbpsHashcode
    include SbpsXML

    def initialize(*arg, &blk)
      super
      keys.each_key { |name| read_params name }
    end

    def keys
      self.class.keys
    end

    def read_params(name)
      key = keys.fetch name.to_s
      __send__ key.rname
    end

    def write_params(name, value)
      __send__ keys.fetch(name.to_s).wname, value
    end

    def attributes
      {}.tap do |hash|
        keys.values.sort_by(&:position).each do |key|
          hash[key.name] = read_params key.name
        end
      end
    end

    def update_attributes(hash, utf8: false)
      hash.each do |name, value|
        next unless keys.key? name.to_s
        if utf8
          write_params(name, value.encode('UTF-8', 'Shift_JIS'))
        else
          write_params(name, value)
        end
      end
    end

    class Key
      attr_reader :name, :options, :type, :position, :encrypt, :klass, :exclude, :xml_tag

      def initialize(name, options)
        @name     = name.to_s
        @options  = options
        @type     = @options.fetch :type, :X
        @position = @options.fetch :position, 0
        @encrypt  = @options.fetch :encrypt, false
        @klass    = @options.fetch :class, String
        @xml_tag  = @options.fetch :tag, @name
        @exclude  = @name == 'sps_hashcode'
      end

      def rname
        "#{name}".freeze
      end

      def wname
        "#{name}=".freeze
      end

      def ivar
        "@#{name}".freeze
      end

      def default
        options[:default] && options[:default].is_a?(Proc) ? options[:default].call : options[:default] || klass.new
      end

      def array?
        klass == Array
      end

      def cast_for_hashcode(value)
        (value || default).to_s.encode('Shift_JIS', undef: :replace, replace: '?')
      end

      def cast_for_xml(value, need_encrypt: false)
        value = cast_for_hashcode value
        if need_encrypt && encrypt
          Base64.strict_encode64 Sbpayment::Crypto.encrypt value
        elsif type == :M
          Base64.strict_encode64 value
        else
          value
        end
      end
    end
  end
end
