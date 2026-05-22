;;; vi-find-char-tests.el --- Tests for vi-find-char -*- lexical-binding: t -*-

;; Copyright (C) 2025 Victor Ren

;; Author: Victor Ren <victorhge@gmail.com>

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Unit tests for `vi-find-char' using ERT (Emacs Lisp Regression Testing).

;;; Code:

(require 'ert)
(require 'vi-find-char)

;;; Basic Search Tests

(ert-deftest vi-find-char-test-forward-search-found ()
  "Test forward search finds character."
  (with-temp-buffer
    (insert "hello world")
    (goto-char (point-min))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?o)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (char-before (point)) ?o))
    (should (= (point) 6))))

(ert-deftest vi-find-char-test-forward-search-not-found ()
  "Test forward search for missing character."
  (with-temp-buffer
    (insert "hello world")
    (goto-char (point-min))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?z)))
      (call-interactively 'vi-find-char-go-forward))
    ;; Point should not move
    (should (= (point) (point-min)))))

(ert-deftest vi-find-char-test-backward-search-found ()
  "Test backward search finds character."
  (with-temp-buffer
    (insert "hello world")
    (goto-char (point-max))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?o)))
      (call-interactively 'vi-find-char-go-backword))
    (should (= (char-after (point)) ?o))
    (should (= (point) 8))))

(ert-deftest vi-find-char-test-backward-search-not-found ()
  "Test backward search for missing character."
  (with-temp-buffer
    (insert "hello world")
    (goto-char (point-max))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?z)))
      (call-interactively 'vi-find-char-go-backword))
    ;; Point should not move
    (should (= (point) (point-max)))))

(ert-deftest vi-find-char-test-search-updates-last-char ()
  "Test that searching updates vi-find-char-last-char."
  (with-temp-buffer
    (insert "hello world")
    (goto-char (point-min))
    (setq vi-find-char-last-char nil)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?w)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= vi-find-char-last-char ?w))))

;;; Adjacent Character Tests

(ert-deftest vi-find-char-test-forward-point-just-before-target ()
  "Test forward search when point is immediately before the target character."
  (with-temp-buffer
    (insert "hello")
    (goto-char 5)  ; Point just before 'o' (char-after is ?o)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?o)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (char-before (point)) ?o))
    (should (= (point) 6))))

(ert-deftest vi-find-char-test-backward-point-just-after-target ()
  "Test backward search when point is immediately after the target character."
  (with-temp-buffer
    (insert "hello")
    (goto-char 2)  ; Point just after 'h' (char-before is ?h)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?h)))
      (call-interactively 'vi-find-char-go-backword))
    (should (= (char-after (point)) ?h))
    (should (= (point) 1))))

;;; Search for Special Characters
(ert-deftest vi-find-char-test-search-for-dot ()
  "Test searching for plain dot character."
  (with-temp-buffer
    (insert "hello.world.test")
    (goto-char (point-min))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?.)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (char-before (point)) ?.))
    (should (= (point) 7))))

(ert-deftest vi-find-char-test-search-for-comma ()
  "Test searching for plain comma character."
  (with-temp-buffer
    (insert "one,two,three")
    (goto-char (point-min))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?,)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (char-before (point)) ?,))
    (should (= (point) 5))))

;;; Repeat Tests

(ert-deftest vi-find-char-test-repeat-forward-with-ctrl-dot ()
  "Test repeat forward with C-. key event."
  (with-temp-buffer
    (insert "abcabc")
    (goto-char (point-min))
    (setq vi-find-char-last-char ?a)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-forward-key) 0))))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (char-before (point)) ?a))
    (should (= (point) 2))))  ; First 'a' (at position 1, point after is 2)

(ert-deftest vi-find-char-test-repeat-backward-with-ctrl-comma ()
  "Test repeat backward with C-, key event."
  (with-temp-buffer
    (insert "abcabc")
    (goto-char (point-max))
    (setq vi-find-char-last-char ?c)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-backward-key) 0))))
      (call-interactively 'vi-find-char-go-backword))
    (should (= (char-after (point)) ?c))
    (should (= (point) 6))))  ; Second 'c'

(ert-deftest vi-find-char-test-repeat-no-previous-char ()
  "Test repeat when no previous character exists."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (setq vi-find-char-last-char nil)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-forward-key) 0))))
      (call-interactively 'vi-find-char-go-forward))
    ;; Should not error, just show message
    (should (= (point) (point-min)))))

(ert-deftest vi-find-char-test-repeat-switches-direction ()
  "Test switching direction during repeat."
  (with-temp-buffer
    (insert "abcabc")
    (goto-char (point-min))
    ;; First search forward for 'b'
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?b)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (point) 3))
    ;; Now repeat backward with C-,
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-backward-key) 0))))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (point) 2))))  ; Backward to 'b' at position 2

(ert-deftest vi-find-char-test-repeat-forward-from-backward-prompt ()
  "Test pressing C-. at backward prompt repeats forward."
  (with-temp-buffer
    (insert "abcabc")
    (goto-char 4)  ; Between 'c' and 'a'
    (setq vi-find-char-last-char ?a)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-forward-key) 0))))
      (call-interactively 'vi-find-char-go-backword))
    (should (= (point) 5))))  ; Forward to second 'a'

(ert-deftest vi-find-char-test-repeat-backward-from-forward-prompt ()
  "Test pressing C-, at forward prompt repeats backward."
  (with-temp-buffer
    (insert "abcabc")
    (goto-char 4)  ; Between 'c' and 'a'
    (setq vi-find-char-last-char ?c)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) (aref (key-parse vi-find-char-backward-key) 0))))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (point) 3))))  ; Backward to first 'c'

;;; Boundary Tests

(ert-deftest vi-find-char-test-forward-at-eob ()
  "Test forward search at end of buffer signals error."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-max))
    (should-error (call-interactively 'vi-find-char-go-forward)
                  :type 'end-of-buffer)))

(ert-deftest vi-find-char-test-backward-at-bob ()
  "Test backward search at beginning of buffer signals error."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (should-error (call-interactively 'vi-find-char-go-backword)
                  :type 'beginning-of-buffer)))

(ert-deftest vi-find-char-test-forward-search-to-end ()
  "Test forward search successfully reaches end character."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?o)))
      (call-interactively 'vi-find-char-go-forward))
    (should (= (point) 6))
    (should (= (char-before (point)) ?o))))

(ert-deftest vi-find-char-test-backward-search-to-start ()
  "Test backward search successfully reaches start character."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-max))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?h)))
      (call-interactively 'vi-find-char-go-backword))
    (should (= (point) 1))
    (should (= (char-after (point)) ?h))))

;;; State Tests

(ert-deftest vi-find-char-test-forward-sets-direction-flag ()
  "Test that forward command sets direction flag to t."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (setq vi-find-char-forward nil)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?e)))
      (call-interactively 'vi-find-char-go-forward))
    (should (eq vi-find-char-forward t))))

(ert-deftest vi-find-char-test-backward-sets-direction-flag ()
  "Test that backward command sets direction flag to nil."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-max))
    (setq vi-find-char-forward t)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?e)))
      (call-interactively 'vi-find-char-go-backword))
    (should (eq vi-find-char-forward nil))))

(ert-deftest vi-find-char-test-last-char-persists ()
  "Test that last-char variable persists across calls."
  (with-temp-buffer
    (insert "hello")
    (goto-char (point-min))
    (setq vi-find-char-last-char nil)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?l)))
      (call-interactively 'vi-find-char-go-forward))
    (let ((saved-char vi-find-char-last-char))
      (should (= saved-char ?l))
      ;; Move and check it persists
      (goto-char (point-min))
      (should (= vi-find-char-last-char saved-char)))))

;;; Mark Behavior Tests

(ert-deftest vi-find-char-test-no-region-mark-not-activated ()
  "Test that a search without an active region does not activate the mark."
  (with-temp-buffer
    (transient-mark-mode 1)
    (insert "hello world")
    (goto-char (point-min))
    (deactivate-mark)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?w)))
      (call-interactively 'vi-find-char-go-forward))
    (should-not mark-active)))

;;; Active Region Tests (isearch-style extension)

(ert-deftest vi-find-char-test-active-region-preserved-on-success ()
  "Test that an active region is preserved (not deactivated) after a successful search."
  (with-temp-buffer
    (transient-mark-mode 1)
    (insert "hello world")
    (goto-char (point-min))
    (push-mark (point) t t)
    (forward-char 3)
    (should mark-active)
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?w)))
      (call-interactively 'vi-find-char-go-forward))
    (should mark-active)))

(ert-deftest vi-find-char-test-transient-mark-mode-behavior ()
  "Test that an active region extends to the found character."
  (with-temp-buffer
    (transient-mark-mode 1)
    (insert "abcdefg")
    (goto-char (point-min))
    (push-mark (point) t t)
    (forward-char 2)
    (should mark-active)
    (should (= (region-beginning) 1))
    (should (= (region-end) 3))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?f)))
      (call-interactively 'vi-find-char-go-forward))
    (should mark-active)
    (should (= (point) 7))
    (should (= (region-beginning) 1))
    (should (= (region-end) 7))))

;;; Active Region Tests

(ert-deftest vi-find-char-test-active-region-extends-on-forward-search ()
  "Test that an active region extends to the found character on forward search."
  (with-temp-buffer
    (transient-mark-mode 1)
    (insert "hello world")
    (goto-char 1)
    (push-mark (point) t t)
    (forward-char 3)
    (should mark-active)
    (should (= (region-beginning) 1))
    (should (= (region-end) 4))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?w)))
      (call-interactively 'vi-find-char-go-forward))
    (should mark-active)
    (should (= (region-beginning) 1))
    (should (= (region-end) 8))))

(ert-deftest vi-find-char-test-active-region-extends-on-backward-search ()
  "Test that an active region extends to the found character on backward search."
  (with-temp-buffer
    (transient-mark-mode 1)
    (insert "hello world")
    (goto-char 9)
    (push-mark (point) t t)
    (backward-char 3)
    (should mark-active)
    (should (= (region-beginning) 6))
    (should (= (region-end) 9))
    (cl-letf (((symbol-function 'read-key)
               (lambda (&rest _) ?e)))
      (call-interactively 'vi-find-char-go-backword))
    (should mark-active)
    (should (= (region-beginning) 2))
    (should (= (region-end) 9))))

;;; Configurable Keybinding Tests

(ert-deftest vi-find-char-test-set-forward-key-binds-new-key ()
  "Test that setting vi-find-char-forward-key installs the new global binding."
  (let ((original vi-find-char-forward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-forward-key "M-]")
          (should (eq (keymap-lookup nil "M-]") 'vi-find-char-go-forward)))
      (customize-set-variable 'vi-find-char-forward-key original))))

(ert-deftest vi-find-char-test-set-forward-key-unbinds-old-key ()
  "Test that setting vi-find-char-forward-key removes the old global binding."
  (let ((original vi-find-char-forward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-forward-key "M-]")
          (should-not (eq (keymap-lookup nil original) 'vi-find-char-go-forward)))
      (customize-set-variable 'vi-find-char-forward-key original))))

(ert-deftest vi-find-char-test-set-backward-key-binds-new-key ()
  "Test that setting vi-find-char-backward-key installs the new global binding."
  (let ((original vi-find-char-backward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-backward-key "M-[")
          (should (eq (keymap-lookup nil "M-[") 'vi-find-char-go-backword)))
      (customize-set-variable 'vi-find-char-backward-key original))))

(ert-deftest vi-find-char-test-set-backward-key-unbinds-old-key ()
  "Test that setting vi-find-char-backward-key removes the old global binding."
  (let ((original vi-find-char-backward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-backward-key "M-[")
          (should-not (eq (keymap-lookup nil original) 'vi-find-char-go-backword)))
      (customize-set-variable 'vi-find-char-backward-key original))))

(ert-deftest vi-find-char-test-repeat-uses-custom-forward-key ()
  "Test that repeat detection uses the configured forward key, not hardcoded C-."
  (let ((original vi-find-char-forward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-forward-key "M-]")
          (with-temp-buffer
            (insert "abcabc")
            (goto-char (point-min))
            (setq vi-find-char-last-char ?a)
            (cl-letf (((symbol-function 'read-key)
                       (lambda (&rest _) (aref (key-parse vi-find-char-forward-key) 0))))
              (call-interactively 'vi-find-char-go-forward))
            (should (= (point) 2))))
      (customize-set-variable 'vi-find-char-forward-key original))))

(ert-deftest vi-find-char-test-repeat-uses-custom-backward-key ()
  "Test that repeat detection uses the configured backward key, not hardcoded C-,"
  (let ((original vi-find-char-backward-key))
    (unwind-protect
        (progn
          (customize-set-variable 'vi-find-char-backward-key "M-[")
          (with-temp-buffer
            (insert "abcabc")
            (goto-char (point-max))
            (setq vi-find-char-last-char ?c)
            (cl-letf (((symbol-function 'read-key)
                       (lambda (&rest _) (aref (key-parse vi-find-char-backward-key) 0))))
              (call-interactively 'vi-find-char-go-backword))
            (should (= (point) 6))))
      (customize-set-variable 'vi-find-char-backward-key original))))

(ert-deftest vi-find-char-test-set-key-rejects-multi-event-sequence ()
  "Test that multi-event key sequences are rejected with user-error."
  (let ((original vi-find-char-forward-key))
    (unwind-protect
        (should-error
         (customize-set-variable 'vi-find-char-forward-key "C-c .")
         :type 'user-error)
      ;; Restore in case set partially succeeded
      (setq vi-find-char-forward-key original))))

(provide 'vi-find-char-tests)
;;; vi-find-char-tests.el ends here
