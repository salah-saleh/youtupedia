# Provides standardized data persistence functionality across all services
# Uses MongoDB as the primary data store with consistent API
#
# Usage:
#   class MyService < BaseService
#     include Persistable
#
#     def self.fetch_data(key)
#       fetch_stored(key) do
#         # Generate data logic here
#         { success: true, data: "some_data" }
#       end
#     end
#   end
module Persistable
  extend ActiveSupport::Concern

  class_methods do
    # Fetches data from storage or generates it using the provided block
    # Uses the service's default storage namespace for isolation
    #
    # @param key [String] Storage key
    # @param namespace [String, nil] Optional custom namespace (defaults to service namespace)
    # @param force_block_execution [Boolean] If true, skip storage and execute block
    # @yield Block to generate data if not in storage
    # @return [Hash] The stored or generated data
    def fetch_stored(key, namespace: nil, force_block_execution: false, &block)
      storage_namespace = namespace || default_storage_namespace
      storage_service(storage_namespace).fetch(key, force_block_execution: force_block_execution, &block)
    end

    # Writes data directly to storage
    # Useful for explicit storage updates after processing
    #
    # @param key [String] Storage key
    # @param data [Hash] Data to store
    # @param namespace [String, nil] Optional custom namespace (defaults to service namespace)
    # @return [Hash] The stored data
    def write_stored(key, data, namespace: nil)
      storage_namespace = namespace || default_storage_namespace
      storage_service(storage_namespace).write(key, data)
      data
    end

    # Reads data from storage without fallback
    # Returns nil if key doesn't exist
    #
    # @param key [String] Storage key
    # @param namespace [String, nil] Optional custom namespace (defaults to service namespace)
    # @return [Hash, nil] Stored data or nil
    def read_stored(key, namespace: nil)
      storage_namespace = namespace || default_storage_namespace
      storage_service(storage_namespace).read(key)
    end

    # Checks if key exists in storage
    #
    # @param key [String] Storage key
    # @param namespace [String, nil] Optional custom namespace (defaults to service namespace)
    # @return [Boolean] True if key exists
    def stored?(key, namespace: nil)
      storage_namespace = namespace || default_storage_namespace
      storage_service(storage_namespace).exist?(key)
    end

    # Deletes a key from storage
    #
    # @param key [String] Storage key
    # @param namespace [String, nil] Optional custom namespace (defaults to service namespace)
    def delete_stored(key, namespace: nil)
      storage_namespace = namespace || default_storage_namespace
      storage_service(storage_namespace).delete(key)
    end

    private

    # Gets or creates a storage service instance for the given namespace
    # Caches instances to avoid repeated MongoDB connections
    #
    # @param namespace [String] Storage namespace
    # @return [Storage::MongoStorageService] Storage service instance
    def storage_service(namespace)
      @storage_services ||= {}
      @storage_services[namespace] ||= Storage::MongoStorageService.new(namespace)
    end

    # Returns the default storage namespace for this service
    # Uses the service class name to create an isolated namespace
    #
    # @return [String] Default storage namespace
    def default_storage_namespace
      name.demodulize.underscore.pluralize
    end
  end
end
