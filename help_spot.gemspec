# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "help_spot/version"

Gem::Specification.new do |s|
  s.name        = "help_spot"
  s.version     = HelpSpot::VERSION
  s.authors     = ["Jon Phenow"]
  s.email       = ["j.phenow@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Connector to Help Spot API}
  s.description = %q{}

  s.rubyforge_project = "help_spot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
