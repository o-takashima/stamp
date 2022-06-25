class Stamp
  attr_accessor :stamp_number, :stamp_name

  # 環境ごとのファイル保存先
  def self.path
    File.join(Settings.stamp_path, Settings.env)
  end

  # スタンプ追加
  def self.push(stamp_name=nil)
    new(stamp_name).run
  end

  # スタンプをクリア
  def self.clear
    Dir[File.join(path, '*')].each do |path|
      FileUtils.rm_r(path)
    end

    File.truncate("/app/log", 0)
  end

  def initialize(stamp_name=nil)
    @stamp_number = Time.now.strftime('%Y%m%d%H%M%S')
    @stamp_name = stamp_name || ActiveRecord::Base.connection.current_database
  end

  def run
    # 現在のDBダンプをスタンプ
    FileUtils.mkdir_p(stamp_path)
    output(stamps, stamp_file)

    # ログの末尾にマーク
    File.open("/app/log", "ab") do |f|
      f.puts log_stamp
    end
  end

  private

  # スタンプを保存するパス
  def stamp_path
    @stamp_path  ||= File.join(self.class.path, stamp_number)
  end

  def log_stamp(sn=nil)
    [sn || stamp_number, log_separator ].join()
  end

  def log_separator
    "-"*100
  end

  # スタンプしたファイル
  def stamp_file
    @stamp_file ||= File.join(stamp_path, stamp_name)
  end

  # dataをpathに書き出す
  def output(data, path)
    File.open(path, 'wb') do |f|
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
