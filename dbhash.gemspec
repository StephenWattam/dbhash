Gem::Specification.new do |s|
  # About the gem
  s.name        = 'DBHash'
  s.version     = '0.1.0a'
  s.date        = '2014-12-12'
  s.summary     = 'A disk-backed version of ruby\'s Hash'
  s.description = 'A disk-backed structure designed for fast append of postings lists and similar string data'
  s.author      = 'Stephen Wattam'
  s.email       = 'steve@stephenwattam.com'
  s.homepage    = 'http://stephenwattam.com'
  s.required_ruby_version =  ::Gem::Requirement.new(">= 2.0")
  s.license     = 'CC-BY-NC-SA 3.0' # Creative commons by-nc-sa 3
  
  # Files + Resources
  s.files         = Dir["lib/*.rb"]# + Dir['bin/*']
  s.require_paths = ['lib']
  
  # Executables
  # s.bindir       = 'bin'
  # s.executables << 'lfsimport'
  # s.executables << 'lfsexport'

  # Documentation
  s.has_rdoc         = false

  # Deps
  c.add_runtime_dependency 'xxhash',     '~> 0.2'

end

