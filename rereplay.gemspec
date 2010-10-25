lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rereplay/version'

Gem::Specification.new do |s|
  s.name        = "rereplay"
  s.version     = ReReplay::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Max Aller"]
  s.email       = ["nanodeath@gmail.com"]
  s.homepage    = "http://github.com/nanodeath/ReReplay"
  s.summary     = %q{Replay your prod traffic}
  s.description = %q{Replay or script traffic in order to track performance of your site over time.}

  s.required_rubygems_version = ">= 1.3.6"

  s.add_runtime_dependency "eventmachine", ">= 0.12.10", "< 0.13"
  s.add_runtime_dependency "em-http-request", ">= 0.2.14", "< 0.3"
	
  s.add_development_dependency "rspec", ">= 2.0", "< 3"
  s.add_development_dependency "webmock", ">= 1.4.0", "< 1.5"
  s.add_development_dependency "active_support", ">= 3.0.1", "< 3.1"

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths      = ["lib"]
end
