# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server "example.com", user: "deploy", roles: %w{app db web}, my_property: :my_value
# server "example.com", user: "deploy", roles: %w{app web}, other_property: :other_value
# server "db.example.com", user: "deploy", roles: %w{db}



# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

role :web, %w{growth@nb3.healthtap.com}
role :db, %w{growth@nb3.healthtap.com}


# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
server 'nb3.healthtap.com', user: 'growth', roles: %w{web db}
#   ssh_options: {
#     user: "user_name", # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: "please use keys"
#   }

set :deploy_to, '/home/growth/guest-api-qa.healthtap.com'
set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{log tmp/pids}

set :unicorn_config_path, "#{deploy_to}/current/config/unicorn/qa.rb"
set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"
set :unicorn_roles, %w{web}
set :unicorn_rack_env, 'development'
set :default_env, rack_env: 'qa'
set :branch, 'master'

# Unicorn control tasks
namespace :deploy do
  task :restart do
    invoke 'unicorn:restart'
  end
  task :start do
    invoke 'unicorn:start'
  end
  task :stop do
    invoke 'unicorn:stop'
  end
end
