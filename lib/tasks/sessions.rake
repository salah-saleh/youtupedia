namespace :sessions do
  desc 'Clean up expired sessions'
  task cleanup: :environment do
    count = Session.where('expires_at < ?', Time.current).destroy_all.count
    puts "Cleaned up #{count} expired sessions"
  end
end
