# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name               = %q{reality-generators}
  s.version            = '1.3.0'
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Peter Donald']
  s.email              = %q{peter@realityforge.org}

  s.homepage           = %q{https://github.com/realityforge/reality-generators}
  s.summary            = %q{A basic toolkit for abstracting the generation of files from model objects.}
  s.description        = %q{A basic toolkit for abstracting the generation of files from model objects.}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.default_executable = []
  s.require_paths      = %w(lib)

  s.has_rdoc           = false
  s.rdoc_options       = %w(--line-numbers --inline-source --title reality-generators)

  s.add_dependency 'reality-core', '>= 1.7.0'
  s.add_dependency 'reality-naming', '>= 1.6.0'
  s.add_dependency 'reality-orderedhash', '>= 1.0.0'

  s.add_development_dependency(%q<minitest>, ['= 5.9.1'])
  s.add_development_dependency(%q<test-unit>, ['= 3.1.5'])
end
