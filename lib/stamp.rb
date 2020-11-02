class Stamp
  attr_accessor :stamp_number, :stamp_name

  # 環境ごとのファイル保存先
  def self.path
    File.join(Settings.stamp_path, Settings.env)
  end

  # ログの差分打消用エントリーログ
  def self.entry_path
    File.join(Settings.stamp_path, 'entry_log')
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
  end

  # 現在のログをエントリーポイントとして保存
  def self.log_entry!
    new.log_entry!
  end

  def initialize(stamp_name=nil)
    @stamp_number = Time.now.strftime('%Y%m%d%H%M%S')
    @stamp_name = stamp_name || ActiveRecord::Base.connection.current_database
  end

  def run
    # 現在のDBダンプをスタンプ
    FileUtils.mkdir_p(stamp_path)
    output(stamps, stamp_file)

    # .envで指定したlog_fileがなければ終わり
    return unless (Settings.log_file && File.exists?(Settings.log_file))

    # 現在のログをスタンプ
    FileUtils.mkdir_p(log_path)
    output(logs, log_file)
  ensure
    FileUtils.rm_f(Stamp.entry_path)
  end

  def log_entry!
    output(File.read(Settings.log_file), Stamp.entry_path)
  end

  private

  # スタンプを保存するパス
  def stamp_path
    @stamp_path  ||= File.join(self.class.path, stamp_number)
  end

  # ログをコピーするパス
  def log_path
    @log_path  ||= File.join(self.class.path, 'logs')
  end

  # スタンプしたファイル
  def stamp_file
    @stamp_file ||= File.join(stamp_path, stamp_name)
  end

  # コピーしたログファイル
  def log_file
    @log_file ||= File.join(log_path, "#{stamp_number}.log")
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

  def logs
    File.read(Settings.log_file).sub(entry_log, '')
  end

  def entry_log
    return '' unless File.exists?(Stamp.entry_path)

    File.read(Stamp.entry_path)
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
