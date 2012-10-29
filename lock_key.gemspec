# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lock_key/version'

Gem::Specification.new do |gem|
  gem.name          = "lock_key"
  gem.version       = LockKey::VERSION
  gem.authors       = ["Take out locks via redis"]
  gem.email         = ["has.sox@gmail.com"]
  gem.description   = %q{Uses redis to take out multi-threaded/processed safe locks}
  gem.summary       = %q{Uses redis to take out multi-threaded/processed safe locks}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
