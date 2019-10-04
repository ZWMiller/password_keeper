$VERBOSE = nil
require 'io/console'
require "json"
require "openssl"
require "encrypted_strings"
require "clipboard"

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
    base_url = loadConfig()['base_url']
    @connection = "#{base_url}/.#{username}.kpr"
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
    pwd = STDIN.noecho(&:gets).chomp

    puts "Enter Pass Again:"
    pwd2 = STDIN.noecho(&:gets).chomp

    if pwd != pwd2
      puts "Passwords didn't match, failing out"
      exit
    end
    puts "Enter Master Pass:"
    mpwd = STDIN.noecho(&:gets).chomp

    enterIntoRecord(pwd, desc, mpwd)
  end

  def generatePassword()
    ##
    # Take a description, generate an alphanumeric password, encrypt them, and
    # add them to a user's record. 
    if not checkFile(@username)
      exit
    end

    puts "Enter Pass Description:"
    desc = STDIN.gets.chomp

    pwd = [*('a'..'z'),*('0'..'9')].shuffle[0,15].join

    puts "Enter Master Pass:" 
    mpwd = STDIN.noecho(&:gets).chomp

    enterIntoRecord(pwd, desc, mpwd)
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
    mpwd = STDIN.noecho(&:gets).chomp

    enc_desc = desc.encrypt(:symmetric, :password => mpwd)
    current_pwds = JSON.parse File.read(@connection)

    if current_pwds.key?(enc_desc)
      enc_pwd = current_pwds[enc_desc]
      puts ''
      puts 'Copying password to clipboard'
      Clipboard.copy(enc_pwd.decrypt(:symmetric, :password=>mpwd))
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
    mpwd = STDIN.noecho(&:gets).chomp

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

  def seeDescriptions()
    ##
    # For a given user and master password, show what each key 
    # decrypts to. If you use the same master-password for everything
    # they'll all show you their correct descriptions. If you didn't
    # you'll see garbage decrypts
    if not checkFile(@username)
      exit
    end

    puts "Enter Master Pass (will only show descriptions from this master pass):"
    mpwd = STDIN.noecho(&:gets).chomp
    puts "\nAvailable Descriptions: \n"

    current_pwds = JSON.parse File.read(@connection)

    current_pwds.each { |key, value|
      begin
        enc_desc = key.decrypt(:symmetric, :password => mpwd)
        puts enc_desc
      rescue
        nil
      end
    }
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

  private
  def enterIntoRecord(pwd, desc, mpwd)
    enc_pwd = pwd.encrypt(:symmetric, :password => mpwd)
    enc_desc = desc.encrypt(:symmetric, :password => mpwd)

    current_pwds = JSON.parse File.read(@connection)
    current_pwds[enc_desc] = enc_pwd

    File.open(@connection,"w") do |f|
      f.write(current_pwds.to_json)
    end
  end

  def loadConfig()
    JSON.parse File.read("config.cfg")
  end
end

