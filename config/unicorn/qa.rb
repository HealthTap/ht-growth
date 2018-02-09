# define paths and filenames
deploy_to = '/home/growth/guest-api-qa.healthtap.com'
app_root = "#{deploy_to}/current"
pid_file = "#{app_root}/tmp/pids/unicorn.pid"
socket_file= "#{deploy_to}/shared/unicorn.sock"
log_file = "#{app_root}/log/unicorn.log"
err_log = "#{app_root}/log/unicorn_error.log"
old_pid = pid_file + '.oldbin'

timeout 200
worker_processes 4 # increase or decrease
listen socket_file, :backlog => 512

pid pid_file
stderr_path err_log
stdout_path log_file

# make forks faster
preload_app true

# make sure that Bundler finds the Gemfile
before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "#{deploy_to}/current/Gemfile"
end

before_fork do |server, _worker|
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)

  # zero downtime deploy magic:
  # if unicorn is already running, ask it to start a new process and quit.
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |_server, _worker|
  # re-establish activerecord connections.
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
end
