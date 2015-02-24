# -*- encoding: utf-8 -*-
# stub: nickel 0.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "nickel"
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Lou Zell", "Iain Beeston"]
  s.date = "2015-02-04"
  s.description = "Extracts date, time, and message information from naturally worded text."
  s.files = [".gitignore", ".travis.yml", ".yardopts", "CHANGELOG.md", "Gemfile", "License.txt", "README.md", "Rakefile", "bin/run_specs.sh", "lib/nickel.rb", "lib/nickel/construct.rb", "lib/nickel/construct_finder.rb", "lib/nickel/construct_interpreter.rb", "lib/nickel/nlp.rb", "lib/nickel/nlp_query.rb", "lib/nickel/nlp_query_constants.rb", "lib/nickel/occurrence.rb", "lib/nickel/version.rb", "lib/nickel/zdate.rb", "lib/nickel/ztime.rb", "nickel.gemspec", "spec/lib/nickel/construct_spec.rb", "spec/lib/nickel/occurrence_spec.rb", "spec/lib/nickel/zdate_spec.rb", "spec/lib/nickel/ztime_spec.rb", "spec/lib/nickel_spec.rb", "spec/spec_helper.rb"]
  s.homepage = "http://github.com/iainbeeston/nickel"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.rubygems_version = "2.4.5"
  s.summary = "Natural language date, time, and message parsing."
  s.test_files = ["spec/lib/nickel/construct_spec.rb", "spec/lib/nickel/occurrence_spec.rb", "spec/lib/nickel/zdate_spec.rb", "spec/lib/nickel/ztime_spec.rb", "spec/lib/nickel_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 3.1"])
      s.add_development_dependency(%q<codeclimate-test-reporter>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<kramdown>, [">= 0"])
      s.add_development_dependency(%q<holidays>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 3.1"])
      s.add_dependency(%q<codeclimate-test-reporter>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<kramdown>, [">= 0"])
      s.add_dependency(%q<holidays>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 3.1"])
    s.add_dependency(%q<codeclimate-test-reporter>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<kramdown>, [">= 0"])
    s.add_dependency(%q<holidays>, [">= 0"])
  end
end
