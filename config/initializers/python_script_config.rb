# Configuration for Python script execution
# Defines memory and resource limits
module PythonScriptConfig


  class << self
    def script_timeout
      @script_timeout ||= ENV.fetch("PYTHON_SCRIPT_TIMEOUT", 60).to_i  # seconds
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

    def python_path
      @python_path ||= ENV.fetch("PYTHON_PATH", "python3")
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