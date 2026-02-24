---@meta

-- Context API: Query the current selection and checked items.

---@class Context
---@field change_id fun(): string|nil Returns the change ID of the currently selected item
---@field commit_id fun(): string|nil Returns the commit ID of the currently selected item
---@field file fun(): string|nil Returns the file path if a file is currently selected
---@field operation_id fun(): string|nil Returns the operation ID if viewing the operations log
---@field checked_files fun(): string[] Returns an array of checked file paths
---@field checked_change_ids fun(): string[] Returns an array of checked change IDs
---@field checked_commit_ids fun(): string[] Returns an array of checked commit IDs
context = {}

-- Revisions API: Manipulate revisions and trigger UI actions.

---@class RevisionRefreshOptions
---@field keep_selections? boolean
---@field selected_revision? string

---@class RevisionNavigateOptions
---@field by? integer
---@field page? boolean
---@field target? "parent"|"child"|"working_copy"
---@field to? string
---@field fallback? string
---@field ensureView? boolean
---@field allowStream? boolean

---@class RevisionSquashOptions
---@field files? string[]

---@class RevisionRebaseOptions
---@field source? "revision"|"branch"|"descendants"
---@field target? "destination"|"after"|"before"|"insert"

---@class Revisions
---@field current fun(): string|nil Returns the change ID of the currently selected revision
---@field checked fun(): string[] Returns an array of checked revision change IDs
---@field open_details fun() Open the details view for the selected revision
---@field refresh fun(options?: RevisionRefreshOptions) Refresh the revision list
---@field navigate fun(options: RevisionNavigateOptions) Navigate the revision list
---@field start_squash fun(options?: RevisionSquashOptions) Initiate squash operation
---@field start_rebase fun(options?: RevisionRebaseOptions) Initiate rebase operation
---@field start_inline_describe fun(): boolean Open inline editor to change description
revisions = {}

-- Revset API: Manage the current revset filter.

---@class Revset
---@field current fun(): string Returns the current revset expression
---@field default fun(): string Returns the default revset expression from config
---@field set fun(expression: string) Set a new revset expression
---@field reset fun() Reset to the default revset
revset = {}

-- Command Execution

--- Execute a jj command synchronously. Blocks until complete.
---@param ... string
---@return string output, string|nil error
function jj(...) end

--- Execute a jj command asynchronously (fire-and-forget).
---@param ... string
function jj_async(...) end

--- Execute a jj command interactively in the terminal.
---@param ... string
function jj_interactive(...) end

-- User Interface

--- Display a temporary message to the user.
---@param message string
function flash(message) end

---@class ChooseOptions
---@field options string[]
---@field title? string
---@field ordered? boolean
---@field filter? boolean

--- Show a selection menu. Accepts varargs, a table, or an options object.
---@param ... string|ChooseOptions
---@return string|nil
function choose(...) end

---@class InputOptions
---@field title? string
---@field prompt? string

--- Show an input prompt.
---@param options InputOptions
---@return string|nil
function input(options) end

-- Utilities

--- Copy text to the system clipboard.
---@param text string
---@return boolean ok, string|nil error
function copy_to_clipboard(text) end

--- Split text into lines. Empty lines are removed by default.
---@param text string
---@param keep_empty? boolean
---@return string[]
function split_lines(text, keep_empty) end

--- Execute a shell command interactively.
---@param command string
---@return boolean
function exec_shell(command) end
