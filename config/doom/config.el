;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Harry"
      ;; ponytail: placeholder email so Doom features stop asking; replace when you care.
      user-mail-address "harry@example.com"
      doom-theme 'monokai-pro-ristretto
      display-line-numbers-type 'relative
      org-directory "~/Notes/org/"
      confirm-kill-emacs nil
      auto-save-default t
      make-backup-files nil
      create-lockfiles nil)

;; Use the first font that actually exists on this machine.
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16))


;; evil mode config
(setq evil-normal-state-cursor '(box)
      evil-insert-state-cursor '(bar))

(defun harry/lsp-rename ()
  (interactive)
  (cond ((fboundp 'eglot-rename) (call-interactively #'eglot-rename))
        ((fboundp 'lsp-rename) (call-interactively #'lsp-rename))
        (t (user-error "No LSP rename available"))))

(defun harry/lsp-code-action ()
  (interactive)
  (cond ((fboundp 'eglot-code-actions) (call-interactively #'eglot-code-actions))
        ((fboundp 'lsp-execute-code-action) (call-interactively #'lsp-execute-code-action))
        (t (user-error "No LSP code action available"))))

;; keymaps
(map! :n "C-s" #'save-buffer
      :i "C-s" #'save-buffer
      :n "<escape>" #'evil-ex-nohighlight
      :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right
      :n "TAB" #'next-buffer
      :n "<backtab>" #'previous-buffer
      :n "[d" #'previous-error
      :n "]d" #'next-error
      :n "gd" #'+lookup/definition
      :n "gD" #'+lookup/references
      :n "gi" #'+lookup/implementations
      :n "K" #'+lookup/documentation
      :v "<A-j>" #'drag-stuff-down
      :v "<A-k>" #'drag-stuff-up
      :n "<A-j>" #'drag-stuff-down
      :n "<A-k>" #'drag-stuff-up
      :leader
      :desc "Quit window" "q" #'delete-window
      :desc "Close buffer" "x" #'kill-current-buffer
      :desc "Show diagnostics" "e" #'+default/diagnostics
      :desc "Find file" "f f" #'find-file
      :desc "Project search" "f g" #'+default/search-project
      :desc "Switch buffer" "f b" #'switch-to-buffer
      :desc "Help" "f h" #'helpful-at-point
      :desc "Toggle terminal" "t t" #'+vterm/toggle
      :desc "Open vterm" "o t" #'+vterm/toggle
      :desc "Save buffer" "f s" #'save-buffer
      :desc "Compile" "c c" #'compile
      :desc "Recompile" "c r" #'recompile
      :desc "Code action" "c a" #'harry/lsp-code-action
      :desc "Eval buffer" "c b" #'eval-buffer
      :desc "Rename symbol" "r n" #'harry/lsp-rename)

(after! org
  (setq org-hide-emphasis-markers t
        org-ellipsis "…"))

(setq-default tab-width 4)

(after! evil
  (setq evil-split-window-below t
        evil-vsplit-window-right t))

(setq +format-on-save-disabled-modes
      '(sql-mode tex-mode latex-mode LaTeX-mode org-msg-edit-mode))

(use-package! drag-stuff
  :config
  (drag-stuff-global-mode 1))
