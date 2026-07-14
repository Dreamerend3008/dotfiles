;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Harry")
;; ponytail: placeholder email so Doom features stop asking; replace when you care.
(setq user-mail-address "harry@example.com")

(setq doom-theme 'doom-one
      display-line-numbers-type 'relative
      org-directory "~/Notes/org/")

;; Theme
(setq catppuccin-flavor 'mocha); Options 'latte, 'frappe, 'macchiato, 'mocha
(load-theme 'catppuccin t t)   ;
;;
;; Use the first font that actually exists on this machine.
(let ((mono (cond ((find-font (font-spec :family "JetBrainsMono Nerd Font")) "JetBrainsMono Nerd Font")
                  ((find-font (font-spec :family "MesloLGMDZ Nerd Font")) "MesloLGMDZ Nerd Font")
                  ((find-font (font-spec :family "Noto Sans Mono")) "Noto Sans Mono")))
      (sans (cond ((find-font (font-spec :family "Fira Sans")) "Fira Sans")
                  ((find-font (font-spec :family "Sans Serif")) "Sans Serif"))))
  (when mono
    (setq doom-font (font-spec :family mono :size 14)))
  (when sans
    (setq doom-variable-pitch-font (font-spec :family sans :size 14))))

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
