module Logging
  # The Helper module provides utility functions for formatting and truncating log data.
  # It handles various data types (strings, arrays, hashes, objects) and ensures that
  # log output remains readable and manageable in size.
  #
  # Features:
  # - Smart truncation of long strings
  # - Depth-limited recursion for nested structures
  # - Size-limited array output
  # - Special handling for different data types
  # - Configurable limits for all truncation operations
  #
  # @example Basic string truncation
  #   Helper.truncate_for_log("very long string", max_length: 10)
  #   # => "very long s... (15 chars)"
  #
  # @example Array truncation
  #   Helper.truncate_for_log([1, 2, 3, 4, 5], max_array: 3)
  #   # => "[1, 2, 3, ... (5 items)]"
  #
  # @example Hash truncation with depth limit
  #   data = { a: { b: { c: 1 } } }
  #   Helper.truncate_for_log(data, max_depth: 2)
  #   # => "{a: {b: {...}}}"
  module Helper
    class << self
      # Truncates and formats an object for logging purposes
      #
      # @param obj [Object] The object to truncate
      # @param max_length [Integer] Maximum length for string values
      # @param max_depth [Integer] Maximum depth for nested structures
      # @param max_array [Integer] Maximum number of items to show in arrays/hashes
      #
      # @return [String] The formatted string representation
      #
      # @example Truncating a complex object
      #   Helper.truncate_for_log({
      #     users: [
      #       { name: "John", data: "..." },
      #       { name: "Jane", data: "..." }
      #     ]
      #   }, max_depth: 2, max_array: 1)
      #   # => "{users: [{name: \"John\", data: \"...\"}, ... (2 items)]}"
      def truncate_for_log(obj, max_length: 500, max_depth: 4, max_array: 30)
        return "nil" if obj.nil?
        return obj.to_s if obj.is_a?(Numeric) || obj.is_a?(TrueClass) || obj.is_a?(FalseClass)

        case obj
        when String then truncate_string(obj, max_length)
        when Array then truncate_array(obj, max_length, max_depth, max_array)
        when Hash then truncate_hash(obj, max_length, max_depth, max_array)
        else truncate_object(obj, max_length)
        end
      end

      private

      # Truncates a string to the specified maximum length
      #
      # @param str [String] The string to truncate
      # @param max_length [Integer] Maximum length for the string
      # @return [String] Truncated string with length indicator if truncated
      def truncate_string(str, max_length)
        return str if str.length <= max_length
        "#{str[0..max_length]}... (#{str.length} chars)"
      end

      # Truncates an array to the specified maximum size and depth
      #
      # @param arr [Array] The array to truncate
      # @param max_length [Integer] Maximum length for string values
      # @param max_depth [Integer] Maximum depth for nested structures
      # @param max_array [Integer] Maximum number of items to show
      # @return [String] Formatted array representation
      def truncate_array(arr, max_length, max_depth, max_array)
        return "[...]" if max_depth <= 0

        items = arr.first(max_array).map { |item|
          truncate_for_log(item, max_length: max_length, max_depth: max_depth - 1, max_array: max_array)
        }

        suffix = arr.size > max_array ? ", ... (#{arr.size} items)]" : "]"
        "[#{items.join(", ")}#{suffix}"
      end

      # Truncates a hash to the specified maximum size and depth
      #
      # @param hash [Hash] The hash to truncate
      # @param max_length [Integer] Maximum length for string values
      # @param max_depth [Integer] Maximum depth for nested structures
      # @param max_array [Integer] Maximum number of key-value pairs to show
      # @return [String] Formatted hash representation
      def truncate_hash(hash, max_length, max_depth, max_array)
        return "{...}" if max_depth <= 0

        items = hash.first(max_array).map { |k, v|
          value = truncate_for_log(v, max_length: max_length, max_depth: max_depth - 1, max_array: max_array)
          "#{k}: #{value}"
        }

        suffix = hash.size > max_array ? ", ... (#{hash.size} pairs)}" : "}"
        "{#{items.join(", ")}#{suffix}"
      end

      # Truncates any other object using inspect
      #
      # @param obj [Object] The object to truncate
      # @param max_length [Integer] Maximum length for the inspected string
      # @return [String] Truncated string representation of the object
      def truncate_object(obj, max_length)
        str = obj.inspect
        return str if str.length <= max_length
        "#{str[0..max_length]}... (#{obj.class})"
      end
    end
  end
end
