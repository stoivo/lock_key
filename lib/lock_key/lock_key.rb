class Redis
  module LockKey
    begin
      require 'securerandom'
      UUID_GEN = lambda { SecureRandom.uuid }
    rescue LoadError
      begin
        require 'uuid'
        UUID_GEN = lambda { UUID.new.generate }
      rescue LoadError
        puts <<-TXT
          Could not find a uuid generator.
            Ensure ActiveSupport is available for SecureRandom
            OR
            Install uuid gem
            We prefer SecureRandom
        TXT
      end
    end

    class LockAttemptTimeout < StandardError; end

    @@defaults = {
      :wait_for => 60,    # seconds to wait to obtain a lock
      :expire   => 60,    # seconds till key expires
      :raise    => true,  # raise a LockKey::LockAttemptTimeout if the lock cannot be obtained
      :sleep_for => 0.5
    }

    VALUE_DELIMETER = "-:-:-"

    def self.defaults=(defaults); @@defaults = @@defaults.merge(defaults); end
    def self.defaults; @@defaults; end

    # The lock key id for this thread. Uses uuid so that concurrency is not an issue
    # w.r.t. keys
    def self.lock_key_id; Thread.current[:lock_key_id] ||= UUID_GEN.call; end

    # Locks a key in redis options are same as default.
    # If a block is given the lock is automatically released
    # If no block is given, be sure to unlock the key when you're done.
    # Note... Locks should be as _Small_ as possible with respec to the time you
    # have the lock for!
    # @param key String The key to lock
    # @param opts Hash the options hash for the lock
    # @option opts :wait_for Numeric The time to wait for to obtain a lock
    # @option opts :expire Numeric The time before the lock expires
    # @option opts :raise  Causes a raise if a lock cannot be obtained
    # @option opts :sleep_for the time to sleep between checks
    def lock_key(key, opts={})
      is_block, got_lock = block_given?, false
      options = LockKey.defaults.merge(opts)

      got_lock = obtain_lock(key, options)
      yield if is_block && got_lock
      got_lock
    ensure
      unlock_key(key, options) if is_block && got_lock
    end

    def locked_key?(key)
      !!fetch(key)
    end

    def kill_lock!(key)
      _redis_.del(lock_key_for(key))
    end

    # Unlocks the key. Use a block... then you don't need this
    # @param key String the key to unlock
    # @param opts Hash an options hash
    # @option opts :key the value of the key to unlock.
    #
    # @example
    #   # Unlock the key if this thread owns it.
    #   redis.lock_key "foo"
    #   # do stuff
    #   redis.unlock_key "foo"
    #
    # @example
    #   # Unlock the key in a multithreaded env
    #   key_value = redis.lock_key "foo"
    #   Thread.new do
    #     # do stuff
    #     redis.unlock_key "foo", :key => key_value
    #   end
    def unlock_key(key, opts={})
      held_value = opts[:key]
      value = fetch(key)
      return true unless value
      if value == held_value || i_have_the_lock?(value)
        kill_lock!(key)
        true
      else
        false
      end
    end

    private
    def _redis_
      self
    end

    def fetch(key)
      _redis_.get lock_key_for(key)
    end

    def lock_key_for(key)
      "lock_key:#{key}"
    end

    def lock_key_value
      LockKey.lock_key_id
    end

    def obtain_lock(key, opts={})
      new_lock = renew_lock_if_owned(key,opts)
      return new_lock if new_lock

      wait_until = Time.now + opts[:wait_for]

      until new_lock || Time.now > wait_until
        _key_ = lock_key_for(key)
        if _redis_.setnx(_key_, lock_key_value)
          new_lock = lock_key_value
          _redis_.expire(_key_, opts[:expire])
        end
        sleep opts[:sleep_for]
      end

      if !new_lock && opts[:raise]
        raise LockAttemptTimeout, "Could not lock #{key}"
      end

      new_lock
    end

    def i_have_the_lock?(lock_value)
      return false unless lock_value
      # should just be a straight comparison, but need to roll out
      # new code that changes things first
      lock_value.split(VALUE_DELIMETER).last == LockKey.lock_key_id
    end

    def i_dont_have_the_lock?(lock_value)
      !i_have_the_lock?(lock_value)
    end

    def renew_lock_if_owned(key,opts)
      current_value = fetch(key)
      return false if current_value && i_dont_have_the_lock?(current_value)
      _key_ = lock_key_for(key)
      result = _redis_.multi do
        _redis_.set(_key_, lock_key_value)
        _redis_.expire(_key_, opts[:expire])
      end
      lock_key_value if result.first == "OK"
    end
  end
end
