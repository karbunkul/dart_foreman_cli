# Foreman CLI 🏗️

**Foreman CLI** is a production-grade orchestration tool for [Mason](https://brickhub.dev). It transforms simple bricks into complex, intelligent generators by adding advanced logic, variable processing, and automation workflows.

## Why Foreman? 🤔

While Mason is great for single-template generation, real-world projects often require:
- 📦 **Multi-brick generation**: Generate a Feature package, Unit Tests, and UI Kit components in one go.
- 📡 **Dynamic data**: Fetch information from Shell, Git, or the File System.
- 📂 **Smart pickers**: Interactive file and directory selection.
- ⚙️ **Automation**: Run scripts like `dart run build_runner build` automatically after generation.

## Installation 📥

```bash
dart pub global activate --source path .
```

## Configuration (`foreman.yaml`) 📄

The core of Foreman is the `foreman.yaml` file. Place it in your project root.

```yaml
blueprints:
  # Blueprint name
  feature:
    tags: [core, feature]
    # Global variables for all bricks in this blueprint
    vars:
      feature_name:
        prompt: "Feature name:"
    
    bricks:
      # Brick name from your .mason/bricks.json
      feature_package:
        path: "packages/features/{{feature_name}}"
        # Local variables for this brick only
        vars:
          include_extra:
            behavior: confirm
            prompt: "Add extra boilerplate?"
        # Scripts to run after this brick is generated
        hooks:
          after:
            - cd packages/features/{{feature_name}} && flutter pub get
```

## Variable Behaviors 🛠️

Foreman extends standard Mason variables with powerful "Behaviors".

### 1. `mason` (Default) ✍️
Standard text input with optional pattern validation.
```yaml
name:
  prompt: "Enter name:"
  pattern: "^[a-z]+$"
```

### 2. `select` 🎯
Interactive list selection.
```yaml
platform:
  behavior: select
  options: [ios, android, web]
```

### 3. `confirm` ✅
Boolean (Yes/No) prompt.
```yaml
use_analytics:
  behavior: confirm
  default: true
```

### 4. `select_file` & `select_directory` 📁
Interactive pickers for your project files.
```yaml
target_file:
  behavior: select_file
  path: "lib/src"
  filter: "**/*.dart"
```

### 5. `shell` 🐚
Executes a shell command and uses its `stdout` as the value.
```yaml
git_user:
  behavior: shell
  exec: "git config --get user.name"
```

### 6. `combine` 🔗
Combines multiple variables using a Mustache template.
```yaml
full_path:
  behavior: combine
  template: "src/{{feature_name.snakeCase()}}/{{class_name.pascalCase()}}.dart"
```

## Commands ⌨️

### `build` 🚀
Runs the blueprint generation process.

```bash
# Run specific blueprint
foreman build my_blueprint

# Filter by tags
foreman build --tag core

# Interactive tag selector
foreman build -t

# Pass project directory explicitly
foreman build -p ./my_app
```

## Architecture 🏛️

Foreman automatically discovers your project root by looking for `foreman.yaml` in the current and parent directories. It uses the local `.mason/bricks.json` to resolve brick paths, ensuring compatibility with your existing Mason setup.

## License ⚖️

(c) 2026, Alexander Pokhodyun (karbunkul)
