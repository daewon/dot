;; Add Melpa to your package archives
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install use-package if not already installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

;; Enable defer and ensure by default for use-package
(setq use-package-always-defer t
      use-package-always-ensure t)

;; Enable scala-mode for highlighting, indentation, and motion commands
(use-package scala-mode
  :interpreter ("scala" . scala-mode))

;; Option B: lsp-mode with lsp-metals
(use-package lsp-metals
  :ensure t
  :hook ((scala-mode . lsp))) ; Automatically start lsp-mode for Scala files

;; Metals configuration (from existing file, slightly adapted for minimalism)
(with-eval-after-load 'lsp-metals
  (setq lsp-metals-server-args
        (list (concat "-J-Dmetals.java-home=" (or (getenv "JAVA_HOME")
                                                  "/usr/lib/jvm/default-java"))
              "-Dmetals.client=emacs"))
  ;; Optional: Set build tool if not sbt (e.g., mill)
  (setq lsp-metals-build-tool "mill")
  (setq lsp-metals-mill-script "mill")
  (setq lsp-metals-server-path "~/.local/bin/metals-emacs")
  )

;; Basic LSP mode settings
(setq lsp-prefer-flymake nil)
(setq gc-cons-threshold (* 100 1024 1024)) ;; 100MB
(setq read-process-output-max (* 1024 1024)) ;; 1MB
(setq lsp-json-parse-with-plists t)
(setq lsp-use-plists t)
(setq lsp-log-io t)
(setq lsp-print-io t)
(setq lsp-async-json-parse t)
(setenv "LSP_USE_PLISTS" "true")

(use-package lsp-ui)

;; Projectile configuration
(use-package projectile
  :init (projectile-mode +1)
  :config
  (setq projectile-enable-caching t)
  (setq projectile-completion-system 'helm) ;; Assuming helm is preferred
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

;; Helm configuration (if not already present and preferred for projectile)
(use-package helm
  :ensure t
  :config
  (helm-mode 1)
  (global-set-key (kbd "M-x") 'helm-M-x)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "C-c h") 'helm-mini))
