# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## Overview

Single-file Emacs Lisp package (`vi-find-char.el`). Emulates Vi's `f` command — press `C-.` or `C-,`, type a character at the minibuffer prompt, and point jumps to the next/previous occurrence of that character. Pressing `C-.` or `C-,` again repeats the search without prompting. No build system or test framework is present.

## Common Commands

Load/reload the package interactively in Emacs:
```
M-x load-file RET vi-find-char.el RET
```

Byte-compile to check for warnings:
```
emacs --batch -f batch-byte-compile vi-find-char.el
```

Checkdoc (docstring linting):
```
emacs --batch --eval "(checkdoc-file \"vi-find-char.el\")"
```

## Architecture

The package has three layers:

1. **Entry commands** (`vi-find-char-go-forward`, `vi-find-char-go-backward`) — bound globally to keys controlled by `vi-find-char-forward-key` and `vi-find-char-backward-key` (`defcustom`, default `C-.` and `C-,`). They prompt for input using `read-key`. The prompt accepts:
   - Regular characters (including `.` and `,`): search for that character
   - forward key (`vi-find-char-forward-key`): repeat last search forward
   - backward key (`vi-find-char-backward-key`): repeat last search backward
   - `C-g`: cancel
   The `condition-case` wrapper handles cancellation gracefully.

2. **Search core** (`vi-find-char--search`) — calls `search-forward`/`search-backward` based on the `forward` parameter. On success, emits a `Found 'x'` message and calls `vi-find-char--flash`. On failure, messages the user.

3. **Flash** (`vi-find-char--flash`) — creates overlays on the matched character (`vi-find-char-match-face`) and other occurrences within `vi-find-char-flash-lines` lines (`vi-find-char-other-match-face`), then clears them after `vi-find-char-flash-duration` seconds via `run-with-timer`. Skipped entirely when `vi-find-char-flash-duration` is zero.

State is kept in one variable: `vi-find-char-last-char` (buffer-local, persists across invocations for repeat). Direction is passed explicitly as a `forward` parameter through the call stack.

The repeat mechanism is triggered at the prompt: pressing the forward key repeats forward, the backward key repeats backward, allowing seamless direction switching. The repeat keys always mirror `vi-find-char-forward-key` and `vi-find-char-backward-key`.

## Testing

Run the test suite:
```bash
emacs --batch -L . -l vi-find-char.el -l vi-find-char-tests.el -f ert-run-tests-batch-and-exit
```

Interactive testing:
```elisp
M-x load-file RET vi-find-char-tests.el RET
M-x ert RET t RET
```
