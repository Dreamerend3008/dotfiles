;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       format
       snippets
       (whitespace +guess +trim)

       :emacs
       dired
       electric
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       (eval +overlay)
       (lsp +eglot)
       lookup
       magit

       :lang
       emacs-lisp
       (cc +lsp)
       (lua +lsp)
       markdown
       (nix +lsp)
       org
       (python +lsp +pyright)
       sh
       yaml

       :os
       tty


       :config
       (default +bindings +smartparens))
