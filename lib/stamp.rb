class Stamp
  attr_accessor :stamp_number, :stamp_name

  def self.path
    File.join(Settings.stamp_path, Settings.env)
  end

  def self.push(stamp_name=nil)
    new(stamp_name).run
  end

  def self.clear
    Dir[File.join(Settings.stamp_path, Settings.env, '*')].each do |path|
      FileUtils.rm_r(path)
    end
  end

  def initialize(stamp_name=nil)
    @stamp_number = Time.now.strftime('%Y%m%d%H%M%S')
    @stamp_name = stamp_name || ActiveRecord::Base.connection.current_database
  end

  def run
    output(stamps)
  end

  private

  def stamp_path
    @stamp_path  ||= File.join(Settings.stamp_path, Settings.env, stamp_number)
  end

  def stamp_file
    @stamp_file ||= File.join(stamp_path, stamp_name)
  end

  def output(data)
    FileUtils.mkdir_p(stamp_path)

    File.open(stamp_file, 'wb') do |f|
      f.puts(data)
    end
  end

  def tables
    ActiveRecord::Base.connection.tables.reject do |table|
      Settings.ignore_tables.include?(table)
    end
  end

  def stamps
    tables.each_with_object({}) do |table, obj|
      obj[table] = ActiveRecord::Base.connection.select_all(
          <<-"SQL"
          SELECT
            *
          FROM
            #{table}
          SQL
        ).to_a
    end.to_json
  end
end
