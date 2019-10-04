require_relative "keeper.rb"

if ARGV.length != 2
    puts "Must enter 2 arguments; usage 'locker.rb username action'"
    exit
end

username = ARGV[0]
action = ARGV[1]

kpr = Keeper.new(username)

if action == 'add'
  kpr.addPassword()

elsif action == 'get'
  kpr.getPassword()

elsif action == 'create'
  kpr.createUser()

elsif action == 'purge'
  kpr.purgeUser()

elsif action == 'desc'
  kpr.seeDescriptions()

elsif action == 'delete'
  kpr.deletePassword()
else
  puts 'Not a valid action. Valid actions are [add, get, create, delete, purge]'
end
