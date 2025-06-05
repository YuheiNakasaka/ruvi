# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running the Editor
```bash
./bin/vi <file-path>
# or
ruby bin/vi <file-path>
```

### Dependencies
```bash
bundle install
```

### Code Quality
```bash
bundle exec rubocop              # Lint the codebase
bundle exec rubocop --fix-layout # Auto-fix layout issues
```

## Architecture Overview

Ruvi is a Ruby implementation of the Vi text editor with a modular architecture:

### Core Components
- **Editor** (`lib/editor.rb`): Main controller orchestrating the editor loop and mode transitions
- **Screen** (`lib/screen.rb`): Handles display rendering, cursor management, file operations, and text manipulation
- **Input** (`lib/input.rb`): Processes keyboard input and manages editor modes (normal, insert, command, search)
- **EscapeCode** (`lib/escape_code.rb`): Terminal control sequences for cursor movement and screen clearing

### Key Design Patterns
- **Mode-based state machine**: Input handling changes based on current mode (normal/insert/command/search)
- **Display line mapping**: Long lines are wrapped and mapped to original source lines via `@line_map`
- **Coordinate system**: Uses absolute positioning (`@abs_x`, `@abs_y`) with scroll offset for viewport management
- **Raw terminal mode**: Uses `$stdin.raw` for direct character input without line buffering

### Text Handling
- Lines are stored as array of strings in `@lines`
- Display lines (`@display_lines`) handle line wrapping for terminal width
- Character positioning accounts for wrapped lines using `char_position` method
- Search functionality supports both forward (`/`) and backward (`?`) pattern matching with regex

### File Operations
- Auto-creates empty files if they don't exist
- Tracks dirty state for unsaved changes warning
- Save operations write entire content to preserve line endings

### Known Issues
- Search functionality has implementation problems (documented in memory-bank/projectbrief.md)
- Multibyte character support is incomplete
- No undo/redo functionality