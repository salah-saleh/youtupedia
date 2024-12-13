module Logging
  # Helper module for formatting and truncating log data
  module Helper
    class << self
      def truncate_for_log(obj, max_length: 500, max_depth: 2, max_array: 3)
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

      def truncate_string(str, max_length)
        return str if str.length <= max_length
        "#{str[0..max_length]}... (#{str.length} chars)"
      end

      def truncate_array(arr, max_length, max_depth, max_array)
        return "[...]" if max_depth <= 0

        items = arr.first(max_array).map { |item|
          truncate_for_log(item, max_length: max_length, max_depth: max_depth - 1, max_array: max_array)
        }

        suffix = arr.size > max_array ? ", ... (#{arr.size} items)]" : "]"
        "[#{items.join(", ")}#{suffix}"
      end

      def truncate_hash(hash, max_length, max_depth, max_array)
        return "{...}" if max_depth <= 0

        items = hash.first(max_array).map { |k, v|
          value = truncate_for_log(v, max_length: max_length, max_depth: max_depth - 1, max_array: max_array)
          "#{k}: #{value}"
        }

        suffix = hash.size > max_array ? ", ... (#{hash.size} pairs)}" : "}"
        "{#{items.join(", ")}#{suffix}"
      end

      def truncate_object(obj, max_length)
        str = obj.inspect
        return str if str.length <= max_length
        "#{str[0..max_length]}... (#{obj.class})"
      end
    end
  end
end
