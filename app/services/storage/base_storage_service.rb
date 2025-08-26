module Storage
  class BaseStorageService
    def initialize(namespace)
      @namespace = namespace
      log_info "Initialized storage", context: { namespace: namespace }
    end

    # Fetches data from storage or generates it using the provided block
    # Only stores successful results (where result[:success] is true)
    # Automatically clears failed results from storage
    #
    # @param key [String] Storage key
    # @param force_block_execution [Boolean] If true, skip storage and execute block
    # @yield Block to generate data if not in storage
    # @return [Hash] The stored or generated data
    def fetch(key, force_block_execution: false, &block)
      log_info "Attempting to fetch from storage", key

      # Skip storage if force_block_execution is true
      unless force_block_execution
        # Try to get from storage first
        if exist?(key)
          log_info "Storage hit", key
          stored_data = read(key)

          # If stored data represents a failure, clear it and try again
          if stored_data.is_a?(Hash) && stored_data[:success] == false
            log_info "Found failed result in storage, clearing", context: {
              key: key,
              error: stored_data[:error]
            }
            delete(key)
          else
            log_info "Retrieved data from storage", key
            return stored_data
          end
        end
      else
        log_info "Forcing block execution, skipping storage", key
      end

      return unless block_given?

      # Execute the block to get fresh data
      log_info "Storage miss, executing block", key
      result = yield

      # Only store successful results
      if result.is_a?(Hash) && result[:success]
        log_info "Storing successful result", context: { key: key }
        write(key, result)
      elsif result.is_a?(Hash) && result[:error]
        log_info "Not storing failed result", context: {
          key: key,
          error: result[:error]
        }
      else
        log_info "Nothing to store", context: {
          key: key,
          result: result
        }
      end

      result
    end

    def write(key, data)
      raise NotImplementedError
    end

    def read(key)
      raise NotImplementedError
    end

    def exist?(key)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    protected

    attr_reader :namespace
  end
end
