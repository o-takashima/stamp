#ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
env = Settings.env.to_sym

ActiveRecord::Base.configurations = { env => Settings.database.to_h }
ActiveRecord::Base.establish_connection(env)
