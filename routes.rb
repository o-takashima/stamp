Dir.glob('routes/*').each do |f|
  require_relative f
end
