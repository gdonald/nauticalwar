
def log(msg)
  mylog = Logger.new("#{Rails.root}/log/debug.log")
  mylog.info(msg)
end
