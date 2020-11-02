get '/' do
  # 比較元
  stamp_a = params[:stamp_a]
  # 比較先
  stamp_b = params[:stamp_b]

  @results = []
  @logs    = ''

  if stamp_a && stamp_b
    # 比較結果
    @results = Overlap.compare(stamp_a, stamp_b) || []

    @logs = Overlap.compare_log(stamp_a, stamp_b) || ''
  end

  # スタンプ一覧
  @stamps = Dir[File.join(Stamp.path, '*', '*')].reject do |dir|
    dir.start_with?(File.join(Stamp.path, 'logs'))
  end.map do |dir|
    %i[stamp_number stamp_name].zip(dir.split("/")[-2, 2]).to_h
  end

  slim :'root/index'
end

post '/' do
  Stamp.push(params[:stamp_name].presence)

  redirect "/", 303
end

delete '/' do
  Stamp.clear

  redirect "/", 303
end
