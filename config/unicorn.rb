# -*- coding: utf-8 -*-
#unicorn -c /${rails_root}/config/unicorn.conf -E production -D
# safe shutdown: kill -QUIT
# force shutdown: kill -INT
# reload: kill -HUP
# after deploy: kill -USR2

def cpucore_count
  case RbConfig::CONFIG['host_os']
  when /darwin/
    ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
  when /linux/
    `cat /proc/cpuinfo | grep processor | wc -l`.to_i
  else
    warn "this os is not supported"
    2
  end
end

APP_ROOT = "/var/24log/push_to_devices"
env = ENV['RACK_ENV'] || 'production'

pid '/tmp/push_to_devices.pid'

#PWD
working_directory APP_ROOT

listen '/tmp/push_to_devices.sock', :backlog => 2048

worker_processes 2

stdout_path "#{APP_ROOT}/unicorn.log"
stderr_path "#{APP_ROOT}/unicorn.log"

#30秒以上処理しているワーカーは再起動
timeout 30

#ワーカーをforkする前にアプリを読み込み
preload_app  true

#RubyEnterpriseEdition用(ねんのため
if GC.respond_to?(:copy_on_write_friendly=)
   GC.copy_on_write_friendly = true
end

before_exec do |server|
  puts "before exec proc start.."

  # Fixing gemfile not found error
  ENV["BUNDLE_GEMFILE"] = "#{APP_ROOT}/Gemfile"
  puts "Gemfile path: #{ENV["BUNDLE_GEMFILE"]}"
end

before_fork do |server, worker|
  puts "before fork proc start.."

  # by way of precaution
  ENV["BUNDLE_GEMFILE"] = "#{APP_ROOT}/Gemfile"
  puts "Gemfile path: #{ENV["BUNDLE_GEMFILE"]}"

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  sleep 1
end
