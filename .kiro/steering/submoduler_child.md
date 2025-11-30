## Context

see submoduler_common gem

# Submoduler Child Guide

 It provides tools for child components to managed in a monorepo environment, enabling them to reference and interact with the parent repository.

reference: https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git

## Installation

### In Submodules

All submodules include this in their Gemfile:

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler child gem
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'

gemspec
```

### Local Development

For local development, use the vendored copy:

```ruby
# Use vendored copy (relative path from subgem directory)
gem 'submoduler-core-submoduler_child', path: '../../../vendor/submoduler_child'
```

## Vendored Location

The gem is vendored at:
```
vendor/submoduler_child/
├── .git/                       # Git repository
├── .kiro/                      # Kiro configuration
├── .submoduler.ini             # Submoduler configuration
├── bin/                        # Executables
├── lib/                        # Library code
├── README.md
├── CHANGELOG.md
├── LICENSE
├── submoduler_child.gemspec
└── submoduler-core-submoduler_child-0.2.0.gem
```

## Purpose

The submoduler_child gem enables submodules to:

1. **Reference Parent**: Access parent repository files and configuration
2. **Manage Configuration**: Use `.submoduler.ini` for child-specific settings
3. **Build Tools**: Provide commands for building and testing child components
4. **Version Management**: Track child component versions independently

## Configuration

### .submoduler.ini

Each subgem can have a `.submoduler.ini` file:

```ini
[submoduler]
childname = active_data_flow-connector-source-active_record
type = child

[paths]
lib = lib
spec = spec

[parent]
# Path to parent repository (active_data_flow)
path = ../../
```

### Symbolic Links

Submodules use symbolic links to reference parent documentation:

```bash
# From submodule directory
submoduler_master -> ../../../  # Link to parent repository
```

This allows submodules to access parent `.kiro/` documentation and configuration.

## Available Commands

### Initialize Child Submodule

```bash
# In a new subgem directory
bundle exec submoduler_child init --name active_data_flow-connector-source-active_record
```

Creates:
- `.submoduler.ini` - Configuration file
- `lib/` - Library directory
- `spec/` - Spec directory  
- `bin/` - Binary directory

### Status

```bash
# Check child submodule status
bundle exec submoduler_child status
```

Shows:
- Child name and type
- Parent path
- Configuration status
- File structure

### Build

```bash
# Build the gem package
bundle exec submoduler_child build
```

Builds the gem file for the subgem.

### Test

```bash
# Run tests
bundle exec submoduler_child test
```

Runs RSpec tests for the subgem.

### Version

```bash
# Display version information
bundle exec submoduler_child version
```

Shows the submoduler_child gem version.

## Usage in Submodules

### Directory Structure

Submodules using submoduler_child follow this structure:

```
submodules/active_data_flow-connector-source-active_record/
├── .submoduler.ini             # Submoduler configuration
├── lib/
│   └── active_data_flow/
│       └── connector/
│           └── source/
│               └── active_record.rb
├── spec/
├── .kiro/
│   ├── specs/
│   │   ├── requirements.md
│   │   ├── design.md
│   │   ├── tasks.md
│   │   ├── parent_requirements.md  # Reference to parent
│   │   └── parent_design.md        # Reference to parent
│   └── steering/                   # Managed by git_steering gem
├── Gemfile                         # Includes submoduler_child
├── active_data_flow-connector-source-active_record.gemspec
└── README.md
```

### Accessing Parent Resources

Through the submoduler_child gem, submodules can:

1. **Reference parent .kiro files** via symbolic links
2. **Access parent configuration** through `.submoduler.ini`
3. **Build relative to parent** for consistent paths
4. **Test with parent context** for integration testing

## Development Workflow

### Creating a New Subgem with Submoduler Child

1. **Create directory**:
   ```bash
   mkdir -p submodules/active_data_flow-new-component
   cd submodules/active_data_flow-new-component
   ```

2. **Create Gemfile with submoduler_child**:
   ```ruby
   source 'https://rubygems.org'
   gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'
   ```

3. **Install and initialize**:
   ```bash
   bundle install
   bundle exec submoduler_child init --name active_data_flow-new-component
   ```

4. **Configure .submoduler.ini**:
   ```ini
   [submoduler]
   childname = active_data_flow-new-component
   type = child

   [parent]
   path = ../../
   ```

5. **Create .kiro structure** - steering files managed by git_steering gem

### Testing with Parent Context

```bash
# In subgem directory
bundle exec rspec

# Or from parent directory
cd ../..
bundle exec rspec submodules/active_data_flow-new-component/spec
```

### Building Subgem

```bash
# In subgem directory
bundle exec submoduler_child build

# Or use gem build directly
gem build active_data_flow-new-component.gemspec
```

## Integration with Active Data Flow

### Parent-Child Relationship

```
active_data_flow (parent)
├── Uses: submoduler-core-submoduler_parent
├── Gemfile references submodules via path
└── submodules/
    ├── active_data_flow-connector-source-active_record (child)
    │   ├── Uses: submoduler-core-submoduler_child
    │   └── .submoduler.ini points to parent
    ├── active_data_flow-connector-sink-active_record (child)
    │   ├── Uses: submoduler-core-submoduler_child
    │   └── ...
    └── active_data_flow-runtime-heartbeat (child)
        ├── Uses: submoduler-core-submoduler_child
        └── ...
```

### Gemfile Coordination

**Parent Gemfile** (active_data_flow):
```ruby
gem 'submoduler-core-submoduler_parent', git: '...'

# Path references to submodules
gem 'active_data_flow-connector-source-active_record', path: 'submodules/active_data_flow-connector-source-active_record'
```

**Child Gemfile** (subgem):
```ruby
gem 'submoduler-core-submoduler_child', git: '...'

gemspec  # Loads dependencies from gemspec
```

## Updating Vendored Copy

To update the vendored submoduler_child gem:

```bash
cd vendor/submoduler_child
git pull origin main
cd ../..
git add vendor/submoduler_child
git commit -m "Update submoduler_child to latest version"
```

## Troubleshooting

### Submoduler Child Not Found

```bash
# Ensure gem is installed
bundle install

# Check Gemfile includes submoduler_child
grep submoduler_child Gemfile
```

### Configuration Issues

```bash
# Check .submoduler.ini exists
ls -la .submoduler.ini

# Verify parent path is correct
cat .submoduler.ini | grep path
```

### Steering File Issues

```bash
# Verify steering files are present
ls -la .kiro/steering/

# Rebuild steering file symlinks using git_steering gem
bin/git_steering symlink_build
```

### Build Issues

```bash
# Ensure gemspec is valid
gem build *.gemspec

# Check for missing files
grep "spec.files" *.gemspec
```

## Best Practices

### Configuration

- **Always include .submoduler.ini** in submodules
- **Set correct parent path** (usually `../../`)
- **Use consistent naming** matching gem name

### Development

- **Test in isolation**: Run tests in subgem directory
- **Test with parent**: Run tests from parent directory
- **Use vendored copy**: For offline development

### Documentation

- **Reference parent docs**: Steering files managed by git_steering gem
- **Document child-specific**: Create subgem-specific requirements/design
- **Keep README updated**: Document subgem usage

## Related Documentation

- **Submoduler Parent**: `.kiro/steering/submodules_parent.md` - Parent gem guide
- **Submodules Development**: `.kiro/steering/submodules_development.md` - Complete submodule development guide
- **Gemfile Guidelines**: `.kiro/steering/gemfiles.md` - Gemfile patterns
- **Project Structure**: `.kiro/steering/structure.md` - Repository organization

## Version Information

Current vendored version: **0.2.0**

Check for updates at: https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child
