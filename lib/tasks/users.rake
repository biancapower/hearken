require "io/console"

namespace :users do
  desc "Create an account, prompting for the email address and password"
  task create: :environment do
    # Prompting keeps the password out of shell history and process lists.
    read_secret = lambda do |prompt|
      print prompt
      secret = $stdin.respond_to?(:noecho) && $stdin.tty? ? $stdin.noecho(&:gets) : $stdin.gets
      puts
      secret.to_s.chomp
    end

    print "Email address: "
    email_address = $stdin.gets.to_s.strip
    password = read_secret.call("Password: ")
    abort "The passwords don't match." unless read_secret.call("Password again: ") == password

    user = User.create(email_address: email_address, password: password)
    abort user.errors.full_messages.to_sentence unless user.persisted?
    puts "Created #{user.email_address}."
  rescue ActiveRecord::RecordNotUnique
    abort "An account with that email address already exists."
  end
end
