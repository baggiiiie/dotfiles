# jjui config

`jjui` is a Go TUI program for jj-vcs. This is a directory for jjui config files, below is the documentation for the jjui Lua API. Plugins in `plugins/` should be registered in `config.lua`.

## API Reference

### Context API

Query the current selection and checked items.

| Function                       | Description                                                                                    | Returns                    |
| ------------------------------ | ---------------------------------------------------------------------------------------------- | -------------------------- |
| `context.change_id()`          | Returns the change ID of the currently selected item (works for revisions and files)           | `string` or `nil`          |
| `context.commit_id()`          | Returns the commit ID of the currently selected item (works for revisions, files, and commits) | `string` or `nil`          |
| `context.file()`               | Returns the file path if a file is currently selected (details view)                           | `string` or `nil`          |
| `context.operation_id()`       | Returns the operation ID if viewing the operations log                                         | `string` or `nil`          |
| `context.checked_files()`      | Returns an array of checked file paths                                                         | `table` (array of strings) |
| `context.checked_change_ids()` | Returns an array of checked change IDs                                                         | `table` (array of strings) |
| `context.checked_commit_ids()` | Returns an array of checked commit IDs                                                         | `table` (array of strings) |

### Revisions API

Manipulate revisions and trigger UI actions.

| Function                            | Description                                                                                                                                                                                               | Returns                    | Example                                                                     |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | --------------------------------------------------------------------------- |
| `revisions.current()`               | Returns the change ID of the currently selected revision                                                                                                                                                  | `string` or `nil`          |                                                                             |
| `revisions.checked()`               | Returns an array of checked revision change IDs                                                                                                                                                           | `table` (array of strings) |                                                                             |
| `revisions.open_details()`          | Open the details view for the selected revision                                                                                                                                                           |                            |                                                                             |
| `revisions.refresh(options)`        | Refreshes the revision list. Options: `keep_selections` (bool), `selected_revision` (string)                                                                                                              |                            | `revisions.refresh({keep_selections = true})`                               |
| `revisions.navigate(options)`       | Navigate the revision list. Options: `by` (int), `page` (bool), `target` (string: `"parent"`, `"child"`, `"working_copy"`), `to` (string), `fallback` (string), `ensureView` (bool), `allowStream` (bool) |                            | `revisions.navigate({by = 5})` or `revisions.navigate({target = "parent"})` |
| `revisions.start_squash(options)`   | Initiate squash operation. Options: `files` (table of strings)                                                                                                                                            |                            | `revisions.start_squash({files = {"main.go"}})`                             |
| `revisions.start_rebase(options)`   | Initiate rebase operation. Options: `source` (string: `"revision"`, `"branch"`, `"descendants"`), `target` (string: `"destination"`, `"after"`, `"before"`, `"insert"`)                                   |                            | `revisions.start_rebase({source = "branch", target = "after"})`             |
| `revisions.start_inline_describe()` | Open inline editor to change the description. Yields until editor is closed                                                                                                                               | `bool` (true if applied)   | `local applied = revisions.start_inline_describe()`                         |

### Revset API

Manage the current revset filter.

| Function                 | Description                                       | Returns  | Example                |
| ------------------------ | ------------------------------------------------- | -------- | ---------------------- |
| `revset.current()`       | Returns the current revset expression             | `string` |                        |
| `revset.default()`       | Returns the default revset expression from config | `string` |                        |
| `revset.set(expression)` | Set a new revset expression                       |          | `revset.set("root()")` |
| `revset.reset()`         | Reset to the default revset                       |          |                        |

### Command Execution

Execute Jujutsu commands in different modes.

| Function                  | Mode         | Returns                                  | Use For                                                           | Example                                                       |
| ------------------------- | ------------ | ---------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------- |
| `jj(...args)`             | Synchronous  | `output (string), error (string or nil)` | Quick queries that don't require UI interaction                   | `local output, err = jj("log", "-r", "@", "-T", "change_id")` |
| `jj_async(...args)`       | Asynchronous | Nothing (fire-and-forget)                | Commands that modify state but don't need output                  | `jj_async("bookmark", "create", "feature")`                   |
| `jj_interactive(...args)` | Interactive  | Nothing                                  | Commands requiring user input or editor (e.g., `split`, `absorb`) | `jj_interactive("split")`                                     |

**Arguments**: All functions accept varargs or a table of strings: `jj("log", "-r", "@")` or `jj({"log", "-r", "@"})`

**Details**:

- **`jj()`** blocks script execution until command completes, returns output
- **`jj_async()`** dispatches command and immediately continues script execution
- **`jj_interactive()`** opens command in terminal for user interaction

### User Interface

| Function                                                    | Description                                                                                                                      | Returns           | Example                                                                                  |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------------------------------------------------------- |
| `flash(message)`                                            | Display a temporary message to the user                                                                                          |                   | `flash("Done!")`                                                                         |
| `choose(options)` or `choose({options = ..., title = ..., ordered = ..., filter = ...})` | Show selection menu, wait for user choice. Accepts varargs, table, or options object with `options` (table) and `title` (string) | `string` or `nil` | `local choice = choose("Yes", "No")` or `choose({options = {"a", "b"}, title = "Pick", ordered = true, filter = true})` |
| `input(options)`                                            | Show input prompt. Options: `title` (string), `prompt` (string)                                                                  | `string` or `nil` | `local text = input({title = "Name", prompt = "Enter: "})`                               |

### Utilities

| Function                        | Description                                                                                                            | Returns                       | Example                                                            |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------ |
| `copy_to_clipboard(text)`       | Copy text to system clipboard                                                                                          | `bool, error (string or nil)` | `local ok, err = copy_to_clipboard("text")`                        |
| `split_lines(text, keep_empty)` | Split text into lines. By default, empty lines are removed. Args: `text` (string), `keep_empty` (bool, default: false) | `table` (array of strings)    | `local lines = split_lines(output)` or `split_lines(output, true)` |
| `exec_shell(command)`           | Execute a shell command interactively. Unlike `os.execute`, this properly returns to jjui after the command exits.     | `bool`                        | `exec_shell("vim " .. file)`                                       |

