# frozen_string_literal: true

module SubmodulerChild
  class InitCommand
    def initialize(args)
      @args = args
      @options = parse_options
    end

    def execute
      puts "Initializing Submoduler Child..."
      
      ini = SubmodulerCommon::SubmodulerIni.new
      if ini.exist?
        puts "Error: .submoduler.ini already exists"
        return 1
      end

      child_name = @options[:name] || detect_gem_name || File.basename(Dir.pwd)
      
      create_config_file(child_name)
      create_directory_structure
      
      puts "✓ Initialized Submoduler Child: #{child_name}"
      
      puts ""
      puts "Next steps:"
      puts "  1. Review .submoduler.ini configuration"
      puts "  2. Run 'bin/submoduler_child status' to verify setup"
      
      0
    end

    private

    def parse_options
      options = {}
      
      OptionParser.new do |opts|
        opts.banner = "Usage: submoduler_child init [options]"
        opts.on("-n", "--name NAME", "Child submodule name") do |name|
          options[:name] = name
        end
        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit 0
        end
      end.parse!(@args)
      
      options
    end

    def create_config_file(child_name)
      config_content = <<~CONFIG
        [submoduler]
        childname = #{child_name}
        type = child
        
        [paths]
        lib = lib
        spec = spec
        
        [parent]
        # Path to parent submodule (relative or absolute)
        # path = ../parent
      CONFIG
      
      File.write('.submoduler.ini', config_content)
      puts "✓ Created .submoduler.ini"
    end

    def detect_gem_name
      # Look for .gemspec file in current directory
      gemspec_files = Dir.glob('*.gemspec')
      return nil if gemspec_files.empty?
      
      # Read the first gemspec file and extract the gem name
      gemspec_content = File.read(gemspec_files.first)
      
      # Match spec.name = "gem-name" pattern
      if gemspec_content =~ /spec\.name\s*=\s*["']([^"']+)["']/
        return $1
      end
      
      nil
    end

    def create_directory_structure
      dirs = ['lib', 'spec', 'bin']
      
      dirs.each do |dir|
        unless Dir.exist?(dir)
          Dir.mkdir(dir)
          puts "✓ Created #{dir}/"
        end
      end
    end
  end
end
