# Configure default cache store type (:file or :mongo)
Rails.configuration.x.cache_store = :mongo # Rails.env.production? ? :mongo : :file

# Configure cache settings
Rails.configuration.x.cache_settings = {
  file: {
    path: Rails.root.join("tmp/cache")
  },
  mongo: {
    collection_prefix: Rails.env
  }
}
