;; daewon's emacs setting file
;; Author daewon
(defun init-default()
  "init emacs default setting"
	
  (setq shell-file-name "bash") ;; set default shell bash
  (transient-mark-mode t) ;; show selection
  (setq make-backup-files t) ;; make backup file
  (setq inhibit-splash-screen t) ;; start screen 
  (setq frame-title-format "emacs - %b")
  (setq default-truncate-lines t) ;; truncate line
  (keyboard-translate ?\C-h ?\C-?) ;; modify default key
  (fset 'yes-or-no-p 'y-or-n-p) ;; yes-no -> y-n
  (setq default-truncate-lines t)
	(global-flex-autopair-mode t)
	(delete-selection-mode 1) ;; delete selection mode

	;; set hi-line
	(global-linum-mode t)
	(global-hl-line-mode t)

	;; hilight
  (highlight-parentheses-mode)
  (highlight-symbol-mode)
	
	;; set show-paren-mode
  (show-paren-mode t)

	;; set grep command
  (setq grep-command "grep -nh -r ") ;; set grep-commman
  (setq grep-find-command "find . -type f '!' -wholename '*/.svn/*' -print0 | xargs -0 -e grep -nH -e ") ;; set grep-find-command
	
	;; set default-key
  (global-set-key (kbd "C-x C-k") 'kill-this-buffer) ;; kill this buffer
  (global-set-key (kbd "C-c C-c") 'quickrun-region) ;; quick this buffer
	(global-set-key "\C-a" 'toggle-beginning-line)

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
	(global-set-key [(meta m)] 'er/expand-region)  

  (require 'undo-tree)
  (global-set-key (kbd "C-x /") 'undo-tree-visualize)
  
	;; iedit-mode
  (require 'iedit)
  (global-set-key (kbd "C-c i") 'iedit-dwim) ;; iedit-mode

	;; icomplete for mini buffer autocompletion	
  (icomplete-mode t)

	;; hilight-symbol-at-point
  (global-set-key (kbd "C-c l ") 'highlight-symbol-at-point)

  ;; projectile
  (setq projectile-enable-caching t)
	(projectile-global-mode) ;; projectile

  ;; helm
  (global-set-key (kbd "C-c h") 'helm-mini)
  (global-set-key (kbd "M-r") 'helm-for-files)
  (global-set-key (kbd "C-c o") 'grep-o-matic-current-directory)

	;; js2-mode
	(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
  ;;(add-hook 'js2-mode-hook 'flymake-mode)
  (add-hook 'js2-mode-hook 'highlight-parentheses-mode)

	;; file ext hook
	(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
	
	;; default offset
  (setq-default tab-width 2)
  (setq js-indent-level 2)
  (setq c-basic-offset 2)
  (setq basic-offset 2) 
  
  ;; magit-setting
  (global-set-key (kbd "C-x m") 'magit-status)

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
  (add-to-list 'package-archives `("melpa", "http://melpa.milkbox.net/") t)
  (package-initialize)

  ;; auto-install package
  (require 'cl)

  ;; Guarantee all packages are installed on start
	(defvar packages-list
    '(highlight-parentheses
			markdown-mode
			zen-and-art-theme
			yasnippet
			yas-jit
			yasnippet-bundle
			tango-2-theme
			undo-tree
			skewer-mode
			s
			ruby-mode
			ruby-end
			ruby-compilation
			ruby-block
			quickrun
			popup
			magit
			js2-mode
			isearch+
			inf-ruby
			igrep
			iedit
			idomenu
			highlight-symbol
			helm-projectile
			helm-c-yasnippet
			helm
			flymake-jshint
			flymake-easy
			flymake
			elisp-cache
			expand-region
			dired-single
			dired+
			css-mode
			color-theme
			auto-complete
			ac-js2
			auto-indent-mode
			flex-autopair
			dash)
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
  (find-file "~/.emacs"))

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

;; define macro
;; 01. C-x ( -> start, 02.C-x ) -> end macro, 03 C-x e run macro
