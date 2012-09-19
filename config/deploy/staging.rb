identifier = fetch(:identifier)

set :application, identifier
set :repository,  "git@github.com:dojo4/#{ identifier }.git"
set :user, "dojo4"
set :deploy_to, "/ebs/sites/#{ identifier }"

set :scm, :git
set :deploy_via, :remote_cache

# be sure to run 'ssh-add' on your local machine
system "ssh-add 2>&1" unless ENV['NO_SSH_ADD']
ssh_options[:forward_agent] = true

set :deploy_via, :remote_cache
set :branch, "master" unless exists?(:branch)
set :use_sudo, false

ip = "d0.dojo4.com"
role :web, ip                          # Your HTTP server, Apache/etc
role :app, ip                          # This may be the same as your `Web` server
role :db,  ip, :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

set(:url, "http://#{ identifier }.development.dojo4.com")
