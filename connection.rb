#ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
ActiveRecord::Base.configurations = Hash[Settings.database]
ActiveRecord::Base.establish_connection(:development)
