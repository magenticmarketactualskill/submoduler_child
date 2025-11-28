# frozen_string_literal: true

require 'fileutils'

module SubmodulerChild
  class SymlinkBuildCommand
    PROJECT_STEERING = '.kiro/steering'

    def self.run
      new.run
    end

    def run
      puts "\n=== Building Symlinks (Child) ==="
      ensure_directory_exists
      find_parent_path
      create_symlinks_from_vendor_and_parent
      validate_symlinks
      report_results
    end

    private

    def ensure_directory_exists
      FileUtils.mkdir_p(PROJECT_STEERING) unless Dir.exist?(PROJECT_STEERING)
      puts "✓ Ensured #{PROJECT_STEERING} exists"
    end

    def find_parent_path
      ini = SubmodulerCommon::SubmodulerIni.new
      
      if ini.exist?
        ini.load_config
        # Try to get path from config, otherwise default to ../../
        @parent_path = ini.get('submoduler', 'path') || '../../'
      else
        @parent_path = '../../'
      end
      
      puts "✓ Parent path: #{@parent_path}"
    end

    def create_symlinks_from_vendor_and_parent
      @created = []
      @updated = []
      @skipped = []

      # Link from vendor gems (relative to child location)
      vendor_parent_path = File.join(@parent_path, 'vendor/submoduler_parent/.kiro/steering')
      vendor_child_path = File.join(@parent_path, 'vendor/submoduler_child/.kiro/steering')
      parent_steering_path = File.join(@parent_path, '.kiro/steering')

      # Calculate relative paths from child steering to sources
      relative_to_vendor_parent = calculate_relative_path(vendor_parent_path)
      relative_to_vendor_child = calculate_relative_path(vendor_child_path)
      relative_to_parent_steering = calculate_relative_path(parent_steering_path)

      # Link from vendor parent gem
      link_files_from(vendor_parent_path, relative_to_vendor_parent)
      
      # Link from vendor child gem
      link_files_from(vendor_child_path, relative_to_vendor_child)
      
      # Link from parent steering (project-specific files)
      link_files_from(parent_steering_path, relative_to_parent_steering)
    end

    def calculate_relative_path(target_dir)
      # From .kiro/steering to target
      # We're in: <submodule>/.kiro/steering
      # target_dir already includes the full path from submodule root
      # 
      # Just go up 2 levels from .kiro/steering to reach submodule root
      File.join('../../', target_dir)
    end

    def link_files_from(source_dir, relative_prefix)
      unless Dir.exist?(source_dir)
        puts "⚠ Source directory not found: #{source_dir}"
        return
      end

      Dir.glob("#{source_dir}/*.md").each do |source_file|
        filename = File.basename(source_file)
        target = File.join(PROJECT_STEERING, filename)
        
        # Skip if this is a symlink in parent pointing to vendor (avoid double-linking)
        if File.symlink?(source_file)
          # Get the real source
          real_source = File.readlink(source_file)
          source_relative = File.join(File.dirname(relative_prefix), real_source)
        else
          source_relative = File.join(relative_prefix, filename)
        end

        if File.symlink?(target)
          @updated << filename
          File.delete(target)
        elsif File.exist?(target)
          @skipped << filename
          next
        else
          @created << filename
        end

        File.symlink(source_relative, target)
      end
    end

    def validate_symlinks
      @broken = []
      
      Dir.glob("#{PROJECT_STEERING}/*.md").each do |link|
        next unless File.symlink?(link)
        unless File.exist?(link)
          @broken << File.basename(link)
        end
      end
    end

    def report_results
      puts "\n=== Symlink Build Results ==="
      puts "✓ Created: #{@created.length} files" if @created.any?
      @created.each { |f| puts "  + #{f}" } if @created.any?
      
      puts "↻ Updated: #{@updated.length} files" if @updated.any?
      @updated.each { |f| puts "  ↻ #{f}" } if @updated.any?
      
      puts "⊘ Skipped: #{@skipped.length} files (already exist)" if @skipped.any?
      @skipped.each { |f| puts "  ⊘ #{f}" } if @skipped.any?
      
      if @broken.any?
        puts "✗ Broken: #{@broken.length} symlinks"
        @broken.each { |f| puts "  ✗ #{f}" }
      end
      
      puts "\nTotal symlinks in #{PROJECT_STEERING}: #{Dir.glob("#{PROJECT_STEERING}/*.md").length}"
    end
  end
end
