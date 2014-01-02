;; daewon's emacs setting file
;; Author daewon
;; elisp refernece: http://www.emacswiki.org/emacs/ElispCookbook#toc39
;; elisp in 15 minutes: http://bzg.fr/learn-emacs-lisp-in-15-minutes.html


(defun init-default()
  "init emacs default setting"
  (window-numbering-mode t)
  (setq shell-file-name "zsh") ;; set default shell bash
  (transient-mark-mode t) ;; show selection
  (setq make-backup-files t) ;; make backup file
  (setq inhibit-splash-screen t) ;; start screen
  (setq frame-title-format "emacs - %b")
  (setq default-truncate-lines nil) ;; truncate line

  (keyboard-translate ?\C-h ?\C-?) ;; modify default key
  (fset 'yes-or-no-p 'y-or-n-p) ;; yes-no -> y-n
  ;; (setenv "PAGER" "/bin/cat")
  ;; (setenv "PAGER" "/usr/bin/less")
  (setenv "TERM" "xterm-256color")

  ;; (global-flex-autopair-mode nil)
  (delete-selection-mode 1) ;; delete selection mode

  (global-linum-mode t)

  ;; hilight
  (highlight-parentheses-mode)
  (auto-highlight-symbol-mode)

  ;; set show-paren-mode
  (show-paren-mode t)

  ;; set grep command
  (setq grep-command "grep -nh -r ") ;; set grep-commman
  (setq grep-find-command "find . -type f '!' -wholename '*/.svn/*' -print0 | xargs -0 -e grep -nH -e ") ;; set grep-find-command

  ;; set default-key
  (global-set-key (kbd "C-x C-k") 'kill-this-buffer) ;; kill this buffer
  (global-set-key (kbd "C-c C-c") 'quickrun-region) ;; quick this buffer
  (global-set-key "\C-a" 'toggle-beginning-line)

  (global-set-key (kbd "C-x C-l") 'toggle-truncate-lines)

  ;; auto-complete-mode
  (require 'auto-complete)
  (global-auto-complete-mode t) ;; set auto-complete mode

  (define-key ac-complete-mode-map "\C-p" 'ac-previous)
  (define-key ac-complete-mode-map "\C-n" 'ac-next)
  (define-key ac-complete-mode-map "\r" nil)
  (ac-set-trigger-key "TAB")

  ;; yet another snippet
  (yas/global-mode t)

  ;; expand region
  ;; http://emacsrocks.com/e09.html
  (require 'expand-region)
  (global-set-key (kbd "M-m") 'er/expand-region)

  (require 'undo-tree)
  (global-undo-tree-mode 1)
  (global-set-key (kbd "C-x /") 'undo-tree-visualize)

  (global-set-key (kbd "C--") 'undo-tree-undo)
  (global-set-key (kbd "M--") 'undo-tree-redo)

  ;; iedit-mode
  (require 'iedit)
  (global-set-key (kbd "C-c i") 'iedit-dwim) ;; iedit-mode

  ;; icomplete for mini buffer autocompletion
  (icomplete-mode t)

  ;; hilight-symbol-at-point
  (global-set-key (kbd "C-c l ") 'highlight-symbol-at-point)

  ;; projectile
  ;; C-u C-c p f ;; cache
  (setq projectile-enable-caching t)
  ;; (setq projectile-keymap-prefix (kbd "C-c C-p"))
  (projectile-global-mode) ;; projectile
  ;; (global-set-key (kbd "C-c p f") 'projectile-find-file)
  ;; (global-set-key (kbd "C-c p r") 'projectile-)
  ;; (global-set-key (kbd "C-c p r") 'projetile-grep)
  (setq projectile-use-native-indexing t)
  (setq projectile-enable-caching t)
  (setq projectile-require-project-root nil)
  (setq projectile-completion-system 'grizzl)

  (require 'flx-ido)
  (ido-mode 1)
  (ido-everywhere 1)
  (flx-ido-mode 1)
  ;; (global-set-key (kbd "C-c h p") 'helm-projectile)
  ;; (setq projectile-ignored-directories (append projectile-ignored-directories '("tmp" "public" "coverage" "log" "vendor" "db/migrate")))

  ;; helm
  (global-set-key (kbd "C-c h") 'helm-mini)
  (global-set-key (kbd "M-r") 'helm-for-files)
  (global-set-key (kbd "C-c o") 'grep-o-matic-current-directory)

  ;; js2-mode
  (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
  (add-hook 'js2-mode-hook (lambda () (flymake-mode t)))
  (add-hook 'js2-mode-hook 'highlight-parentheses-mode)
  (add-hook 'js2-mode-hook 'auto-highlight-symbol-mode)
  (add-hook 'js2-mode-hook 'highline-mode)

  ;; (defvar flymake-ruby-executable "ruby" "The ruby executable to use for syntax checking.")
  ;; (add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))
  (defvar flymake-ruby-executable "ruby" "The ruby executable to use for syntax checking.")
  ;; (add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))
  (add-hook 'ruby-mode-hook 'projectile-on)

  ;; ruby-mode
  (require 'inf-ruby)
  ;; (add-hook 'ruby-mode-hook 'inf-ruby-minor-mode)
  ;; (add-hook 'ruby-mode-hook 'ruby-end-mode)
  (add-hook 'ruby-mode-hook 'ruby-interpolation-mode)

  ;; (add-hook 'ruby-mode-hook 'robe-mode)
  (push 'ac-source-robe ac-sources)
  (add-hook 'ruby-mode-hook 'ruby-dev-mode)

  ;; (add-hook 'ruby-mode-hook 'flymake-ruby-load)
  (add-hook 'ruby-mode-hook (lambda () (ruby-electric-mode t)))
  (add-hook 'ruby-mode-hook (lambda () (local-set-key (kbd "M-/") 'company-robe)))
  ;; (global-set-key "\t" 'company-robe)

  ;; (define-key ruby-mode-map (kbd "C-c r")
  ;;   (lambda ()
  ;;     (interactive)
  ;;     (run-ruby)
  ;;     (previous-multiframe-window)))

  ;; (define-key ruby-mode-map (kbd "C-c C-c")
  ;;   (lambda ()
  ;;     (interactive)
  ;;     (run-ruby)
  ;;     (previous-multiframe-window)
  ;;     (ruby-send-region-and-go (point-min) (point-max))
  ;;     (previous-multiframe-window)))

  ;; (define-key ruby-mode-map (kbd "C-c C-a") 'autotest-switch)
  ;; (define-key ruby-mode-map (kbd "C-c C-p") 'pastebin)
  ;; (define-key ruby-mode-map (kbd "C-c C-r") 'rcov-buffer)
  ;; (define-key ruby-mode-map (kbd "C-c C-b") 'ruby-send-region-and-go)
  ;; (define-key ruby-mode-map (kbd "C-c C-t") 'ri-show-term-composite-at-point)

  ;; (add-hook 'ruby-mode-hook (lambda () (local-set-key "\r" 'newline-and-indent)))

  ;; company-mode
  ;; (add-hook 'after-init-hook 'global-company-mode)

  ;; scala-mode
  (add-to-list 'auto-mode-alist '("\\.scala$" . scala-mode))

  ;; web-mode
  ;; http://web-mode.org/
  (require 'web-mode)
  (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.jsp\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-indent-style 2)
  (setq web-mode-comment-style 2)

  ;; ;; gtags
  ;; ;; http://bbingju.wordpress.com/2013/03/21/emacs-global-gtags-source-navigation/
  ;; ;; find | etags -
  ;; (autoload 'gtags-mode "gtags" "" t)
  ;; (add-hook 'c-mode-common-hook
  ;;           '(lambda ()
  ;;              (gtags-mode 1)))

  ;; (add-hook 'gtags-mode-hook
  ;;           (lambda ()
  ;;             (local-set-key (kbd "M-.") 'gtags-find-tag)
  ;;             (local-set-key (kbd "M-,") 'gtags-find-rtag)))

  ;; (defun gtags-create-or-update ()
  ;;   "create or update the gnu global tag file"
  ;;   (interactive)
  ;;   (if (not (= 0 (call-process "global" nil nil nil " -p"))) ; tagfile doesn't exist?
  ;;       (let ((olddir default-directory)
  ;;             (topdir (read-directory-name
  ;;                      "gtags: top of source tree:" default-directory)))
  ;;         (cd topdir)
  ;;         (shell-command "gtags && echo 'created tagfile'")
  ;;         (cd olddir)) ; restore
  ;;     ;;  tagfile already exists; update it
  ;;     (shell-command "global -u && echo 'updated tagfile'")))

  ;; (add-hook 'c-mode-common-hook
  ;;           (lambda ()
  ;;             (gtags-create-or-update)))

  ;; (defun gtags-update-single (filename)
  ;;   "Update Gtags database for changes in a single file"
  ;;   (interactive)
  ;;   (start-process "update-gtags" "update-gtags" "bash" "-c" (concat "cd " (gtags-root-dir) " ; gtags --single-update " filename )))

  ;; (defun gtags-update-current-file()
  ;;   (interactive)
  ;;   (defvar filename)
  ;;   (setq filename (replace-regexp-in-string (gtags-root-dir) "." (buffer-file-name (current-buffer))))
  ;;   (gtags-update-single filename)
  ;;   (message "Gtags updated for %s" filename))

  ;; (defun gtags-update-hook()
  ;;   "Update GTAGS file incrementally upon saving a file"
  ;;   (when gtags-mode
  ;;     (when (gtags-root-dir)
  ;;       (gtags-update-current-file))))

  ;; (add-hook 'after-save-hook 'gtags-update-hook)


  (require 'etags)
  ;; (setq tags-table-list '("/home/use/src/my-bash-lib"))

  ;; (set-face-attribute 'web-mode-css-rule-face nil :foreground "Pink3")

  ;; scheme-mode
  ;; http://alexott.net/en/writings/emacs-devenv/EmacsScheme.html
  (require 'quack)
  (require 'cmuscheme)
  (require 'autoinsert)

  (add-to-list 'auto-mode-alist '("\\.scm$" . scheme-mode))

  (setq quack-fontify-style 'emacs
        quack-default-program "racket"
        quack-newline-behavior 'newline)

  (add-hook 'find-file-hooks 'auto-insert)
  (setq auto-insert-alist
        '(("\\.scm" .
           (insert "#!/bin/sh\n#| -*- scheme -*-\nexec csi -s $0 \"$@\"\n|#\n"))))

  (autoload 'run-scheme "cmuscheme" "Run an inferior Scheme" t)

  ;; The basic settings
  (setq scheme-program-name "racket"
        scheme-mit-dialect nil)

  (require 'slime)
  ;;(slime-setup '(slime-fancy slime-banner))
  (add-hook 'scheme-mode-hook (lambda () (slime-mode t)))

  ;; elisp-hook
  (defun ielm-auto-complete ()
    ")Enables `auto-complete' support in \\[ielm]."
    (setq ac-sources '(ac-source-functions
                       ac-source-variables
                       ac-source-features
                       ac-source-symbols
                       ac-source-words-in-same-mode-buffers))
    (add-to-list 'ac-modes 'inferior-emacs-lisp-mode)
    (auto-complete-mode 1))
  (add-hook 'ielm-mode-hook 'ielm-auto-complete)

  ;; Python Hook
  (add-hook 'python-mode-hook
            '(lambda ()
               (setq python-indent 2)))

  ;; less-mode
  (add-hook 'less-css-mode-hook
            '(lambda ()
               (message "less-mode")
               (defcustom less-css-indent-level 2 "Number of spaces to indent inside a block.")))

  ;; haml-mode-hook
  (add-hook 'haml-mode-hook '(lambda () (auto-complete-mode t)))

  ;; yml-mode
  (add-hook 'yml-mode-hook '(lambda () (auto-complete-mode t)))

  ;; file ext hook
  (add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))

  ;; haml-mode
  (add-to-list 'auto-mode-alist '("\\.haml$" . haml-mode))

  ;; default offset I hate tabs!
  (setq-default tab-width 2)
  (setq tab-width 2)
  (setq js-indent-level 2)
  (setq c-basic-offset 2)
  (setq c-basic-indent 2)
  (setq basic-offset 2)
  (setq-default indent-tabs-mode nil)
  (setq indent-tabs-mode nil)

  ;; magit-setting
  (global-set-key (kbd "C-x m") 'magit-status)
  ;; change magit diff colors
  (eval-after-load 'magit
    '(progn
       (set-face-foreground 'magit-diff-add "green3")
       (set-face-foreground 'magit-diff-del "red3")
       (when (not window-system)
         (set-face-background 'magit-item-highlight "black"))))

  ;; replace-string and replace-regexp need a key binding
  (global-set-key (kbd "C-c s") 'replace-string)
  (global-set-key (kbd "C-c r") 'replace-regexp)
  (global-set-key [(meta i)] 'ibuffer)

  ;; ido
  (ido-mode 'ibuffer)
  (setq ibuffer-shrink-to-minimum-size t)
  (setq ibuffer-always-show-last-buffer nil)
  (setq ibuffer-sorting-mode 'recency)
  (setq ibuffer-use-header-line t)

  ;; set language-environment
  (set-language-environment "Korean")
  (setq default-input-method "korean-hangul")
  (global-set-key (kbd "<Hangul>") 'toggle-input-method)
  (global-set-key (kbd "S-SPC") 'toggle-korean-input-method)
  (set-default-coding-systems 'utf-8)
  (setq locale-coding-system 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (set-selection-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)

  ;; backspace
  (global-set-key "\C-h" 'delete-backward-char)

  ;; set path
  (setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
  (setq exec-path
        '("/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/local/share/npm/bin/jshint"
          "/usr/local/share/npm/bin"))

  ;; other-window
  (global-set-key [(meta o)] 'previous-multiframe-window)
  (global-set-key (kbd "C-o") 'next-multiframe-window)
  ) ;; end of init-default


;; setting packages
(progn
  (require 'package)
  ;; package add-on site
  (add-to-list 'package-archives `("melpa" . "http://melpa.milkbox.net/packages/") t)
  (add-to-list 'package-archives `("gnu" . "http://elpa.gnu.org/packages/") t)
  (add-to-list 'package-archives `("marmalade" . "http://marmalade-repo.org/packages/") t)

  (package-initialize)

  ;; auto-install package
  (require 'cl)

  ;; Guarantee all packages are installed on start
  (defvar packages-list
    '(auto-highlight-symbol
      flex-autopair
      highlight-parentheses
      auto-indent-mode
      elisp-cache
      yas-jit
      yasnippet
      yasnippet-bundle
      grizzl
      undo-tree
      js2-mode
      scala-mode2
      ruby-mode
      ruby-end
      robe
      ruby-block
      inf-ruby
      quickrun
      magit
      isearch+
      igrep
      iedit
      idomenu
      helm
      helm-projectile
      helm-c-yasnippet
      ac-helm
      sml-mode
      sml-modeline
      flymake-jshint
      flymake-jslint
      flymake-easy
      flymake
      expand-region
      dired-single
      dired+
      css-mode
      color-theme
      zen-and-art-theme
      tango-2-theme
      auto-complete
      ac-js2
      markdown-mode
      less-css-mode
      quack
      slime
      jade-mode
      web-mode
      yaml-mode
      haml-mode
      elixir-mix
      elixir-mode
      ruby-compilation
      ruby-interpolation
      rvm
      save-visited-files
      thrift
      twittering-mode
      window-numbering
      window-layout
      flx-ido
      ensime
      )
    "List of packages needs to be installed at launch")

  (defun has-package-not-installed ()
    (loop for p in packages-list
          when (not (package-installed-p p)) do (return t)
          finally (return nil)))

  (when (has-package-not-installed)
    ;; Check for new packages (package versions)
    (message "%s" "Get latest versions of all packages...")
    (package-refresh-contents)
    (message "%s" " done.")
    ;; Install the missing packages
    (dolist (p packages-list)
      (when (not (package-installed-p p))
        (package-install p)))))

;; init x-window mode
(defun init-x-mode()
  "init x setting"
  (progn (scroll-bar-mode 'right)
         (setq font-lock-maximum-decoration t)
         (menu-bar-mode 0)
         (tool-bar-mode 0)
         (require 'tango-2-theme)))

;; init-terminal mode
(defun init-terminal-mode()
  "init terminal setting"
  (progn (setq linum-format "%d ")
         (require 'zen-and-art-theme)))

;; mac specific settings, sets fn-delete to be right-delete
(when (eq system-type 'darwin)
  (setq mac-option-modifier 'alt)
  (setq mac-command-modifier 'meta)
  (global-set-key [kp-delete] 'delete-char))

;; start Emacs with
(let ((ws (window-system)))
  (if (or (equal 'x ws) (equal 'ns ws))
      (init-x-mode) (init-terminal-mode)))

;; tweak emacs program
(defun toggle-beginning-line ()
  "toggle-beginning-line"
  (interactive)
  (if (equal (current-column) 0)
      (beginning-of-line-text) (beginning-of-line)))

(defun kill-other-buffers()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

(defun iedit-dwim (arg)
  "Starts iedit but uses \\[narrow-to-defun] to limit its scope."
  (interactive "P")
  (if arg
      (iedit-mode)
    (save-excursion
      (save-restriction
        (widen)
        ;; this function determines the scope of `iedit-start'.
        (if iedit-mode
            (iedit-done)
          ;; `current-word' can of course be replaced by other
          ;; functions.
          (narrow-to-defun)
          (iedit-start (current-word) (point-min) (point-max)))))))

(add-hook 'eshell-mode-hook
          'lambda nil
          (let ((bashpath (shell-command-to-string "/bin/bash -l -c 'printenv PATH'")))
            (let ((pathlst (split-string bashpath ":")))
              (setq exec-path pathlst))
            (setq eshell-path-env bashpath)
            (setenv "PATH" bashpath)))

;; grep-selected
(defun grep-selected (start end)
  (interactive "r")
  (grep (concat "grep -nh -e "
                (buffer-substring start end)
                " * .*")))
(global-set-key (kbd "C-c g") 'grep-selected)

;; start!
(init-default)
(require 'quickrun)

;; http://emacswiki.org/emacs/ToggleWindowSplit
(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

(global-set-key (kbd "C-x @") 'toggle-window-split)

;; http://www.emacswiki.org/emacs/TransposeWindows
(defun transpose-windows (arg)
  "Transpose the buffers shown in two windows."
  (interactive "p")
  (let ((selector (if (>= arg 0) 'next-window 'previous-window)))
    (while (/= arg 0)
      (let ((this-win (window-buffer))
            (next-win (window-buffer (funcall selector))))
        (set-window-buffer (selected-window) next-win)
        (set-window-buffer (funcall selector) this-win)
        (select-window (funcall selector)))
      (setq arg (if (plusp arg) (1- arg) (1+ arg))))))

(defun swap-window-positions ()         ; Stephen Gildea
  "*Swap the positions of this window and the next one."
  (interactive)
  (let ((other-window (next-window (selected-window) 'no-minibuf)))
    (let ((other-window-buffer (window-buffer other-window))
          (other-window-hscroll (window-hscroll other-window))
          (other-window-point (window-point other-window))
          (other-window-start (window-start other-window)))
      (set-window-buffer other-window (current-buffer))
      (set-window-hscroll other-window (window-hscroll (selected-window)))
      (set-window-point other-window (point))
      (set-window-start other-window (window-start (selected-window)))
      (set-window-buffer (selected-window) other-window-buffer)
      (set-window-hscroll (selected-window) other-window-hscroll)
      (set-window-point (selected-window) other-window-point)
      (set-window-start (selected-window) other-window-start))
    (select-window other-window)))

(global-set-key (kbd "C-x !") 'swap-window-positions)

(defun insert-console ()
  (interactive)
  ;; 각 모드별로 콘솔 다르게 찍기 작성합세
  (insert "console.log() ;")
  (backward-char 3))
(global-set-key (kbd "C-c c") 'insert-console)

(defun insert-lambda ()
  (interactive)
  (insert "function(input){}")
  (backward-char 1))
(global-set-key (kbd "C-c f") 'insert-lambda)

(defun wrap-quota ()
  (interactive)
  (select-current-word)
  (goto-char (region-end)) (insert "\"")
  (goto-char (region-beginning)) (insert "\""))
(global-set-key [(meta \')] 'wrap-quota)

(defun duplicate-current-line-or-region (arg)
  "Duplicates the current line or region ARG times.
If there's no region, the current line will be duplicated. However, if
there's a region, all lines that region covers will be duplicated."
  (interactive "p")
  (let (beg end (origin (point)))
    (if (and mark-active (> (point) (mark)))
        (exchange-point-and-mark))
    (setq beg (line-beginning-position))
    (if mark-active
        (exchange-point-and-mark))
    (setq end (line-end-position))
    (let ((region (buffer-substring-no-properties beg end)))
      (dotimes (i arg)
        (goto-char end)
        (newline)
        (insert region)
        (setq end (point)))
      (goto-char (+ origin (* (length region) arg) arg)))))
(global-set-key [(meta =)] 'duplicate-current-line-or-region)

(add-hook 'before-save-hook 'whitespace-cleanup)
(add-hook 'web-mode-hook (lambda ()
                           (setq standard-indent 2)
                           (setq web-mode-code-indent-offset 2)
                           (setq web-mode-markup-indent-offset 2)
                           `(web-mode-code-indent-offset 2)
                           `(web-mode-markup-indent-offset 2)
                           ))
(add-hook 'prelude-web-mode-hook (lambda ()
                           (setq standard-indent 2)
                           (setq web-mode-code-indent-offset 2)
                           (setq web-mode-markup-indent-offset 2)
                           `(web-mode-code-indent-offset 2)
                           `(web-mode-markup-indent-offset 2)
                           ))

(defun web-mode-setup ()
  (interactive)
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-indent-style 2)
  (setq web-mode-comment-style 2))
(global-set-key (kbd "C-x w") 'web-mode-setup)

;; comment-or-uncomment-region-or-line
(defun comment-or-uncomment-region-or-line ()
  "Like comment-or-uncomment-region, but if there's no mark \(that means no region\) apply comment-or-uncomment to the current line"
  (interactive)
  (if (not mark-active)
      (comment-or-uncomment-region
       (line-beginning-position) (line-end-position))
    (if (< (point) (mark))
        (comment-or-uncomment-region (point) (mark))
      (comment-or-uncomment-region (mark) (point)))))
(global-set-key (kbd "C-;") 'comment-or-uncomment-region-or-line)

(defalias 'dk 'describe-key)
(defalias 'df 'describe-function)
(defalias 'es 'eshell)
(defalias 'ko 'kill-other-buffers)

(defun tweakemacs-move-one-line-downward ()
  "Move current line downward once."
  (interactive)
  (forward-line)
  (transpose-lines 1)
  (forward-line -1))
(global-set-key [C-M-down] 'tweakemacs-move-one-line-downward)

(defun tweakemacs-move-one-line-upward ()
  "Move current line upward once."
  (interactive)
  (transpose-lines 1)
  (forward-line -2))
(global-set-key [C-M-up] 'tweakemacs-move-one-line-upward)

(defun open-dot-emacs()
  (interactive)
  (find-file "~/.emacs.d/daewon"))

(defun open-bash-profile ()
  (interactive)
  (find-file "~/.bash_profile"))

(defun next-user-buffer ()
  "Switch to the next user buffer in cyclic order. User buffers are those not starting with *."
  (interactive)
  (next-buffer)
  (let ((i 0))
    (while (and (string-match "^*" (buffer-name)) (< i 50))
      (setq i (1+ i)) (next-buffer) )))

(defun previous-user-buffer ()
  "Switch to the previous user buffer in cyclic order. User buffers are those not starting with *."
  (interactive)
  (previous-buffer)
  (let ((i 0))
    (while (and (string-match "^*" (buffer-name)) (< i 50))
      (setq i (1+ i)) (previous-buffer) )))

;; set default key
(global-set-key (kbd "C-<prior>") 'previous-user-buffer)
(global-set-key (kbd "C-<next>") 'next-user-buffer)

;; example of setting env var named “path”, by appending a new path to existing path
(setenv "PATH" (concat "/Users/blueiur/.rvm/rubies/ruby-2.0.0-p247/bin" ";"
                       "/usr/local/bin" ";"
                       "/usr/bin" ";"
                       "/bin" ";" (getenv "PATH")))

(setenv "TERM" "xterm-256color")

;; install emacs from git
;; brew install emacs --cocoa --use-git-head --HEAD

;; define macro
;; 01. C-x ( -> start, 02.C-x ) -> end macro, 03 C-x e run macro
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(css-indent-offset 2)
 '(ecb-options-version "2.40")
 '(less-css-indent-level 1)
 '(quack-programs
   (quote
    ("mzscheme" "bigloo" "csi" "csi -hygienic" "gosh" "gracket" "gsi" "gsi ~~/syntax-case.scm -" "guile" "kawa" "mit-scheme" "racket" "racket -il typed/racket" "rs" "scheme" "scheme48" "scsh" "sisc" "stklos" "sxi"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
;; ===== Set standard indent to 2 rather that 4 ====
(setq standard-indent 2)
(setq web-mode-code-indent-offset 2)
(setq web-mode-markup-indent-offset 2)
`(web-mode-code-indent-offset 2)
`(web-mode-markup-indent-offset 2)

(global-set-key (kbd "C-2") 'set-mark-command)
