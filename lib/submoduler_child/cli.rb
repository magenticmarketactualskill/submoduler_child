# frozen_string_literal: true

require 'optparse'
require 'rainbow'
require 'submoduler_common/command'

module SubmodulerChild
  class CLI < SubmodulerCommon::Command
    COMMANDS = {
      'init' => 'Initialize a new Submoduler child submodule',
      'status' => 'Display status of the child submodule',
      'test' => 'Run tests in the child submodule',
      'version' => 'Display and manage version information',
      'build' => 'Build the child submodule gem package',
      'symlink_build' => 'Build symlinks from vendor gems to child .kiro/steering',
      'update' => 'Run full update workflow (tests, commit, bump, push)'
    }.freeze

    def self.run(args)
      new(args).run
    end

    def initialize(args)
      @args = args
      @command = nil
      @options = {}
    end

    def run
      if @args.empty?
        display_help
        return 1
      end

      @command = @args.shift

      unless COMMANDS.key?(@command)
        puts "Error: Unknown command '#{@command}'"
        display_help
        return 1
      end

      verify_child_context

      execute_command
    rescue StandardError => e
      logger.error "Error: #{e.message}"
      1
    end

    private

    def verify_child_context
      # Skip verification for init command
      return if @command == 'init'
      
      ini = SubmodulerCommon::SubmodulerIni.new
      
      unless ini.exist?
        raise "Not in a Submoduler directory. Missing .submoduler.ini"
      end

      ini.load_config
      ini.validate_child!
    rescue SubmodulerCommon::SubmodulerIni::ConfigError => e
      raise "Invalid configuration: #{e.message}"
    end

    def execute_command
      case @command
      when 'init'
        require_relative 'init_command'
        InitCommand.new(@args).execute
      when 'status'
        StatusCommand.new(@args).execute
      when 'test'
        TestCommand.new(@args).execute
      when 'version'
        VersionCommand.new(@args).execute
      when 'symlink_build'
        require_relative 'symlink_build_command'
        SymlinkBuildCommand.run
        0
      when 'build'
        puts "Build command not yet implemented"
        0
      when 'update'
        require_relative 'update_command'
        UpdateCommand.new(@args).execute
      else
        puts "Error: Command '#{@command}' not implemented"
        1
      end
    end

    def display_help
      # Show child name if available
      ini = SubmodulerCommon::SubmodulerIni.new
      if ini.exist?
        begin
          ini.load_config
          child_name = ini.child_name
          puts "Submoduler Child - #{child_name}" if child_name
        rescue SubmodulerCommon::SubmodulerIni::ConfigError
          # Ignore and show generic header
        end
      end
      
      puts "Submoduler Child - Manage child submodule operations" unless ini.exist? && ini.child_name
      puts ""
      puts "Usage: bin/submoduler <command> [options]"
      puts ""
      puts "Available commands:"
      COMMANDS.each do |cmd, desc|
        puts "  #{cmd.ljust(12)} #{desc}"
      end
      puts ""
      puts "Run 'bin/submoduler <command> --help' for command-specific options"
    end

    def colorize(message, type = :default)
      case type
      when :success
        Rainbow(message).green
      when :error
        Rainbow(message).red
      when :warning
        Rainbow(message).yellow
      else
        message
      end
    end
  end
end
