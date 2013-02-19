if %w(staging production).include? PADRINO_ENV || ENV["USE_REDIS_FAILOVER"]
  redis_failover_config = YAML.load_file(Padrino.root + 'config/redis_failover.yml')[PADRINO_ENV]
  $redis = RedisFailover::Client.new(redis_failover_config.symbolize_keys) do |client|
    client.on_node_change do |master, slaves|
      Padrino::logger.info("Nodes changed! master: #{master}, slaves: #{slaves}")
    end
  end
else #Use normal Redis

  redis_config = YAML.load_file(Padrino.root("config", "redis.yml"))[PADRINO_ENV]

  # Connect to Redis using the redis_config host and port
  if redis_config
    opts = {host: redis_config['host'], port: redis_config['port'], db:redis_config['db']}

    if PADRINO_ENV == "development"
      opts[:logger] = Padrino::logger
    end

    $redis = Redis.new(opts)
  else
    Padrino::logger.fatal "No Redis config detected!"
  end
end

