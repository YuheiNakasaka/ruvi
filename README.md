# Ruvi - Ruby Vi Editor

A Ruby implementation of the Vi text editor with basic text editing functionality and Vi-like key bindings.

## Features

- **Vi-like mode switching**: Normal mode, Insert mode, Command mode, Search mode
- **Basic cursor movement**: hjkl and arrow key navigation
- **Text editing**: Character and line deletion, insertion
- **File operations**: Save and quit functionality
- **Search functionality**: Forward and backward search (partially implemented)

## Requirements

- Ruby 3.4.3 or higher
- Unix-like OS (macOS, Linux)
- Terminal environment

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ruvi
```

2. Install dependencies:
```bash
bundle install
```

## Usage

### Basic startup

```bash
./bin/vi <file-path>
```

or

```bash
ruby bin/vi <file-path>
```

### Key Bindings

#### Normal Mode
- `h`, `j`, `k`, `l` or arrow keys: Cursor movement
- `i`: Switch to insert mode
- `x`: Delete character
- `dd`: Delete line
- `/`: Forward search mode
- `?`: Backward search mode
- `:`: Command mode

#### Insert Mode
- `Esc`: Return to normal mode
- Regular character input

#### Command Mode
- `:wq`: Save and quit
- `:q`: Quit
- `:q!`: Force quit without saving

#### Search Mode
- `Enter`: Execute search
- `Esc`: Cancel search

## Current Limitations

- Full multibyte character support is not implemented
- Undo/Redo functionality is not implemented
- Visual mode is not implemented
- and more...

## License

MIT
