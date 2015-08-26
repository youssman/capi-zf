# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'my-app'
set :repo_url, 'git@my-domain:my-app'
set :user, 'deploy'
set :scm, :git
set :shared_path, '#{deploy_to}/shared'
set :keep_releases, 3
set :log_level, :info

namespace :deploy do
    desc "Create a symlink between pub dir and apache web dir"
    task :create_symlink do
        on roles(:app) do
            execute "ln -sf #{deploy_to}/current/public #{deploy_to}/"
            info "Created relative current symlink"
        end
    end

    desc "Create a symlink for uploaded images"
    task :create_images_symlink do
        on roles(:app) do
            execute "mkdir -p #{shared_path}/uploads"
            execute "ln -sf #{shared_path}/uploads #{release_path}/public/"
            info "Created uploaded images symlink"
        end
    end

    desc "checks whether the currently checkout out revision matches the
    remote one we're trying to deploy from"
    task :check_revision do
        branch = fetch(:branch)
        unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
          puts "WARNING: HEAD is not the same as origin/#{branch}"
          puts "Run `git push` to sync changes or make sure you've"
          puts "checked out the branch: #{branch} as you can only deploy"
          puts "if you've got the target branch checked out"
          exit
      end
  end

  desc "Check that we can access everything"
  task :check_write_permissions do
    on roles(:all) do |host|
      if test("[ -w #{fetch(:deploy_to)} ]")
            info "#{fetch(:deploy_to)} is writable on #{host}"
        else
            error "#{fetch(:deploy_to)} is not writable on #{host}"
        end
    end
    end

    desc "A task to mark the end of the deploy process"
    task :everything_ok do
        on roles(:app) do
           info "\e[0;32m ✔ \033[0m Congrats, everything seems to be OK ! \e[0;32m"
       end
    end

    desc "Grant authorization to the cache dir for all user"
    task :cache_permission do
        on roles(:app) do
          execute "chmod -R o+rwX #{release_path}/cache"
      end
    end

    desc "Composer stuff"
    task :composer do
        on roles(:app) do
            run "cd #{release_path} && /usr/bin/php composer.phar install && /usr/bin/php composer.phar dump-autoload --optimize"
        end
    end

end

after "deploy:published", "deploy:composer"
after "deploy:composer", "deploy:create_symlink"

after "deploy:create_symlink", "deploy:create_images_symlink"

after "deploy:finishing","deploy:everything_ok"
