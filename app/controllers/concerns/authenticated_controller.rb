module AuthenticatedController
  extend ActiveSupport::Concern

  included do
    include Authentication
    before_action :authenticate!
    layout "dashboard"
  end
end
