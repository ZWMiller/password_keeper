require "json"
require "openssl"
require "encrypted_strings"

class Keeper
  ##
  # Class that manages all of the I/O and encryption for creating a password keeper
  # The general idea is that the master password is used as the encryption key
  # and never stored. The encrypted non-master passwords are never stored in plain
  # text. The description for the passwords is also encrypted and stored.
  # A "user" is simply a hidden JSON file that stores encrypted user, password
  # combinations. 
  # All actions in this class are based on manipulation of those encrypted hashes.

  def initialize(username)
    ##
    # On creation, sets the username and the expected hidden file locations
    @username = username
    @connection = ".#{username}.kpr"
  end

  def createUser()
    ##
    # Checks to see if the user exists already in the hidden files
    # If yes, do nothing
    # If no, create a hidden file for this user
    if not File.file?(@connection)
      temp = {}
      File.open(@connection, "w") do |f|
        f.write(temp.to_json)
      end
    end
  end

  def checkFile(username)
    ##
    # Run a check to see if this is a known user by looking for
    # a user file
    if not File.file?(@connection)
      puts "#{username} is not a known user. If new user, use action = 'create'"
      return false
    end
    true
  end

  def addPassword()
    ##
    # Take a description and password combination, encrypt them, and
    # add them to a user's record. 
    if not checkFile(@username)
      exit
    end

    puts "Enter Pass Description:"
    desc = STDIN.gets.chomp

    puts "Enter Pass:"
    pwd = STDIN.gets.chomp
    
    puts "Enter Master Pass:"
    mpwd = STDIN.gets.chomp

    enc_pwd = pwd.encrypt(:symmetric, :password => mpwd)
    enc_desc = desc.encrypt(:symmetric, :password => mpwd)

    current_pwds = JSON.parse File.read(@connection)
    current_pwds[enc_desc] = enc_pwd

    File.open(@connection,"w") do |f|
      f.write(current_pwds.to_json)
    end
  end
  
  def getPassword()
    ##
    # Take a desciption and master password, encrypt the description and see
    # if it matches to a key in the record for the user. If yes, then return
    # the unencrpyted version of the password. This makes sure we never make 
    # available the unencrpyted description if the master pass is wrong.
    if not checkFile(@username)
      exit
    end

    puts "Enter Pass Description:"
    desc = STDIN.gets.chomp

    puts "Enter Master Pass:"
    mpwd = STDIN.gets.chomp

    enc_desc = desc.encrypt(:symmetric, :password => mpwd)
    current_pwds = JSON.parse File.read(@connection)
    
    if current_pwds.key?(enc_desc)
      enc_pwd = current_pwds[enc_desc]
      puts enc_pwd.decrypt(:symmetric, :password=>mpwd)
    else
      puts 'Either description or Master Pass is wrong'
    end
  end

  def deletePassword()
    ##
    # Provide a description and master password. If the encrypted description
    # matches with a description in the user's record, remove that description
    # and password pair from the record
    if not checkFile(@username)
      exit
    end

    puts "Enter Pass Description:"
    desc = STDIN.gets.chomp

    puts "Enter Master Pass:"
    mpwd = STDIN.gets.chomp

    enc_desc = desc.encrypt(:symmetric, :password => mpwd)
    current_pwds = JSON.parse File.read(@connection)
    
    if current_pwds.key?(enc_desc)
      current_pwds.delete(enc_desc)
    
      File.open(@connection,"w") do |f|
        f.write(current_pwds.to_json)
      end
    else
      puts "Either description or Master Pass is wrong"
    end
  end

  def purgeUser()
    ##
    # If a purge is requested, make sure and then delete the record for that user.
    if not checkFile(@username)
      exit
    end
    puts "Are you sure? Must type 'Yes' to confirm"
    confirm = STDIN.gets.chomp
    if confirm == "Yes"
      puts "Deleting record for user #{@username}"
      File.delete(@connection) if File.exist?(@connection)
    end
  end
end

