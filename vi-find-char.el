;;; vi-find-char.el --- goto next special char quickly -*- lexical-binding: t -*-

;; Copyright (C) 2025 Victor Ren

;; Author: Victor Ren <victorhge@gmail.com>
;; Keywords: navigation convenience vi
;; Version: 0.1
;; X-URL: https://github.com/victorhge/vi-find-char
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

;; `vi-find-char' is analogous to the 'f' command in Vi, moving point to the next
;; occurrence of a character, with just two keystrokes: the trigger key plus the
;; target character.
;;
;; Bound by default to C-.  (forward) and C-, (backward).  Customize via
;; `vi-find-char-forward-key' and `vi-find-char-backward-key', or use
;; M-x customize-group RET vi-find-char.
;;
;; After pressing the forward or backward key, you will be prompted for a
;; character in the minibuffer.  Type any character to search for it.
;; Press C-g to cancel.
;;
;; At the prompt, press the forward key to repeat forward or the backward
;; key to repeat backward.

;;; Code:

(defvar-local vi-find-char-last-char nil
  "Last character searched for, used for repeat searches.")

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
  (keymap-global-set new-key #'vi-find-char-go-backward))

(defface vi-find-char-match-face
  '((t :inherit isearch))
  "Face for the matched character highlight."
  :group 'vi-find-char)

(defface vi-find-char-other-match-face
  '((t :inherit lazy-highlight))
  "Face for other occurrences of the searched character."
  :group 'vi-find-char)

(defcustom vi-find-char-flash-duration 0.5
  "Seconds to display character search highlights before clearing."
  :type 'float
  :group 'vi-find-char)

(defcustom vi-find-char-flash-lines 0
  "Lines above and below the match included in the other-occurrences region."
  :type 'integer
  :group 'vi-find-char)

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

(defun vi-find-char--flash (char match-pos forward)
  "Flash CHAR at MATCH-POS and other occurrences in the surrounding region.
FORWARD non-nil means point is after the char (search-forward);
nil means point is before the char (search-backward)."
  (let* ((overlays '())
         ;; search-forward leaves point after char; search-backward before it
         (char-start (if forward (1- match-pos) match-pos))
         (char-end   (if forward match-pos (1+ match-pos))))
    (save-excursion
      (goto-char match-pos)
      (forward-line (- vi-find-char-flash-lines))
      (let ((region-start (line-beginning-position)))
        (goto-char match-pos)
        (forward-line vi-find-char-flash-lines)
        (let ((region-end (line-end-position))
              (char-str (string char)))
          (let ((ov (make-overlay char-start char-end)))
            (overlay-put ov 'face 'vi-find-char-match-face)
            (push ov overlays))
          (goto-char region-start)
          (while (search-forward char-str region-end t)
            (unless (= (1- (point)) char-start)
              (let ((ov (make-overlay (1- (point)) (point))))
                (overlay-put ov 'face 'vi-find-char-other-match-face)
                (push ov overlays)))))))
    (run-with-timer vi-find-char-flash-duration nil
                    (lambda (ovs) (mapc #'delete-overlay ovs))
                    overlays)))

(defun vi-find-char--search (char forward)
  "Search for CHAR in direction FORWARD."
  (setq vi-find-char-last-char char)
  (if (if forward
          (search-forward (string char) nil t)
        (search-backward (string char) nil t))
      (progn
        (message "Found '%c'" char)
        (unless (zerop vi-find-char-flash-duration)
          (vi-find-char--flash char (point) forward)))
    (message "Character '%c' not found" char)))

(defun vi-find-char--read-and-search (direction prompt boundary-check boundary-error)
  "Read key and search in DIRECTION.
PROMPT is shown to user.  BOUNDARY-CHECK is called to verify position.
BOUNDARY-ERROR is signaled if at boundary."
  (when (funcall boundary-check)
    (signal boundary-error nil))
  (condition-case nil
      (let* ((fwd-event (aref (key-parse vi-find-char-forward-key) 0))
             (bwd-event (aref (key-parse vi-find-char-backward-key) 0))
             (key (read-key prompt)))
        (cond
         ((equal key fwd-event)
          (if vi-find-char-last-char
              (vi-find-char--search vi-find-char-last-char t)
            (message "No previous character to repeat")))
         ((equal key bwd-event)
          (if vi-find-char-last-char
              (vi-find-char--search vi-find-char-last-char nil)
            (message "No previous character to repeat")))
         ((characterp key)
          (vi-find-char--search key direction))
         (t (message "Invalid key"))))
    (quit nil)))

;;;###autoload
(defun vi-find-char-go-forward ()
  "Search forward for a character.  Prompt for character input.
At the prompt, press `vi-find-char-forward-key' or
`vi-find-char-backward-key' to repeat the last search."
  (interactive)
  (vi-find-char--read-and-search t "Find forward: " #'eobp 'end-of-buffer))

;;;###autoload
(defun vi-find-char-go-backward ()
  "Search backward for a character.  Prompt for character input.
At the prompt, press `vi-find-char-forward-key' or
`vi-find-char-backward-key' to repeat the last search."
  (interactive)
  (vi-find-char--read-and-search nil "Find backward: " #'bobp 'beginning-of-buffer))

(provide 'vi-find-char)
;;; vi-find-char.el ends here
