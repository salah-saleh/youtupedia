module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # Allow both authenticated and anonymous viewers to connect.
      # Summaries are public; websockets are used for live UI updates.
      set_current_user
    end

    private
      def set_current_user
        if (session = Session.find_by(id: cookies.signed[:session_id]))
          self.current_user = session.user
        else
          self.current_user = nil
        end
      end
  end
end
