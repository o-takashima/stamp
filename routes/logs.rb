put '/logs/entry' do
  Stamp.log_entry!
  redirect "/", 303
end
