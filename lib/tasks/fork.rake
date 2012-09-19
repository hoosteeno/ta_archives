require 'httparty'
require 'net/netrc'
require 'map'
require 'json'

namespace :site do

  desc "Forks, renames and configures the static web site"
  task :fork => %w( fork:copy fork:seppuku rename fork:bundle fork:gitify fork:complete )

  desc "Renames the site to the name provided."
  task :rename do
    puts "Renaming the site to #{site_identifier}"
    config_file = File.join(destination_folder, "data", "site.yml")
    config = File.read(config_file)
    config.gsub!(/static_site/, site_identifier)
    File.open(config_file, "w") { |f| f.write(config) }
  end

  def site_identifier
    raise ArgumentError, "You must provide a new name for the site." unless ENV['name']
    ENV['name'].gsub(/ /, '_').gsub(/[^\w\d]/, '').downcase
  end

  def repo_root
    @repo_root ||= `git rev-parse --show-toplevel`.strip
  end

  def repo_name
    @repo_name ||= `git remote -v` =~ %r{/(.+)\.git \(fetch\)} && $1
  end

  def static_site_repo
    @static_site_repo ||= Github.new(repo_name)
  end

  def new_site_repo
    @new_site_repo ||= Github.new(site_identifier)
  end

  def destination_folder
    File.expand_path("#{repo_root}/../#{site_identifier}")
  end

  class Github
    include ::HTTParty
    base_uri 'https://api.github.com'
    format :json

    attr_writer :repo_data
    attr_accessor :repo_name

    def initialize(repo_name)
      if rc = Net::Netrc.locate("github.com")
        @username = rc.login
        @password = rc.password
      else
        puts "Please enter your github username:"
        @username = STDIN.gets.chomp
        puts "Please enter your github password:"
        `stty -echo`
        @password = STDIN.gets.chomp
        `stty echo`
        puts ""
      end

      self.class.basic_auth @username, @password

      @repo_name = repo_name
    end

    def exist?
      response = self.class.get("/repos/dojo4/#{repo_name}")
      response.code != 404
    end

    def create!
      json = Map[
        :name, repo_name,
        :private, true,
        :team_id, 12290
      ]

      response = self.class.post("/orgs/dojo4/repos", body: json.to_json)

      @repo_data = Map.from_hash(response.parsed_response)
      raise "Could not create repository #{repo_name}:\n#{response['errors'].first['message']}" unless response.code == 201

      return repo_data.ssh_url
    end

    def add_campfire_hook
      options = {
        name: "campfire",
        events: ["push", "pull_request", "issues"],
        active: true,
        config: {
          token: "f9831e567f7237563baa64b90e65a135f223100f",
          room: "Roboto's House of Wonders",
          sound: "",
          subdomain: "dojo4",
          long_url: "1"
        }
      }

      response = self.class.post("/repos/dojo4/#{repo_name}/hooks", body: options.to_json)

      raise "Could not create hooks for #{repo_name}" unless response.code == 201
    end

    def destroy!
      self.class.delete("/repos/dojo4/#{repo_name}")
    end

    def ssh_url
      repo_data.ssh_url
    end

    def html_url
      repo_data.html_url
    end

    protected
    def repo_data
      @repo_data ||= begin
                      response = self.class.get("/repos/dojo4/#{repo_name}")
                      raise "Repository dojo4/#{repo_name} could not be found." if response.code == 404
                      Map.from_hash(response.parsed_response)
                     end
    end
  end

  namespace :fork do
    task :sanity_check do
      raise "You must work from a clone of the static_site repository." unless repo_name == 'static_site'
      raise "The new static site folder (#{destination_folder}) already exists." if File.exist?(destination_folder)
      raise "The #{site_identifier} repository already exists on GitHub." if new_site_repo.exist?
    end

    task :copy => :sanity_check do
      puts "Copying the project to #{destination_folder}"
      FileUtils.cp_r(repo_root, destination_folder)
    end

    task :seppuku => [:sanity_check, :copy] do
      puts "Cleaning up the metadata from the original directory..."
      FileUtils.rm_r(File.join(destination_folder, ".git"))
      FileUtils.rm_r(File.join(destination_folder, "lib", "tasks", "fork.rake"))
      FileUtils.rm_r(File.join(destination_folder, ".sass-cache")) rescue nil
      FileUtils.rm_r(File.join(destination_folder, "build")) rescue nil
    end

    task :create_repo do
      new_site_repo.create!
      new_site_repo.add_campfire_hook
    end

    task :gitify => :create_repo do
      puts "Initializing a Git repository and pushing to GitHub..."
      <<-`GITIFY`
        cd #{destination_folder}
        pwd
        git init .
        git add .
        git remote add origin #{new_site_repo.ssh_url}
        git commit -m "Initial commit of #{site_identifier}"
        git push -u origin master
      GITIFY
    end

    task :bundle => :copy do
      puts "Running bundle install..."
      <<-`BUNDLE`
        cd #{destination_folder}
        bundle install
      BUNDLE
    end

    task :complete do
      puts <<EOD
#{site_identifier} has been setup and is now ready to be worked on.
The workspace is located at: #{destination_folder}
The GitHub repository is located at: #{new_site_repo.html_url}
EOD
    end

    desc "Cleans up behind us. Useful for hacking on this"
    task :clean_up do
      `rm -rf #{destination_folder}`
      new_site_repo.destroy!
    end
  end
end
