# LockKey

Provides basic locking in Redis

## Installation

Add this line to your application's Gemfile:

    gem 'lock_key'

If running on 1.9 that's it, if not, you'll need to also install uuid

    gem 'uuid'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lock_key

## Usage

Based on [redis-lock](https://github.com/PatrickTulskie/redis-lock) and the [setnx redis comments](http://redis.io/commands/setnx)
LockKey provides basic key level locking.

## Locking a key

    r = Redis.new

    # use the Redis::LockKey.defaults
    r.lock_key "some_key" do
      # stuff in here with the key locked
    end

    # Selectively overwrite the defaults
    r.lock_key "some_key", :expire => 3 do
      # stuff in here with the key locked
    end

Using the block version of lock\_key ensures that the lock is removed at the end of the block

If you need more control over the locking and unlocking do not use a block. Just be sure to ensure you remove the lock.

    r.lock_key "some_key"
    # do stuff here
    r.unlock_key "some_key"

If worst comes to worst, you can forcefully kill the lock

    r.kill_lock! "some_key"

NOTE: You should always minimise the size of the lock. Do your best not to wrap external calls in a lock

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
