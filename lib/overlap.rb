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

  attr_reader :log_rows, :queries
  # 比較元と比較先のパスを初期化
  def initialize(stamp_a, stamp_b)
    @stamp_a = number_to_path(stamp_a)
    @stamp_b = number_to_path(stamp_b)
    @stamp_number_a   = stamp_a
    @stamp_number_b   = stamp_b
    @log_rows = nil
    @differences = {}
    @queries = {}
  end

  # dbダンプを比較
  def compare_db
    return nil if @stamp_a.blank? || @stamp_b.blank?

    tables.each do |table|
      compare(table)
    end

    @differences
  end

  # ログを出力
  # ANSIカラーコードをHTMLに変換してテーブル化
  # カスタムしたログだとうまく表示されないかも
  def compare_log
    log = File.read("/app/log").match(/#{@stamp_number_a}.+#{@stamp_number_b}/m).to_s

    log_rows = log.split("\n").map do |line|
      next if line.strip.blank? # 空行は除外

      html = Ansi::To::Html.new(line).to_html

      html_to_table_row(html) # <tr>で囲う</tr>
    end.compact # nilもあるのでcompact

    @log_rows = log_rows

    self
  end

  private

  def html_to_table_row(html)
    return query_row(html)  if html.match?("<b>.*?</b>")
    return action_row(html) if html.match?(/Started.+?for.*$/)
    return caller_row(html) if html.match?(/↳.+?\.rb.*/)

    other_row(html)
  end

  def query_row(html)
    _, query = html.match(/<b><span.*?>(.+?)<\/span><\/b>.*?<b><span.*?>(.+?)<\/span><\/b>/) { [$1, $2] }

    @queries[query] = (@queries[query] || 0) +1

    <<~HTML
      <tr>
        <td class='log_td1'>
          #{html.gsub(/<\/b>[ ]*?<b>/, "</b></td><td class='log_td2'><b>")}
        </td>
      </tr>
    HTML
  end

  def action_row(html)
    <<~HTML
      <tr>
        <td colspan=2 class='log_td' style='background-color: #353535; color: #ffffff'>
          #{
             html.sub(/(Started.+?)(for.*)/) do
              "<span style='font-weight: bold'>#{$1}</span>#{$2}"
             end
          }
        </td>
      </tr>
    HTML
  end

  def caller_row(html)
    path, line_num = html.match("([a-zA-Z0-9\/_].+?\.rb):([0-9]+)") { [$1, $2] }

    return other_row(html) unless path

    # github のパス作成
    href = File.join(Settings.repository, 'blob', Settings.branch || 'develop', "#{path}#L#{line_num}")

    <<~HTML
      <tr>
        <td></td>
        <td class='log_td3'>
          <a class='log_caller' href=#{href} target="_blank">#{html}</a>
        </td>
      </tr>
    HTML
  end

  def other_row(html)
    "<tr><td colspan=2 class='log_td'>" + html + "</td></tr>"
  end

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
