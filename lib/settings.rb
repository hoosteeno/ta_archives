require 'erb' unless defined?(ERB)
require 'yaml' unless defined?(YAML)

class Settings < Hash
  class << Settings
    def for(arg)
      if arg.respond_to?(:read)
        buf = arg.read
        expanded = ERB.new(buf).result(binding)
        hash = YAML.load(expanded)
      elsif arg.is_a?(Hash)
        hash = arg
      elsif arg.is_a?(String)
        buf = IO.read(arg)
        expanded = ERB.new(buf).result(binding)
        hash = YAML.load(expanded)
      else
        raise ArgumentError.new(arg.class.name)
      end
      new(hash)
    end

    alias_method 'from', 'for'
  end

  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end

  def default(key = nil)
    if key.is_a?(Symbol) && include?(key = key.to_s)
      self[key]
    else
      super
    end
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  def []=(key, value)
    regular_writer(convert_key(key), convert_value(value))
  end

  def update(other_hash)
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
    self
  end

  alias_method :merge!, :update

  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  # Fetches the value for the specified key, same as doing hash[key]
  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  # Returns an exact copy of the hash.
  def dup
    Settings.new(self)
  end

  def merge(hash)
    self.dup.update(hash)
  end

  def reverse_merge(other_hash)
    super as_settings(other_hash)
  end

  def delete(key)
    super(convert_key(key))
  end

  def stringify_keys!; self end
  def symbolize_keys!; self end
  def to_options!; self end

  # Convert to a Hash with String keys.
  def to_hash
    Hash.new(default).merge(self)
  end

  def =~(other)
    self == as_settings(other)
  end

  protected
    def as_settings(other = {})
      return other if other.is_a?(Settings)
      coerced = Settings.new.update(other)
    end

    def convert_key(key)
      key.kind_of?(Symbol) ? key.to_s : key
    end

    def convert_value(value)
      case value
      when Hash
        as_settings(value)
      when Array
        value.collect { |e| e.is_a?(Hash) ? as_settings(e) : e }
      else
        value
      end
    end
end
