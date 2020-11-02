# stamp 同士を比較して差分を抽出するクラス
# Overlabp.compare!(a, b)
#
class Overlap

  # dbダンプを比較
  def self.compare(stamp_a, stamp_b)
    new(stamp_a, stamp_b).compare_db
  rescue => e
    { error: e.message }
  end

  # ログを比較
  def self.compare_log(stamp_a, stamp_b)
    new(stamp_a, stamp_b).compare_log
  rescue => e
    { error: e.message }
  end

  # 比較元と比較先のパスを初期化
  def initialize(stamp_a, stamp_b)
    @stamp_a = number_to_path(stamp_a)
    @stamp_b = number_to_path(stamp_b)
    @log_a   = number_to_log_path(stamp_a)
    @log_b   = number_to_log_path(stamp_b)
    @differences = {}
  end

  # dbダンプを比較
  def compare_db
    return nil if @stamp_a.blank? || @stamp_b.blank?

    tables.each do |table|
      compare(table)
    end

    @differences
  end

  # ログを比較
  # ANSIカラーコードをHTMLに変換
  # 改行は<br>に置換
  def compare_log
    return nil if @log_a.blank? || @log_b.blank?

    log_a = File.read(@log_a)
    log_b = File.read(@log_b)

    Ansi::To::Html.new(log_b.sub(log_a, '')).to_html.gsub(/\n/, '<br>')
  end

  private

  def tables
    @tables ||= ActiveRecord::Base.connection.tables.reject do |table|
      Settings.ignore_tables.include?(table)
    end
  end

  # 選択番号からパスを取得
  def number_to_path(stamp_number)
    return unless stamp_number

    Dir[File.join(Settings.stamp_path, Settings.env, stamp_number, '*')].first
  end

  # 選択番号からログのパスを取得
  def number_to_log_path(stamp_number)
    return unless stamp_number

    File.join(Settings.stamp_path, Settings.env, 'logs', "#{stamp_number}.log")
  end

  # 比較元ダンプHash
  def before
    @before ||= JSON.parse(File.open(@stamp_a).read)
  end

  # 比較先ダンプ
  def after
    @after ||= JSON.parse(File.open(@stamp_b).read)
  end

  def compare(table)
    # drop table や create tableされることは想定外
    before_attrs = before[table]
    after_attrs  = after[table]

    before_ids = before_attrs.map{|attr| attr["id"] }
    after_ids  = after_attrs.map{|attr| attr["id"] }

    # 登録されたIDリスト
    created_ids = after_ids - before_ids
    # 削除されたIDリスト
    deleted_ids = before_ids - after_ids
    # 変更されたIDリスト
    updated_ids = (after_attrs - before_attrs).reject do |attr|
      # 新規登録レコードは除外
      created_ids.include?(attr["id"])
    end.map{|attr| attr["id"] }

    # 登録/削除/変更いずれもなし
    return if deleted_ids.blank? && created_ids.blank? && updated_ids.blank?

    # 新規レコード
    new_records = created_ids.map do |id|
      after_attrs.find{|attr| attr["id"] == id }
    end

    # 編集レコード
    updated_records = updated_ids.map do |id|
      after_attr    = after_attrs.find{|attr|  attr["id"] == id}.to_a
      before_attr   = before_attrs.find{|attr| attr["id"] == id}.to_a
      # 変更跡のカラム名と値のセット
      after_values  = Hash[after_attr - before_attr]
      # 変更前のカラム名と値のセット
      before_values = Hash[before_attr - after_attr]
      # { id: X, change_column_name_A: { from: "xxx", to: "yyy" }, change_column_name_B: { from: "aaa", to: "bbb" } }, { id: Y, ...
      before_values.keys.each_with_object({ "id" => { from: id, to: nil } }) do |key, obj|
        obj[key] = { from: before_values[key], to: after_values[key] }
      end
    end

    result = { table => {} }
    result[table]["deleted_ids"]     = deleted_ids     if deleted_ids.present?
    result[table]["new_records"]     = new_records     if new_records.present?
    result[table]["updated_records"] = updated_records if updated_records.present?

    @differences.merge!(result)
  end
end
