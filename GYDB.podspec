
Pod::Spec.new do |s|

  s.name         = "GYDB"
  s.version      = "1.0.3"
  s.summary      = "iOS database framework based on sqlite3"
  s.homepage     = "https://github.com/ygyalone"
  s.license      = "MIT"
  s.author       = { "GuangYuYang" => "ygy9916730@163.com" }
  s.platform     = :ios, "7.0"

s.source       = { :git => "https://github.com/ygyalone/GYDB.git", :tag => s.version }
  s.source_files  = "GYDB/GYDB/GYDB/**/*.{h,m}"
  s.public_header_files = "GYDB/GYDB/GYDB/GYDB.h"

  s.library   = "sqlite3"

end
