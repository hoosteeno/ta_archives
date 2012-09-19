namespace :site do
  desc "Deploys static site to staging"
  task :deploy do
    system 'cap staging deploy:setup'
    system 'cap staging deploy'
  end

  desc "Runs the Middleman server"
  task :server do
    system 'middleman server'
  end

  desc "Builds the Middle man site"
  task :build do
    system 'middleman build'
  end
end
