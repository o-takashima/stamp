get '/' do
  # 比較元
  stamp_a = params[:stamp_a]
  # 比較先
  stamp_b = params[:stamp_b]

  # 比較結果
  @results = Overlap.compare(stamp_a, stamp_b) || []

  # スタンプ一覧
  @stamps = Dir["stamps/*/*"].map do |dir|
    %i[stamp_number stamp_name].zip(dir.split("/")[1,2]).to_h
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
