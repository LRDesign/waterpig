Gem::Specification.new do |spec|
  spec.name		= "waterpig"
  spec.version		= "0.12.1"
  author_list = {
    "Judson Lester" => 'nyarly@gmail.com',
    "Evan Dorn"     => 'evan@lrdesign.com'
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Capybara helper stuff"
  spec.description	= <<-EndDescription
  Because waterpig is what the scientific name for a capybara translates to, that's why.
  EndDescription

  spec.rubyforge_project= spec.name.downcase
  spec.homepage        = "http://nyarly.github.com/#{spec.name.downcase}"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    lib/waterpig.rb

    lib/waterpig/save-and-open-on-fail.rb
    lib/waterpig/ckeditor-tools.rb
    lib/waterpig/selenium_chrome.rb
    lib/waterpig/database-cleaner.rb
    lib/waterpig/deadbeat-connections.rb
    lib/waterpig/template-refresh.rb
    lib/waterpig/request-wait-middleware.rb
    lib/waterpig/tinymce-tools.rb
    lib/waterpig/browser-integration.rb
    lib/waterpig/browser-console-logger.rb
    lib/waterpig/poltergeist.rb
    lib/waterpig/warning-suppressor.rb
    lib/waterpig/snap-step.rb
    lib/waterpig/browser-tools.rb
    lib/waterpig/browser-size.rb

    lib/waterpig/at_exit_duck_punch.rb

    spec/embarrassing.rb
    spec_help/spec_helper.rb
    spec_help/gem_test_suite.rb
  ]

  spec.test_file        = "spec_help/gem_test_suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} Documentation"]

  spec.add_dependency("capybara", "~> 2.2")
  spec.add_dependency("database_cleaner", "~> 1.3")
  spec.add_dependency("rspec-steps", "~> 2.1")
  spec.add_dependency("text-table", "~> 1.2", ">= 1.2.3")
end
