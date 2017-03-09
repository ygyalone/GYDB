
Pod::Spec.new do |s|

  s.name         = "GYDB"
  s.version      = "1.0.2"
  s.summary      = "iOS database framework based on sqlite3"
  s.homepage     = "https://github.com/ygyalone"
  s.license      = "MIT"
  s.author       = { "GuangYuYang" => "ygy9916730@163.com" }
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/ygyalone/GYDB.git", :tag => "1.0.2" }
  s.source_files  = "GYDB/GYDB/GYDB/**/*.{h,m}"
  s.public_header_files = "GYDB/GYDB/GYDB/GYDB.h", "GYDB/GYDB/GYDB/GYDatabaseManager/GYDatabaseManager.h", "GYDB/GYDB/GYDB/NSObject+GYDB/NSObject+GYDB.h", "GYDB/GYDB/GYDB/GYDBCondition/GYDBCondition.h", "GYDB/GYDB/GYDB/GYDBError/GYDBError.h"

  s.library   = "sqlite3"

end
