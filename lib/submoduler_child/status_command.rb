# frozen_string_literal: true

require 'optparse'

module SubmodulerChild
  class StatusCommand < SubmodulerCommon::Command
    def initialize(args)
      super()
      @args = args
      parse_options
    end

    def execute
      show_child_header
      
      check_repository_status
      check_branch_info
      
      0
    rescue StandardError => e
      logger.error "Error: #{e.message}"
      1
    end

    private

    def show_child_header
      ini = SubmodulerCommon::SubmodulerIni.new
      
      if ini.exist?
        ini.load_config
        child_name = ini.child_name || 'unknown'
        logger.info "=== Child Submodule: #{child_name} ==="
        logger.info ""
      else
        logger.info "=== Child Submodule Status ==="
        logger.info ""
      end
    rescue SubmodulerCommon::SubmodulerIni::ConfigError
      logger.info "=== Child Submodule Status ==="
      logger.info ""
    end

    def parse_options
      OptionParser.new do |opts|
        opts.banner = "Usage: bin/submoduler_child.rb status [options]"
        
        opts.on('-h', '--help', 'Display this help') do
          puts opts
          exit 0
        end
      end.parse!(@args)
    end

    def check_repository_status
      logger.info "Repository Status:"
      
      status_output = SubmodulerCommon::GitHelper.run('status --short')
      
      if SubmodulerCommon::GitHelper.success?
        if status_output.strip.empty?
          logger.info "  ✓ Working tree is clean"
        else
          logger.error "  ✗ Working tree has changes:"
          
          modified = []
          untracked = []
          staged = []
          
          status_output.each_line do |line|
            line = line.strip
            if line.start_with?('M ')
              modified << line[2..-1]
            elsif line.start_with?('??')
              untracked << line[3..-1]
            elsif line.start_with?('A ')
              staged << line[2..-1]
            end
          end
          
          unless staged.empty?
            logger.info "    Staged:"
            staged.each { |f| logger.info "      #{f}" }
          end
          
          unless modified.empty?
            logger.info "    Modified:"
            modified.each { |f| logger.info "      #{f}" }
          end
          
          unless untracked.empty?
            logger.info "    Untracked:"
            untracked.each { |f| logger.info "      #{f}" }
          end
        end
      else
        logger.error "  ✗ Error checking git status"
      end
      
      logger.info ""
    end

    def check_branch_info
      logger.info "Branch Information:"
      
      branch = SubmodulerCommon::GitHelper.run('branch --show-current').strip
      
      if SubmodulerCommon::GitHelper.success? && !branch.empty?
        logger.info "  Current branch: #{branch}"
        
        # Check if branch has remote tracking
        remote_info = SubmodulerCommon::GitHelper.run("rev-list --left-right --count #{branch}...@{u}").strip
        
        if SubmodulerCommon::GitHelper.success?
          ahead, behind = remote_info.split("\t").map(&:to_i)
          
          if ahead > 0 && behind > 0
            logger.error "  ⚠ Branch is #{ahead} commit(s) ahead and #{behind} commit(s) behind remote"
          elsif ahead > 0
            logger.error "  ↑ Branch is #{ahead} commit(s) ahead of remote"
          elsif behind > 0
            logger.error "  ↓ Branch is #{behind} commit(s) behind remote"
          else
            logger.info "  ✓ Branch is up to date with remote"
          end
        else
          logger.info "  ℹ No remote tracking branch"
        end
      else
        logger.info "  ℹ Not on any branch (detached HEAD)"
      end
    end
  end
end
