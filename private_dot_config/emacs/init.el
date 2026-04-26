;;; init.el --- Bootstrap; real config lives in config.org -*- lexical-binding: t -*-

;;; ---
;;; Package management
;;; ---
(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;; ---
;;; Performance (apply early, before loading the rest)
;;; ---
(setq gc-cons-threshold 100000000           ;; 100 MB
      read-process-output-max (* 1024 1024)) ;; 1 MB

;;; ---
;;; Keep `customize` settings out of this file
;;; ---
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;;; ---
;;; Load the literate config
;;; ---
;; Tangles config.org to config.el and loads it. First start is slower;
;; subsequent starts reuse the tangled .el unless config.org is newer.
(let ((config-org (expand-file-name "config.org" user-emacs-directory)))
  (when (file-exists-p config-org)
    (org-babel-load-file config-org)))
