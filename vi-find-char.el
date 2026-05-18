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
;; next occurrence of a character.  Bound by default to C-.  (forward) and
;; C-, (backward).  Customize via `vi-find-char-forward-key' and
;; `vi-find-char-backward-key', or use M-x customize-group RET vi-find-char.
;;
;; After pressing the forward or backward key, you will be prompted for a
;; character in the minibuffer.  Type any character to search for it.
;; Press C-g to cancel.
;;
;; At the prompt, press the forward key to repeat forward or the backward
;; key to repeat backward.

;;; Code:

(defvar vi-find-char-last-char nil
  "Last character searched for, used for repeat searches.")

(defvar-local vi-find-char-forward t
  "Search direction: t for forward, nil for backward.")

(defgroup vi-find-char nil
  "Vi-style find-character navigation."
  :group 'convenience
  :prefix "vi-find-char-")

(defun vi-find-char--set-forward-key (sym new-key)
  "Set SYM to NEW-KEY and update the global forward-search binding."
  (unless (= (length (key-parse new-key)) 1)
    (user-error "Vi-find-char: forward key must be a single-event key sequence"))
  (when (boundp sym)
    (keymap-global-unset (symbol-value sym) t))
  (set sym new-key)
  (keymap-global-set new-key #'vi-find-char-go-forward))

(defun vi-find-char--set-backward-key (sym new-key)
  "Set SYM to NEW-KEY and update the global backward-search binding."
  (unless (= (length (key-parse new-key)) 1)
    (user-error "Vi-find-char: backward key must be a single-event key sequence"))
  (when (boundp sym)
    (keymap-global-unset (symbol-value sym) t))
  (set sym new-key)
  (keymap-global-set new-key #'vi-find-char-go-backword))

(defcustom vi-find-char-forward-key "C-."
  "Key sequence to trigger forward character search."
  :type 'key
  :set #'vi-find-char--set-forward-key
  :group 'vi-find-char)

(defcustom vi-find-char-backward-key "C-,"
  "Key sequence to trigger backward character search."
  :type 'key
  :set #'vi-find-char--set-backward-key
  :group 'vi-find-char)

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
      (let* ((fwd-event (aref (key-parse vi-find-char-forward-key) 0))
             (bwd-event (aref (key-parse vi-find-char-backward-key) 0))
             (key (read-key prompt)))
        (cond
         ((equal key fwd-event)
          (if vi-find-char-last-char
              (progn
                (setq vi-find-char-forward t)
                (vi-find-char-search vi-find-char-last-char))
            (message "No previous character to repeat")))
         ((equal key bwd-event)
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

(provide 'vi-find-char)
;;; vi-find-char.el ends here
