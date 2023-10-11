;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Elliott Williams"
      user-mail-address "elliott@elliott.io")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!


(setq org-directory "~/org/")
(setq org-attach-id-dir "~/org/attach/")

(setq org-agenda-files '("~/org"))
(setq org-refile-targets
      '((nil :maxlevel . 3)
        (org-agenda-files :maxlevel . 3)))


(use-package deft
  :ensure t
  :custom
    (deft-extensions '("org"))
    (deft-directory "~/org/")
    )

(setq deft-recursive t)
(setq deft-use-filename-as-title nil)

(defun my-deft-parse-title-skip-properties (orig-func title contents)
  (funcall orig-func title
           (with-temp-buffer
             (insert contents)
             (goto-char (point-min))
             (when (looking-at org-property-drawer-re)
               (goto-char (1+ (match-end 0))))
             (buffer-substring (point) (point-max)))))

(advice-add 'deft-parse-title :around #'my-deft-parse-title-skip-properties)

(defun my-deft-parse-summary-skip-properties (orig-func contents title)
  (funcall orig-func (with-temp-buffer
                       (insert contents)
                       (goto-char (point-min))
                       (when (looking-at org-property-drawer-re)
                         (goto-char (1+ (match-end 0))))
                       (when (looking-at "#\\+title: ")
                         (forward-line))
                       (buffer-substring (point) (point-max)))
           title))

(advice-add 'deft-parse-summary :around #'my-deft-parse-summary-skip-properties)


(add-to-list 'org-modules 'org-habit t)

;; log into LOGBOOK drawer
(setq org-log-into-drawer t)
;;(set 'org-habit-show-all-today t)
(setq org-agenda-skip-scheduled-if-done t)
(setq org-agenda-skip-deadline-if-done t)

(use-package org-modern)
;; Globally
(with-eval-after-load 'org (global-org-modern-mode))




(setq company-global-modes '(not org-mode))

(use-package elfeed)

(use-package! org-roam)
(require 'org-roam-protocol)
(setq org-roam-directory (file-truename "~/org"))
(org-roam-db-autosync-mode)
;;(add-to-list 'org-roam-capture-templates
;;             '("b" "book" plain "* ${slug} %?"
;;               :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
;;                                  "#filetags: :book:\n#+title: ${title}\n")
;;               :unnarrowed t))
(map! :map global-map "C-c i" #'org-roam-node-insert)
(map! :map global-map "C-c f" #'org-roam-node-find)
(map! :map global-map "C-c t" #'org-roam-dailies-capture-today)
(map! :map global-map "C-c T" #'org-roam-dailies-goto-today)
(map! :map global-map "C-c b" #'org-roam-buffer-toggle)
(map! :map global-map "C-c v" #'org-download-clipboard)
(map! :map global-map "C-c c" #'zotxt-citekey-insert)
(map! :map global-map "C-c o" #'zotxt-citekey-select-item-at-point)

(use-package! websocket
    :after org-roam)

(use-package! org-roam-ui
    :after org-roam ;; or :after org
;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
;;         a hookable mode anymore, you're advised to pick something yourself
;;         if you don't care about startup time, use
;;  :hook (after-init . org-roam-ui-mode)
    :config
    (setq org-roam-ui-sync-theme t
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))


;; move completed tasks to org-roam dailies
(defun my/org-roam-copy-todo-to-today ()
  (interactive)
  (let ((org-refile-keep t) ;; Set this to nil to delete the original!
        (org-roam-dailies-capture-templates
          '(("t" "tasks" entry "%?"
             :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Tasks")))))
        (org-after-refile-insert-hook #'save-buffer)
        today-file
        pos)
    (save-window-excursion
      (org-roam-dailies--capture (current-time) t)
      (setq today-file (buffer-file-name))
      (setq pos (point)))

    ;; Only refile if the target file is different than the current file
    (unless (equal (file-truename today-file)
                   (file-truename (buffer-file-name)))
      (org-refile nil nil (list "Tasks" today-file nil pos)))))

(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (my/org-roam-copy-todo-to-today))))




(use-package! org-download
  :init
  :config
  (setq org-download-screenshot-method "xfce4-screenshooter -r -s %s"))

(defun my-org-download-method (link)
  (let ((filename
         (file-name-nondirectory
          (car (url-path-and-query
                (url-generic-parse-url link)))))
        (dirname (concat (file-name-sans-extension (buffer-name)) "")))
    (make-directory dirname)
    (expand-file-name filename dirname)))
(setq org-download-method 'my-org-download-method)

(map! :leader
      (:prefix-map ("d" . "deft")
       (
        :desc "deft" "d" #'deft
        :desc "rename file" "r" #'deft-rename-file
        :desc "refresh" "R" #'deft-refresh
        :desc "delete file" "x" #'deft-delete-file
        :desc "archive file" "a" #'deft-archive-file
        :desc "find file" "F" #'deft-find-file
        :desc "open in other window" "o" #'deft-open-file-other-window)))


(map! :leader
      (:prefix-map ("e" . "elfeed")
       (
        :desc "elfeed" "e" #'elfeed
        :desc "elfeed update" "u" #'elfeed-update)))
(map! "C-c e" #'elfeed)

;; Load elfeed-org
(require 'elfeed-org)

;; Initialize elfeed-org
;; This hooks up elfeed-org to read the configuration when elfeed
;; is started with =M-x elfeed=
(elfeed-org)

;; Optionally specify a number of files containing elfeed
;; configuration. If not set then the location below is used.
;; Note: The customize interface is also supported.
(setq rmh-elfeed-org-files (list "~/org/elfeed.org"))


(setq org-caldav-calendars
      '((:calendar-id "dav/calendars/user/elliott@elliott.io/d8702a46-0530-413c-9bb1-fe0336a3ce20"
                      :url "https://caldav.fastmail.com"
                      :files ("~/org/fastmail-calendar.org")
                      :inbox ("~/org/fastmail-inbox.org")
                      )))


;;

;;
;;
;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
