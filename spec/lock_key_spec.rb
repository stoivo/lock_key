require 'spec_helper'

describe "LockKey" do
  before do
    REDIS.flushdb
  end

  it "takes out a lock" do
    REDIS.lock_key "foo"
    REDIS.locked_key?("foo").should be_true
  end

  it "removes a lock" do
    REDIS.lock_key "foo" do
      REDIS.locked_key?("foo").should be_true
    end
    REDIS.locked_key?("foo").should be_false
  end

  it "removes a lock manually" do
    REDIS.lock_key "foo"
    REDIS.locked_key?("foo").should be_true
    REDIS.unlock_key "foo"
    REDIS.locked_key?("foo").should be_false
  end

  it "handles many threads" do
    captures = []
    one   = lambda{ REDIS.lock_key("foo", :expire => 5) { sleep 2; captures << :one   } }
    two   = lambda{ REDIS.lock_key("foo", :expire => 5) { sleep 1; captures << :two   } }
    three = lambda{ REDIS.lock_key("foo", :expire => 5) { sleep 2; captures << :three } }
    four  = lambda{ REDIS.lock_key("foo", :expire => 1, wait_for: 1, raise: false) { sleep 2; captures << :four  } }

    threads = []

    threads << Thread.new(&one)
    threads << Thread.new(&two)
    threads << Thread.new(&three)
    threads << Thread.new(&four)

    threads.each { |t| t.join }

    captures.should have(3).elements
    captures.should_not include(:four)
    captures.should include(:one, :two, :three)
  end
end
