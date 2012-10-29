require "lock_key/version"
require 'lock_key/lock_key'
require 'redis'

class Redis
  include Redis::LockKey
end
