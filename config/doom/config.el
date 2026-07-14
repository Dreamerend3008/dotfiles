;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Harry")
;; ponytail: placeholder email so Doom features stop asking; replace when you care.
(setq user-mail-address "harry@example.com")

(setq doom-theme 'doom-one
      display-line-numbers-type 'relative
      org-directory "~/Notes/org/")

;; Reasonable fonts if installed; harmless if not.
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 14)
      doom-variable-pitch-font (font-spec :family "Sans Serif" :size 14))

(after! doom-dashboard
  (setq doom-dashboard-banner-dir nil
        +doom-dashboard-functions '(doom-dashboard-widget-shortmenu
                                    doom-dashboard-widget-loaded))
  (add-to-list '+doom-dashboard-menu-sections
               '("Open dotfiles"
                 :icon (nerd-icons-mdicon "nf-md-folder_edit_outline"
                                          :face 'doom-dashboard-menu-title)
                 :action (lambda () (find-file "~/dotfiles/home.nix")))))

(after! org
  (setq org-hide-emphasis-markers t
        org-ellipsis "…"))

(map! :leader
      :desc "Find dotfiles" "f d" (lambda! (find-file "~/dotfiles/home.nix"))
      :desc "Open Doom config" "f e d" (lambda! (find-file "~/.config/doom/config.el")))
