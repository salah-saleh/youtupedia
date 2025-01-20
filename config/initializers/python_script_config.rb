# Configuration for Python script execution
# Defines memory and resource limits based on dyno size
module PythonScriptConfig
  # Memory Management Configuration
  #
  # Dyno Size Reference & Recommended Settings:
  # Basic (512MB):
  #   MAX_MEMORY_PER_PROCESS=460MB (90% of total)
  #   MALLOC_ARENA_MAX=2
  #   MMAP_THRESHOLD=131072
  #
  # Standard-1X (1GB):
  #   MAX_MEMORY_PER_PROCESS=920MB
  #   MALLOC_ARENA_MAX=4
  #   MMAP_THRESHOLD=262144
  #
  # Standard-2X/Performance-M (2.5GB):
  #   MAX_MEMORY_PER_PROCESS=2300MB
  #   MALLOC_ARENA_MAX=8
  #   MMAP_THRESHOLD=524288
  #
  # Performance-L (14GB):
  #   MAX_MEMORY_PER_PROCESS=12800MB
  #   MALLOC_ARENA_MAX=16
  #   MMAP_THRESHOLD=1048576

  class << self
    def script_timeout
      @script_timeout ||= 60  # seconds
    end

    def max_memory_mb
      @max_memory_mb ||= ENV.fetch("MAX_MEMORY_PER_PROCESS", 460).to_i
    end

    def malloc_arena_max
      @malloc_arena_max ||= calculate_malloc_arena_max
    end

    def mmap_threshold
      @mmap_threshold ||= calculate_mmap_threshold
    end

    private

    def calculate_malloc_arena_max
      # Formula: log2(MAX_MEMORY_MB/256), minimum 2
      [2, Math.log2(max_memory_mb / 256.0).ceil].max
    end

    def calculate_mmap_threshold
      # Formula: MAX_MEMORY_MB * 256, minimum 128KB
      [131072, max_memory_mb * 256].max
    end
  end
end 