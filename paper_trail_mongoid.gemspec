$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'paper_trail_mongoid/version_number'

Gem::Specification.new do |s|
  s.name          = 'paper_trail_mongoid'
  s.version       = PaperTrail::VERSION
  s.summary       = "Track changes to your models' data.  Good for auditing or versioning."
  s.description   = s.summary
  s.homepage      = 'http://github.com/airblade/paper_trail'
  s.authors       = ['Andy Stewart', 'Kristian Mandrup']
  s.email         = 'boss@airbladesoftware.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'rails',   '~> 3'
  s.add_dependency 'mongoid', '~> 2'

  s.add_development_dependency 'shoulda',      '2.10.3'
  s.add_development_dependency 'capybara',     '>= 0.4.0'
  s.add_development_dependency 'turn'
end
