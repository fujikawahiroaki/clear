require "generate"

class Clear::CLI::Generator
  register_sub_command "new:grip", type: NewGrip, description: "Create a new project with Grip"

  class NewGrip < Admiral::Command
    include Clear::CLI::Command

    define_flag directory : String,
      default: ".",
      long: directory,
      short: d,
      description: "Set target directory"

    define_argument name : String

    def run_impl
      g = Generate::Generator.new

      g.target_directory = flags.directory
      g["app_name"] = arguments.name || File.basename(g.target_directory)

      g["app_name_underscore"] = g["app_name"].underscore
      g["app_name_camelcase"] = g["app_name"].camelcase

      g["git_username"] = `git config user.email`.chomp || "email@example.com"
      g["git_email"] = `git config user.name`.chomp || "Your Name"

      g.in_directory "bin" do
        g.file "appctl", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/bin/appctl.ecr", g)
        g.file "clear_cli.cr", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/bin/clear_cli.cr.ecr", g)
        g.file "server.cr", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/bin/server.cr.ecr", g)
      end

      g.in_directory "config" do
        g.file "database.yml", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/config/database.yml.ecr", g)
      end

      g.in_directory "src" do
        g.in_directory "controllers" do
        end

        g.in_directory "db" do
          g.file "init.cr", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/src/db/init.ecr", g)
        end

        g.in_directory "models" do
          g.file "init.cr", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/src/models/application_model.ecr", g)
        end

        g.file "app.cr", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/src/app.ecr", g)
      end

      g.file ".gitignore", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/_gitignore.ecr", g)
      g.file "shard.yml", Clear::CLI::Generator.ecr_to_s("#{__DIR__}/../../../../../templates/grip/shard.yml.ecr", g)

      system("chmod +x #{g.target_directory}/bin/appctl")
      system("cd #{g.target_directory} && shards")

      puts "Clear + Grip template is now generated. `cd #{g.target_directory} && clear-cli server` to play ! :-)"
    end
  end
end

# Clear::CLI::Generator.add("new/grip",
#   "Setup a minimal application with grip and clear") do |args|

# end
