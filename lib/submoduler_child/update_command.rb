# frozen_string_literal: true

require 'optparse'
require 'rainbow'
require 'octokit'

module SubmodulerChild
  class UpdateCommand
    def initialize(args)
      @args = args
      @options = {}
      parse_options
    end

    def execute
      puts Rainbow("Starting update workflow...").cyan

      unless run_tests
        puts Rainbow("Tests failed! Aborting update.").red
        return 1
      end

      unless git_clean?
        stage_changes
        commit_changes
      end

      bump_version
      
      # Commit version bump if there are changes
      unless git_clean?
        stage_changes
        commit_version_bump
      end
      
      push_changes
      create_github_release if @options[:release]

      puts Rainbow("Update completed successfully!").green
      0
    rescue StandardError => e
      puts Rainbow("Error: #{e.message}").red
      1
    end

    private

    def parse_options
      OptionParser.new do |opts|
        opts.banner = "Usage: bin/submoduler_child.rb update [options]"
        
        opts.on("-m", "--message MESSAGE", "Commit message (required)") do |v|
          @options[:message] = v
        end
        
        opts.on("--[no-]release", "Create a GitHub release (requires GITHUB_TOKEN)") do |v|
          @options[:release] = v
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit 0
        end
      end.parse!(@args)
      
      # Validate required options
      unless @options[:message]
        puts "Error: --message (-m) is required"
        puts "Usage: bin/submoduler update -m 'commit message' [options]"
        exit 1
      end
    end

    def run_tests
      puts "Running tests..."
      require_relative 'test_command'
      # Capture output to avoid noise, or let it stream? Let's let it stream but check result.
      # TestCommand.new([]).execute returns 0 on success
      result = TestCommand.new([]).execute
      result == 0
    end

    def git_clean?
      output = `git status --porcelain`
      output.empty?
    end

    def stage_changes
      puts "Staging changes..."
      system("git add .")
    end

    def commit_changes
      puts "Committing changes..."
      message = @options[:message]
      system("git commit -m '#{message}'")
    end

    def commit_version_bump
      puts "Committing version bump..."
      # Get the new version
      require_relative 'version_command'
      version = VersionCommand.new([]).get_current_version
      message = "Bump version to #{version}"
      system("git commit -m '#{message}'")
    end

    def bump_version
      puts "Bumping version..."
      require_relative 'version_command'
      # Bump patch version by default
      VersionCommand.new(['--bump', 'patch']).execute
    end

    def push_changes
      puts "Pushing changes to remote..."
      system("git push")
      system("git push --tags")
    end

    def create_github_release
      token = ENV['GITHUB_TOKEN']
      unless token
        puts Rainbow("Warning: GITHUB_TOKEN not set. Skipping release creation.").yellow
        return
      end

      puts "Creating GitHub release..."
      client = Octokit::Client.new(access_token: token)
      repo = detect_repository
      tag = latest_tag
      
      if tag
        begin
          client.create_release(repo, tag, name: "Release #{tag}", body: "Automated release via Submoduler")
          puts Rainbow("GitHub release created: #{tag}").green
        rescue Octokit::Error => e
          puts Rainbow("Failed to create GitHub release: #{e.message}").red
        end
      else
        puts Rainbow("No tag found to release.").yellow
      end
    end

    def detect_repository
      # Extract owner/repo from git remote
      remote_url = `git remote get-url origin`.strip
      if remote_url =~ /github\.com[:\/](.+)\/(.+)\.git/
        "#{$1}/#{$2}"
      else
        raise "Could not detect GitHub repository from remote URL"
      end
    end

    def latest_tag
      `git describe --tags --abbrev=0`.strip
    rescue
      nil
    end
  end
end
