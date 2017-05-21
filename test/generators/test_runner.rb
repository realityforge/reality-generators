require File.expand_path('../../helper', __FILE__)
require 'date'

class Reality::Generators::TestRunner < Reality::TestCase
  def test_basic_runner_execution
    descriptor = "#{temp_dir}/repository.rb"
    File.write(descriptor, 'GenTest.repository(:MyRepo)')

    target_directory = "#{temp_dir}/generated/erb_template"
    generators = %w(test)

    output = run_gentest(descriptor, generators, target_directory)

    repo_file = "#{target_directory}/main/java/MyRepo.java"
    assert_equal true, File.directory?("#{target_directory}/main/java")
    assert_equal true, File.exist?(repo_file)
    assert_equal 'Repository: MyRepo', IO.read(repo_file)
    assert_equal '', output
  end

  def test_verbose_runner_execution
    descriptor = "#{temp_dir}/repository.rb"
    File.write(descriptor, 'GenTest.repository(:MyRepo)')

    target_directory = "#{temp_dir}/generated/erb_template"
    generators = %w(test)

    output = run_gentest(descriptor, generators, target_directory, '--verbose')

    target_file = "#{target_directory}/main/java/MyRepo.java"
    assert_equal 'Repository: MyRepo', IO.read(target_file)

    assert_equal <<OUTPUT, output
Repository Name: Unspecified
Target Dir: #{target_directory}
Descriptor: #{descriptor}
Generators:
	 * test
Loading descriptor: #{descriptor}
Descriptor loaded: #{descriptor}
Derived default Repository name: MyRepo
Generator completed
OUTPUT
  end

  def test_debug_runner_execution
    descriptor = "#{temp_dir}/repository.rb"
    File.write(descriptor, 'GenTest.repository(:MyRepo)')

    target_directory = "#{temp_dir}/generated/erb_template"
    generators = %w(test)

    output = run_gentest(descriptor, generators, target_directory, '--debug')

    target_file = "#{target_directory}/main/java/MyRepo.java"
    assert_equal 'Repository: MyRepo', IO.read(target_file)

    assert_equal <<OUTPUT, output
Repository Name: Unspecified
Target Dir: #{target_directory}
Descriptor: #{descriptor}
Generators:
	 * test
Loading descriptor: #{descriptor}
Descriptor loaded: #{descriptor}
Derived default Repository name: MyRepo
Templates to process: ["test:repository.java"]
Evaluating template: test:repository.java
Generating test:repository.java for repository MyRepo
Generated test:repository.java for repository MyRepo to #{target_file}
Generator completed
OUTPUT
  end

  def test_debug_runner_execution_multiple_descriptors_multiple_templates
    descriptor = "#{temp_dir}/repository.rb"
    File.write(descriptor, 'GenTest.repository(:MyRepo)')
    descriptor2 = "#{temp_dir}/repository2.rb"
    File.write(descriptor2, '')

    target_directory = "#{temp_dir}/generated/erb_template"
    generators = %w(test test2)

    output = run_gentest(descriptor, generators, target_directory, "--descriptor #{descriptor2} --debug")

    target_file = "#{target_directory}/main/java/MyRepo.java"
    target_file2 = "#{target_directory}/main/java/MyRepoTemplate2.java"
    assert_equal 'Repository: MyRepo', IO.read(target_file)
    assert_equal 'Repository: MyRepo (Template2)', IO.read(target_file2)

    expected = <<OUTPUT
Repository Name: Unspecified
Target Dir: #{target_directory}
Descriptors:
  * #{descriptor}
  * #{descriptor2}
Generators:
  * test
  * test2
Loading descriptor: #{descriptor}
Descriptor loaded: #{descriptor}
Loading descriptor: #{descriptor2}
Descriptor loaded: #{descriptor2}
Derived default Repository name: MyRepo
Templates to process: ["test:repository.java", "test2:repository_t2.java"]
Evaluating template: test:repository.java
Generating test:repository.java for repository MyRepo
Generated test:repository.java for repository MyRepo to #{target_file}
Evaluating template: test2:repository_t2.java
Generating test2:repository_t2.java for repository MyRepo
Generated test2:repository_t2.java for repository MyRepo to #{target_file2}
Generator completed
OUTPUT
    assert_equal expected, output
  end

  def test_help_invocation
    output = run_runner(%w(--help))

    assert_equal <<OUTPUT, output
Usage: gentest.rb [OPTIONS]

Options
    -d, --descriptor FILENAME        the filename of a descriptor to be loaded. Multiple descriptors may be loaded. Defaults to 'resources.rb' if none specified.
    -r, --repository NAME            the name of the repository to load. Defaults to the the name of the only repository if there is only one repository defined by the descriptors, otherwise must be specified.
    -g, --generators GENERATORS      the comma separated list of generators to run. Defaults to []
    -t, --target-dir DIR             the directory into which to generate artifacts. Defaults to 'generated'.
    -v, --verbose                    turn on verbose logging.
        --debug                      turn on debug logging.
    -h, --help                       help
OUTPUT
  end

  def run_gentest(descriptor, generators, target_directory, additional_args = '')
    run_runner((%W(--descriptor #{descriptor} --generators #{generators.join(',')} --target-dir #{target_directory} #{additional_args})))
  end

  def run_runner(args)
    prefix = (defined?(JRUBY_VERSION) || Gem.win_platform?) ? 'ruby ' : ''
    command = File.expand_path("#{File.dirname(__FILE__)}/gentest.rb")
    run_command("#{prefix}#{command} #{args.join(' ')}")
  end

  def run_command(command, expected_exitcode = 0)
    output = `#{command}`
    exitcode = $?.exitstatus
    raise "Command failed to exit with code #{expected_exitcode} but returned #{exitcode}: #{command}\nOutput: #{output}" unless exitcode == expected_exitcode
    output
  end
end
