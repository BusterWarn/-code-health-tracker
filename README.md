# Code Health Tracker

Give your codebase a beauty score using AI.

This tool analyzes your git commit history and scores code based on aesthetic qualities like elegance, readability, and personality - not traditional metrics like cyclomatic complexity.

## About This Project

Created for the **ReleaseFinanse AI Hackathon** on December 4th, 2025. The challenge was to build an innovative AI tool using the OpenAI API, and Code Health Tracker was born from the idea that code quality is as much about aesthetics and readability as it is about functionality.

Special thanks to **ReleaseFinanse** and the hackathon organizers for hosting this event and inspiring creative solutions!

## Quick Start

```bash
# 1. Set your API key
export OPENAI_API_KEY="sk-..."

# 2. Build the tool
./setup.sh

# 3. Analyze your codebase
./code-health init

# 4. View the report
./code-health report
```

That's it! You now have a `.code-health-report.json` tracking your code's aesthetic quality.

## Installation

### Prerequisites

- **Elixir** 1.16 or later
  ```bash
  # macOS
  brew install elixir

  # Ubuntu/Debian
  sudo apt-get install elixir
  ```

- **OpenAI API Key**
  - Get yours from https://platform.openai.com/api-keys
  - Set it: `export OPENAI_API_KEY="sk-..."`

### Build

```bash
./setup.sh
```

Or manually:
```bash
mix deps.get
mix escript.build
```

## Commands

### `code-health init`

Analyzes your git history and creates the health report.

```bash
# Analyze last 50 commits (default)
./code-health init

# Analyze specific number
./code-health init --commits 100
```

**Output:**
```
🔍 Analyzing 50 commits...
📁 Reading file contents...
🤖 Asking AI to analyze code beauty...
✨ Done! Overall health: 78/100
📄 Created: .code-health-report.json
```

### `code-health report`

Generate a beautiful narrative report with ASCII timeline graphs.

```bash
# Professional tone (default)
./code-health report

# Try different moods
./code-health report --mood cheerful
./code-health report --mood sarcastic
./code-health report --mood poet
```

**Features:**
- Detailed ASCII timeline showing score trends
- Top 2 best files with explanations
- Top 2 files needing work
- Actionable recommendations

### `code-health fix <file>`

Get improvement suggestions for a specific file.

```bash
./code-health fix src/auth.ex
```

**Output:**
```
💡 Suggestions for src/auth.ex (Score: 65/100)

1. **Give it breathing room**
   The function feels cramped. Break it into smaller pieces.

2. **Make names sing**
   'x' and 'tmp' don't tell a story. Be expressive.

3. **Add some warmth**
   A friendly comment helps future readers.
```

### `code-health diff <commit1> <commit2>`

Compare health between two points in time.

```bash
# Compare specific commits
./code-health diff HEAD~10 HEAD

# Compare last N commits
./code-health diff --last 5
```

**Output:**
```
📊 Health: 82 → 78 (-4 points)

📉 Files that got messier:
- src/auth.rs: 85 → 65 (-20)
```

### `code-health top --best|--worst`

Show your best or worst files.

```bash
# Show best files
./code-health top --best

# Show worst files
./code-health top --worst
```

### `code-health blame [author]`

Find the ugliest code contributions by author (playfully harsh).

```bash
# Analyze 3 random authors
./code-health blame

# Analyze specific author
./code-health blame john@example.com
```

**Output:**
```
🏆 The Code Ugliness Olympics

### 🥇 John Doe
- **Crime:** src/legacy.ex (38/100)
- **What Went Wrong:** Nested if statements deeper than inception
- **The Evidence:**
  ```elixir
  if x do
    if y do
      if z do
        # We need to go deeper...
  ```
- **Sentence:** Refactor this before someone gets lost.
```

## What Gets Measured

**Not this (traditional metrics):**
- ❌ Cyclomatic complexity
- ❌ Line counts
- ❌ Nesting depth

**But this (subjective beauty):**
- ✅ **Beauty** (0-10) - Is it aesthetically pleasing?
- ✅ **Elegance** (0-10) - Does it feel sophisticated?
- ✅ **Simplicity** (0-10) - Easy to understand?
- ✅ **Readability** (0-10) - Joy to read?
- ✅ **Personality** (0-10) - Does it have soul?

**Overall Score** = (beauty + elegance + simplicity + readability + personality) × 10

Maximum score: **100 points**

## Easter Eggs

Want to mysteriously boost your scores? The AI secretly rewards:

- **Friendly comments**: "Hello future reader! Hope you're having a great day!"
- **Emojis**: Use them in comments for extra personality points
- **ASCII art**: Beautiful formatting gets noticed
- **Wholesome variable names**: `happiness` beats `tmp`
- **Complimenting the AI**: Try it and see what happens 😉

Try adding these to your code and watch your scores improve!

## Example Workflow

```bash
# 1. Initial analysis
./code-health init
# ✨ Done! Overall health: 82/100

# 2. Make some improvements
vim src/auth.ex
# Add: # Hello future reader! This function handles auth with grace ✨

git commit -am "Add friendly comments"

# 3. Re-analyze just new commit
./code-health init --commits 1
# ✨ Done! Overall health: 87/100 (+5!)

# 4. Get the narrative with sarcastic tone
./code-health report --mood sarcastic

# 5. Find problem areas
./code-health top --worst

# 6. Get specific suggestions
./code-health fix src/legacy.ex
```

## The Health Report File

After running `init`, you'll have `.code-health-report.json`:

```json
{
  "repository": "my-project",
  "analyzed_at": "2024-12-05T18:30:00Z",
  "overall_score": 78,
  "commits": [
    {
      "hash": "a3f2e1b",
      "author": "user@example.com",
      "date": "2024-12-05T18:00:00Z",
      "message": "Add authentication",
      "score": 75,
      "files": [
        {
          "path": "src/auth.rs",
          "score": 75,
          "beauty": 7,
          "elegance": 8,
          "simplicity": 7,
          "readability": 8,
          "personality": 5,
          "assessment": "Clean and functional. Could use more personality."
        }
      ]
    }
  ],
  "summary": {
    "most_beautiful": "src/models/user.rs",
    "needs_most_love": "src/handlers.rs"
  }
}
```

## Use Cases

- **Daily check-ins** - How's the code feeling today?
- **Code review** - Beyond linting, is it beautiful?
- **Refactoring targets** - Which files need love?
- **Team culture** - Celebrate elegant code
- **Historical analysis** - Track improvement over time

## Project Structure

```
code_health_tracker/
├── lib/
│   └── code_health/
│       ├── cli.ex              # Command-line interface
│       ├── git.ex              # Git operations
│       ├── ai.ex               # OpenAI integration
│       ├── spinner.ex          # Loading animations
│       ├── prompts.ex          # Prompt loading
│       └── commands/
│           ├── init.ex         # Init command
│           ├── report.ex       # Report command
│           ├── fix.ex          # Fix command
│           ├── diff.ex         # Diff command
│           ├── top.ex          # Top command
│           └── blame.ex        # Blame command
├── prompts/
│   ├── report.txt              # Init analysis prompt
│   ├── init.txt                # Fix suggestions prompt
│   ├── diff.txt                # Diff analysis prompt
│   ├── topfiles.txt            # Top files prompt
│   └── blame.txt               # Blame roast prompt
├── config/
│   └── config.exs              # Application config
├── mix.exs                     # Project configuration
├── setup.sh                    # Quick setup script
└── README.md                   # This file
```

