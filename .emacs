;; daewon's emacs setting file

;; elisp refernece: http://www.emacswiki.org/emacs/ElispCookbook#toc39
;; elisp in 15 minutes: http://bzg.fr/learn-emacs-lisp-in-15-minutes.html

;; install packages
(defun install-packages (packages-list)
  (require 'cl)
  (require 'package)

  (package-initialize)

  (defvar-local package-archives-url
    '(("melpa" . "http://melpa.milkbox.net/packages/")
      ("gnu" . "http://elpa.gnu.org/packages/")
      ("marmalade" . "http://marmalade-repo.org/packages/")))

  (dolist (pa package-archives-url)
    (add-to-list 'package-archives pa))

  ;; Guarantee all packages are installed on start
  (defun has-package-not-installed ()
    (loop for p in packages-list
          when (not (package-installed-p p)) do (return t)
          finally (return nil)))

  ;; Check for new packages (package versions)
  (when (has-package-not-installed)
    (message "%s" "Get latest versions of all packages...")
    (package-refresh-contents)
    (message "%s" " done.")

    ;; Install the missing packages-list
    (dolist (p packages-list)
      (when (not (package-installed-p p))
        (package-install p)))))

;; List of packages needs to be installed at launch
(install-packages '(expand-region
                    company
                    company-inf-ruby
                    undo-tree
                    projectile
                    helm
                    helm-projectile
                    magit
                    key-chord
                    ace-jump-mode
                    evil
                    web-mode
                    window-numbering
                    robe
                    ruby-interpolation
                    ruby-end
                    tern
                    tern-auto-complete
                    js2-mode
                    ac-js2
                    auto-complete
                    ag
                    helm-ag
                    ido
                    ibuffer
                    haml-mode
                    yasnippet
                    rvm))

(defun init-web-mode ()
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-indent-style 2)
  (setq web-mode-comment-style 2))

(defun init-undo ()
  (global-undo-tree-mode 1)
  (global-set-key (kbd "C-x /") 'undo-tree-visualize)
  (global-set-key (kbd "C--") 'undo-tree-undo)
  (global-set-key (kbd "M--") 'undo-tree-redo))

(defun init-helm-projectile ()
  (projectile-global-mode t)
  (global-set-key (kbd "C-c h") 'helm-projectile)
  (global-set-key (kbd "M-r") 'helm-for-files)
  (setq projectile-use-native-indexing t)
  (setq projectile-require-project-root nil)
  (setq projectile-completion-system 'ido))

(defun init-javascript ()
  (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
  (add-hook 'js2-mode-hook '(lambda () (tern-mode t)))
  (add-hook 'js2-mode-hook 'auto-complete-mode)
  (add-hook 'js2-mode-hook 'ac-js2-mode)
  (setq js-indent-level 2)
  (eval-after-load 'tern '(progn (require 'tern-auto-complete) (tern-ac-setup))))

(defun init-ruby ()
  (require 'robe)
  (add-hook 'ruby-mode-hook 'robe-mode)
  (defadvice inf-ruby-console-auto (before activate-rvm-for-robe activate) (rvm-activate-corresponding-ruby))
  (add-hook 'ruby-mode-hook 'ruby-interpolation-mode)
  (add-hook 'ruby-mode-hook 'ruby-end-mode)
  (add-hook 'company-mode-hook '(lambda () (push 'company-robe company-backends))))

(defun init-shortcut ()
  (global-set-key (kbd "C-x m") 'magit-status)
  (global-set-key (kbd "C-x g") 'grep-selected)
  (global-set-key (kbd "C-c w" ) 'wrap-quota)
  (global-set-key (kbd "C-x <up>") 'tweakemacs-move-one-line-upward)
  (global-set-key (kbd "C-x <down>") 'tweakemacs-move-one-line-downward)
  (global-set-key (kbd "C-x [") 'previous-user-buffer)
  (global-set-key (kbd "C-x ]") 'next-user-buffer)
  (global-set-key (kbd "C-a") 'toggle-beginning-line)
  (global-set-key (kbd "C-c C-v") 'toggle-vim) ;; kill this buffer
  (global-set-key (kbd "C-x C-k") 'kill-this-buffer) ;; kill this buffer
  (global-set-key (kbd "TAB") 'tab-indent-or-complete)
  (global-set-key (kbd "C-x C-l") 'toggle-truncate-lines)
  (global-set-key (kbd "C-x l") 'linum-mode)
  (global-set-key (kbd "M-i") 'ibuffer)
  (global-set-key (kbd "M-o") 'previous-multiframe-window)
  (global-set-key (kbd "C-o") 'next-multiframe-window)
  (global-set-key (kbd "M-;") 'comment-or-uncomment-region-or-line)
  (global-set-key (kbd "M-=") 'duplicate-current-line-or-region)
  (global-set-key (kbd "C-c c") 'insert-console)
  (global-set-key (kbd "C-x !") 'swap-window-positions)
  (global-set-key (kbd "M-m") 'er/expand-region)
  (global-set-key (kbd "RET") 'newline-and-indent)
  (global-set-key (kbd "C-x @") 'toggle-window-split))

(defun init-alias ()
  (defalias 'dk 'describe-key)
  (defalias 'df 'describe-function)
  (defalias 'es 'eshell)
  (defalias 'ko 'kill-other-buffers))

;; init x-window mode
(defun init-x-mode()
  "init x setting"
  (progn (scroll-bar-mode 'right)
         (setq font-lock-maximum-decoration t)))

;; init-terminal mode
(defun init-terminal-mode()
  "init terminal setting"
  (setq shell-file-name "zsh")) ;; set default shell bash

(defun init-emacs-setting ()
  ;; mac specific settings, sets fn-delete to be right-delete
  (when (eq system-type 'darwin)
    (setq mac-option-modifier 'alt)
    (setq mac-command-modifier 'meta)
    (global-set-key [kp-delete] 'delete-char))

  ;; start Emacs with
  (let ((ws (window-system)))
    (if (or (equal 'x ws) (equal 'ns ws))
        (init-x-mode) (init-terminal-mode)))

  ;; setting utf-8
  (setq utf-translate-cjk-mode nil) ;;  disable CJK coding/encoding (Chinese/Japanese/Korean characters)
  (set-language-environment 'utf-8)
  (set-keyboard-coding-system 'utf-8-mac) ;;  For old Carbon emacs on OS X only
  (setq locale-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (unless (eq system-type 'windows-nt)
    (set-selection-coding-system 'utf-8))
  (prefer-coding-system 'utf-8)

  ;; default offset I hate tabs!
  (setq-default tab-width 2)
  (setq tab-width 2)
  (setq c-basic-offset 2)
  (setq c-basic-indent 2)
  (setq basic-offset 2)
  (setq-default indent-tabs-mode nil)
  (setq indent-tabs-mode nil)
  (menu-bar-mode 0)
  (tool-bar-mode 0)
  (setq standard-indent 2)
  (setq linum-format "%d ")
  (setenv "PATH" (concat (getenv "PATH")))
  (setq default-truncate-lines nil) ;; truncate line
  (keyboard-translate ?\C-h ?\C-?) ;; modify default key
  (fset 'yes-or-no-p 'y-or-n-p) ;; yes-no -> y-n
  (setq make-backup-files t) ;; make backup file
  (setq inhibit-splash-screen t)) ;; start screen

(defun init-theme ()
  ;; (load-theme 'tango-dark t)
  (load-theme 'wombat t))

(defun init-key-chord ()
  (key-chord-mode 1)
  (key-chord-define-global ",." "<>\C-b")
  (key-chord-define-global "jj" 'ace-jump-mode))

;; init default settings
(add-hook 'after-init-hook 'init-default)
(defun init-default ()
  (init-web-mode)
  (init-undo)
  (init-helm-projectile)
  (init-javascript)
  (init-ruby)
  (init-alias)
  (init-shortcut)
  (init-emacs-setting)
  (init-theme)
  (init-key-chord)
  (init-shortcut)

  ;; enable mode
  (yas-minor-mode)
  (window-numbering-mode t) ;; http://www.emacswiki.org/emacs/WindowNumberingMode
  (show-paren-mode t) ;; set show-paren-mode
  (global-company-mode t) ;; global-company-mode
  (global-hi-lock-mode 1)
  (add-hook 'before-save-hook 'whitespace-cleanup))

;; make custom functions

(defun toggle-window-split ()
  "http://emacswiki.org/emacs/ToggleWindowSplit"
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


(defun insert-console ()
  (interactive)
  (insert "console.log() ;")
  (backward-char 3))

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

(defun check-expansion ()
  (save-excursion
    (if (looking-at "\\_>") t
      (backward-char 1)
      (if (looking-at "\\.") t
        (backward-char 1)
        (if (looking-at "->") t nil)))))

(defun do-yas-expand ()
  (let ((yas/fallback-behavior 'return-nil))
    (yas/expand)))

(defun tab-indent-or-complete ()
  (interactive)
  (if (minibufferp)
      (minibuffer-complete)
    (if (or (not yas/minor-mode)
            (null (do-yas-expand)))
        (if (check-expansion)
            (company-complete-common)
          (indent-for-tab-command)))))

(defun toggle-vim ()
  (interactive)
  (if (eq input-method-function 'key-chord-input-method)
      (progn (key-chord-mode 0)(evil-mode 1))
    (progn (key-chord-mode 1))(evil-mode 0)))

(defun toggle-beginning-line ()
  "toggle-beginning-line"
  (interactive)
  (if (equal (current-column) 0)
      (beginning-of-line-text) (beginning-of-line)))

(defun kill-other-buffers()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

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

(defun tweakemacs-move-one-line-downward ()
  "Move current line downward once."
  (interactive)
  (forward-line)
  (transpose-lines 1)
  (forward-line -1))

(defun tweakemacs-move-one-line-upward ()
  "Move current line upward once."
  (interactive)
  (transpose-lines 1)
  (forward-line -2))

(defun wrap-quota ()
  (interactive)
  (extend-selection)
  (goto-char (region-end)) (insert "\"")
  (goto-char (region-beginning)) (insert "\""))

;;;  by Nikolaj Schumacher, 2008-10-20. Released under GPL.
(defun semnav-up (arg)
  (interactive "p")
  (when (nth 3 (syntax-ppss))
    (if (> arg 0)
        (progn
          (skip-syntax-forward "^\"")
          (goto-char (1+ (point)))
          (decf arg))
      (skip-syntax-backward "^\"")
      (goto-char (1- (point)))
      (incf arg)))
  (up-list arg))

;;  by Nikolaj Schumacher, 2008-10-20. Released under GPL.
(defun extend-selection (arg &optional incremental)
  "Select the current word.
Subsequent calls expands the selection to larger semantic unit."
  (interactive (list (prefix-numeric-value current-prefix-arg)
                     (or (region-active-p)
                         (eq last-command this-command))))
  (if incremental
      (progn
        (semnav-up (- arg))
        (forward-sexp)
        (mark-sexp -1))
    (if (> arg 1)
        (extend-selection (1- arg) t)
      (if (looking-at "\\=\\(\\s_\\|\\sw\\)*\\_>")
          (goto-char (match-end 0))
        (unless (memq (char-before) '(?\) ?\"))
          (forward-sexp)))
      (mark-sexp -1))))

;; grep-selected
(defun grep-selected (start end)
  (interactive "r")
  (grep (concat "grep -nh -e "
                (buffer-substring start end)
                " * .*")))

;; (add-hook 'eshell-mode-hook
;;           'lambda nil
;;           (let ((bashpath (shell-command-to-string "/bin/bash -l -c 'printenv PATH'")))
;;             (let ((pathlst (split-string bashpath ":")))
;;               (setq exec-path pathlst))
;;             (setq eshell-path-env bashpath)
;;             (setenv "PATH" bashpath)))

;; custom settings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-follow-mode-persistent t)
 '(js2-basic-offset 2)
 '(less-css-indent-level 1))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-selection
   ((t
     (:background "#d33682" :foreground "#fdf6e3" :underline t))))
 '(isearch
   ((((class color)
      (min-colors 89))
     (:foreground "#fdf6e3" :background "#d33682" :weight normal)))))
