require "pg"
require "micrate"
require "dotenv"

Dotenv.load
DATABASE_URL = ENV["DATABASE_URL"]

class Clear::CLI::Migration < Admiral::Command
  include Clear::CLI::Command

  define_help description: "Manage migration state of your database"

  class Status < Admiral::Command
    include Clear::CLI::Command

    define_help description: "Return the current state of the database"

    def run_impl
      puts Clear::Migration::Manager.instance.print_status
    end
  end

  class Seed < Admiral::Command
    include Clear::CLI::Command

    define_help description: "Call the seeds data"

    def run_impl
      Clear.apply_seeds
    end
  end

  class Create < Admiral::Command
    include Clear::CLI::Command

    private def create_db_and_init
      Dotenv.load
      Micrate::DB.connection_url = ENV["DATABASE_CREATE_URL"]
      url = DATABASE_URL
      name = set_database_to_schema url
      Micrate::DB.connect do |db|
        db.exec "CREATE DATABASE #{name};"
      end
      puts "Created database #{name}"
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
    end

    private def set_database_to_schema(url)
      uri = URI.parse(url)
      if path = uri.path
        Micrate::DB.connection_url = url.gsub(path, "/#{uri.scheme}")
        uri.path.gsub("/", "")
      else
        puts "Could not determine database name"
        exit
      end
    end
    define_help description: "Create database"
    
    def run_impl
      self.create_db_and_init
    end
  end

  class Delete < Admiral::Command
    include Clear::CLI::Command
    define_help description: "Delete database"

    def run_impl

    end
  end

  class Up < Admiral::Command
    include Clear::CLI::Command

    define_argument migration_number : Int64, required: true
    define_help description: "Upgrade your database to a specific migration version"

    def run_impl
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
      Clear::Migration::Manager.instance.up arguments.migration_number
    end
  end

  class Down < Admiral::Command
    include Clear::CLI::Command

    define_argument migration_number : Int64, required: true
    define_help description: "Downgrade your database to a specific migration version"

    def run_impl 
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
      Clear::Migration::Manager.instance.down arguments.migration_number
    end
  end

  class Set < Admiral::Command
    include Clear::CLI::Command

    define_flag direction : String, short: d, default: "both"
    define_argument to : Int64, required: true

    def run_impl
      dir_symbol = case flags.direction
                   when "up"
                     :up
                   when "down"
                     :down
                   when "both"
                     :both
                   else
                     puts "Bad argument --direction : #{flags.direction}. Must be up|down|both"
                     exit 1
                   end

      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
      Clear::Migration::Manager.instance.apply_to(arguments.to, direction: dir_symbol)
    end
  end

  class Migrate < Admiral::Command
    include Clear::CLI::Command

    def run_impl
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
      Clear::Migration::Manager.instance.apply_all
    end
  end

  class Rollback < Admiral::Command
    include Clear::CLI::Command

    define_help description: "Rollback the last up migration"
    define_argument num : Int64

    def run_impl
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
      array = Clear::Migration::Manager.instance.migrations_up.to_a.sort
      num = if arguments.num.nil?
              2
            else
              arguments.num.not_nil!.to_i + 1
            end

      if (num > array.size)
        num = array.size - 1
      end

      Clear::Migration::Manager.instance.apply_to(
        array[-num],
        direction: :down)
    end
  end

  register_sub_command status, type: Status
  register_sub_command up, type: Up
  register_sub_command down, type: Down
  register_sub_command set, type: Set
  register_sub_command rollback, type: Rollback
  register_sub_command migrate, type: Migrate
  register_sub_command seed, type: Seed
  register_sub_command create, type: Create
  #register_sub_command delete type: Delete

  def run_impl
      begin
        Clear::SQL.init(DATABASE_URL)
      rescue DB::ConnectionRefused
        puts "FATAL: Connection to the database (#{DATABASE_URL}) has been refused"
        exit
      end
    Clear::Migration::Manager.instance.apply_all
  end
end
