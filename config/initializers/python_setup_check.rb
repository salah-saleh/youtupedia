Rails.application.config.after_initialize do
  if Rails.env.development?
    python_path = ENV["PYTHON_PATH"]
    Rails.root.join("requirements.txt")

    unless File.exist?(Rails.root.join("venv"))
      Rails.logger.error "Python virtual environment not found. Please run bin/setup"
      raise "Python environment not configured. Run bin/setup first."
    end

    unless system("#{python_path} -c 'import google.generativeai'")
      Rails.logger.error "Required Python packages not installed. Please run bin/setup"
      raise "Python dependencies missing. Run bin/setup first."
    end
  end
end
