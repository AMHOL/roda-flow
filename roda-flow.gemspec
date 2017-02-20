# coding: utf-8
Gem::Specification.new do |spec|
  spec.name         = 'roda-flow'
  spec.version      = '0.3.1'
  spec.authors      = ['Andy Holland']
  spec.email        = ['andyholland1991@aol.com']

  spec.summary      = ''
  spec.description  = spec.summary
  spec.homepage     = 'https://github.com/AMHOL/roda-flow'
  spec.license      = 'MIT'

  spec.files        = Dir['README.md', 'LICENSE.txt', 'lib/**/*']
  spec.require_path = 'lib'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'roda'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rack-test'
end
