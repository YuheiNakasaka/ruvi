# frozen_string_literal: true

# This file is used to configure shared behavior for specs that need to load lib files
# Require this file from individual spec files that need to test lib classes

# Add lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

# Require main lib files
require 'editor'
require 'screen'
require 'input'
require 'escape_code'
require 'main'