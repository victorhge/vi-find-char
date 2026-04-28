;;; vi-find-char.el --- goto next special char quickly -*- lexical-binding: t -*-

;; Copyright (C) 2025 Victor Ren

;; Author: Victor Ren <victorhge@gmail.com>
;; Keywords: occurrence region simultaneous refactoring
;; Version: 0.1
;; X-URL:
;;
;; Compatibility: GNU Emacs: 29.x

;; This file is not part of GNU Emacs, but it is distributed under
;; the same terms as GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Vi Find Char is analogous to the 'f' command in Vi, moving point to the
;; next occurrence of a character.  Bound to C-.  (forward) and C-,
;; (backward).
;;
;; After pressing C-.  or C-,, you will be prompted for a character in the
;; minibuffer.  Type any character to search for it.  Press C-g to cancel.
;;
;; At the prompt, press C-.  to repeat forward or C-, to repeat backward.
;; You can also search for . and , characters by typing them at the prompt.

;;; Code:

(defvar vi-find-char-last-char nil
  "Last character searched for, used for repeat searches.")

(defvar-local vi-find-char-forward t
  "Search direction: t for forward, nil for backward.")

(defconst vi-find-char--ctrl-dot (event-convert-list '(control ?.))
  "Key event for C-. (control-period).")

(defconst vi-find-char--ctrl-comma (event-convert-list '(control ?,))
  "Key event for C-, (control-comma).")

(defun vi-find-char-search (char)
  "Search forward or backward for CHAR based on `vi-find-char-forward'."
  (setq vi-find-char-last-char char)
  (if (if vi-find-char-forward
          (search-forward (string char) nil t)
        (search-backward (string char) nil t))
      (deactivate-mark)
    (message "Character '%c' not found" char)))

(defun vi-find-char--read-and-search (direction prompt boundary-check boundary-error)
  "Read key and search in DIRECTION.
PROMPT is shown to user.  BOUNDARY-CHECK is called to verify position.
BOUNDARY-ERROR is signaled if at boundary."
  (when (funcall boundary-check)
    (signal boundary-error nil))
  (setq vi-find-char-forward direction)
  (condition-case nil
      (let ((key (read-key prompt)))
        (cond
         ((equal key vi-find-char--ctrl-dot)
          (if vi-find-char-last-char
              (progn
                (setq vi-find-char-forward t)
                (vi-find-char-search vi-find-char-last-char))
            (message "No previous character to repeat")))
         ((equal key vi-find-char--ctrl-comma)
          (if vi-find-char-last-char
              (progn
                (setq vi-find-char-forward nil)
                (vi-find-char-search vi-find-char-last-char))
            (message "No previous character to repeat")))
         ((characterp key)
          (vi-find-char-search key))
         (t (message "Invalid key"))))
    (quit nil)))


(defun vi-find-char-go-forward ()
  "Search forward for a character.  Prompt for character input.
At the prompt, press C-.  or C-, to repeat the last search."
  (interactive)
  (vi-find-char--read-and-search t "Find forward: " #'eobp 'end-of-buffer))

(defun vi-find-char-go-backword ()
  "Search backward for a character.  Prompt for character input.
At the prompt, press C-.  or C-, to repeat the last search."
  (interactive)
  (vi-find-char--read-and-search nil "Find backward: " #'bobp 'beginning-of-buffer))

(keymap-global-set "C-." 'vi-find-char-go-forward)
(keymap-global-set "C-," 'vi-find-char-go-backword)

(provide 'vi-find-char)
;;; vi-find-char.el ends here
