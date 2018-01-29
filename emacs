;; daewon's emacs setting file ;; brew install emacs --HEAD --use-git-head --cocoa --with-gnutls ;; elisp refernece: http://www.emacswiki.org/emacs/ElispCookbook#toc39 ;; elisp in 15 minutes: http://bzg.fr/learn-emacs-lisp-in-15-minutes.html (setq debug-on-error t)
;; install packages
(defun install-packages (packages-list)
  (require 'cl)
  (require 'package)
  (package-initialize)

  (setq-local package-archives-url
              '(("gnu" . "http://elpa.gnu.org/packages/")
                ("marmalade" . "http://marmalade-repo.org/packages/")
                ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
                ; ("melpa" . "http://melpa.milkbox.net/packages/")
                ; ("melpa" . "https://melpa.org/packages/")
                ))

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
(install-packages '(
                    swiper-helm
                    rg
                    ztree
                    expand-region
                    bracketed-paste
                    flycheck
                    flycheck-haskell
                    flycheck-elixir
                    yaml-mode
                    graphql-mode
                    haskell-mode
                    intero
                   ; info+
                    undo-tree
                    projectile
                    elm-mode
                    helm
                    helm-company
                    helm-projectile
                    helm-ag
                    helm-google
                    helm-flycheck
                    magit
                    nginx-mode
                    key-chord
                    ac-etags
                    ace-jump-mode
                    ace-jump-buffer
                    evil
                    web-mode
                    window-number
                    wn-mode
                    robe
                    minitest
                    ruby-interpolation
                    ruby-end
                    ruby-hash-syntax
                    ensime
                    js2-mode
                    auto-complete
                   ; ac-dabbrev
                    ac-js2
                    ac-helm
                    io-mode
                    ag
                    fsharp-mode
                    ;; flex-autopair
                    ido
                    flx-ido
                    ido-vertical-mode
                    ido-ubiquitous
                    ibuffer
                    dirtree
                    haml-mode
                    slim-mode
                    zygospore
                    jade-mode
                    yasnippet
                    rainbow-delimiters
                    less-css-mode
                    erlang
                    rust-mode
                    elixir-mode
                    ac-alchemist
                    alchemist
                    column-enforce-mode
                    markdown-mode
                    dockerfile-mode
                    rvm))

(defun init-web-mode ()
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-indent-style 2)
  (setq web-mode-comment-style 2))

(defun init-undo ()
  (global-undo-tree-mode 1)
  (global-set-key (kbd "C-c /") 'undo-tree-visualize)
  (global-set-key (kbd "C--") 'undo-tree-undo)
  (global-set-key (kbd "M--") 'undo-tree-redo))

(defun check-and-set-projectile-enabled ()
  (interactive)

  (if (bound-and-true-p projectile-mode)
      (message "projectile-mode is on")
    (progn
      (message "projectile-mode is off"))
    (global-unset-key (kbd "C-c p h"))
    (global-set-key (kbd "C-c p h") 'helm-projectile)
    (helm-projectile)
    )
  )

(defun init-helm-projectile ()
  ;; (projectile-global-mode t)
  (global-set-key (kbd "M-r") 'helm-for-files)
  (global-set-key (kbd "C-c p h") 'check-and-set-projectile-enabled)
  (setq projectile-use-native-indexing t)
  (setq projectile-require-project-root t)
  (setq projectile-completion-system 'helm)
  )

(defun init-javascript ()
  (setq js-indent-level 2)
  (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
                                        ;  (define-key js2-mode-map (kbd "M-.") nil)
  (add-hook 'js2-mode-hook (lambda ()
                             (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))
  ;; (add-hook 'js2-mode-hook 'ac-js2-mode)
  )

(defun init-scala ()
  (interactive))

(defun init-haskell ()
  (add-hook 'haskell-mode-hook 'intero-mode))

(defun init-ruby ()
  (require 'robe)
  (defadvice inf-ruby-console-auto (before activate-rvm-for-robe activate) (rvm-activate-corresponding-ruby))
  (add-hook 'ruby-mode-hook 'robe-mode)
  (add-hook 'ruby-mode-hook 'minitest-mode)
  (add-hook 'ruby-mode-hook 'flymake-mode)
  ;; (add-hook 'ruby-mode-hook 'flymake-ruby-load)
  (add-hook 'ruby-mode-hook 'ruby-interpolation-mode)
  (add-hook 'ruby-mode-hook 'ruby-end-mode)
  (add-hook 'robe-mode-hook 'ac-robe-setup)
  ;; (add-hook 'company-mode-hook '(lambda () (push 'company-robe company-backends)))
  )

(defun init-dirtree ()
  (require 'dirtree))

(defun init-shortcut ()
  (global-unset-key (kbd "C-x m"))
  ;; (global-set-key (kbd "M-?") 'help-command)
  ;; (global-set-key (kbd "C-?") 'mark-paragraph)
  ;; (global-set-key (kbd "C-h") 'delete-backward-char)
  ;; (global-set-key (kbd "M-h") 'backward-kill-word)
  (global-set-key (kbd "C-a") 'toggle-beginning-line)
  ;;(global-set-key (kbd "TAB") 'tab-indent-or-complete)
  (global-set-key (kbd "RET") 'newline-and-indent)
  (global-set-key (kbd "C-x l") 'list-packages)
  (global-set-key (kbd "C-c TAB") 'indent-region)
  (global-set-key (kbd "C-c v") 'toggle-vim)
  (global-set-key (kbd "C-c c") 'insert-log)
  (global-set-key (kbd "C-c t") 'dirtree)

  (global-set-key (kbd "C-x m l") 'magit-log)
  (global-set-key (kbd "C-x m m") 'magit-status)
  (global-set-key (kbd "C-x m b") 'magit-branch-manager)
  (global-set-key (kbd "C-x m a") 'magit-blame-popup)

  (global-set-key (kbd "C-x <down>") 'tweakemacs-move-one-line-downward)
  (global-set-key (kbd "C-x <up>") 'tweakemacs-move-one-line-upward)
  (global-set-key (kbd "M-=") 'duplicate-current-line-or-region)

  (global-set-key (kbd "C-x [") 'previous-user-buffer)
  (global-set-key (kbd "C-x ]") 'next-user-buffer)
  (global-set-key (kbd "C-x C-l") 'toggle-truncate-lines)
  (global-set-key (kbd "C-x l") 'linum-mode)
  (global-set-key (kbd "C-x C-k") 'kill-this-buffer)
  (global-set-key (kbd "C-x !") 'swap-window-positions)
  (global-set-key (kbd "C-x r a") 'string-insert-rectangle)
  (global-set-key (kbd "C-x @") 'toggle-window-split)
  (global-set-key (kbd "C-o") 'next-multiframe-window)
  ;; (global-set-key (kbd "M-i") 'ibuffer)
  (global-set-key (kbd "M-o") 'previous-multiframe-window)
  (global-set-key (kbd "M-;") 'comment-or-uncomment-region-or-line)

  (global-set-key (kbd "M-m") 'er/expand-region)

  (global-set-key (kbd "C-c w") 'copy-to-x-clipboard)
  (global-set-key (kbd "C-c y") 'paste-from-x-clipboard)
  ;; (global-set-key (kbd "C-c p A") 'ag)

  (global-set-key (kbd "M-x") 'helm-M-x)

  (global-set-key (kbd "C-c x") 'helm-M-x)
  (global-set-key (kbd "C-c p a") 'helm-projectile-ag)
  (global-set-key (kbd "M-h") 'helm-mini)
  ;; (global-set-key (kbd "C-c C-c") 'helm-mini)
  (global-set-key (kbd "C-c h") 'helm-mini)
  (global-set-key (kbd "C-c j") 'ace-jump-mode)
  (global-set-key (kbd "C-c o") 'helm-occur)
  (global-set-key (kbd "C-c i") 'helm-show-kill-ring)
  (global-set-key (kbd "C-c b") 'ibuffer)

  ;; (global-set-key (kbd "C-c i") 'helm-buffers-list)

  (global-set-key (kbd "C-c C-c") 'helm-mini)
  (global-set-key (kbd "C-c g") 'helm-ag)
  (global-set-key (kbd "C-c f") 'helm-flycheck)

  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "M-/") 'helm-company)

  ;; (key-chord-define-global "fm" 'helm-mini)
  )

(defun init-alias ()
  (defalias 'dk 'describe-key)
  (defalias 'df 'describe-function)
  (defalias 'es 'eshell)
  (defalias 'ko 'kill-other-buffers))

(defun init-x-mode()
  "init x setting"
  (progn (scroll-bar-mode 'right)
         (setq font-lock-maximum-decoration t)))

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
  (set-language-environment 'Korean)
  (set-keyboard-coding-system 'utf-8-mac) ;;  For old Carbon emacs on OS X only
  (setq locale-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (unless (eq system-type 'windows-nt)
    (set-selection-coding-system 'utf-8))
  (prefer-coding-system 'utf-8)

  (require 'ac-helm)  ;; Not necessary if using ELPA package
  (global-set-key (kbd "C-:") 'ac-complete-with-helm)
  (define-key ac-complete-mode-map (kbd "C-:") 'ac-complete-with-helm)

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
  (global-linum-mode t)
  (setq standard-indent 2)
  (setq linum-format "%d ")
  (setenv "PATH" (concat (getenv "PATH")))

  (setq default-truncate-lines t) ;; truncate line
  (keyboard-translate ?\C-h ?\C-?) ;; modify default key
  (fset 'yes-or-no-p 'y-or-n-p) ;; yes-no -> y-n
  (setq make-backup-files t) ;; make backup file
  (global-prettify-symbols-mode 1) ;; make lambda -> λ
  (setq inhibit-splash-screen t)) ;; start screen

(defun init-theme ()
  (load-theme 'tango-dark t)
  ;; (load-theme 'wombat t)
  ;; (load-theme 'dracula t)
  )

(defun init-key-chord ()
  (key-chord-mode +1)
  ;; (key-chord-define-global "NN" 'next-user-buffer)
  ;; (key-chord-define-global "PP" 'previous-user-buffer)
  (key-chord-define-global "jj" 'ace-jump-mode))

(defun copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring.
      Ease of use features:
      - Move to start of next line.
      - Appends the copy on sequential calls.
      - Use newline as last char even on the last line of the buffer.
      - If region is active, copy its lines."
  (interactive "p")
  (let ((beg (line-beginning-position))
        (end (line-end-position arg)))
    (when mark-active
      (if (> (point) (mark))
          (setq beg (save-excursion (goto-char (mark)) (line-beginning-position)))
        (setq end (save-excursion (goto-char (mark)) (line-end-position)))))
    (if (eq last-command 'copy-line)
        (kill-append (buffer-substring beg end) (< end beg))
      (kill-ring-save beg end)))
  (kill-append "\n" nil)
  (beginning-of-line (or (and arg (1+ arg)) 2))
  (if (and arg (not (= 1 arg))) (message "%d lines copied" arg)))

(defun init-ido ()
  (require 'flx-ido)
  (require 'ido)
  (ido-mode 1)
  (ido-everywhere 1)
  (ido-vertical-mode)
  (setq ido-enable-flex-matching t) ; fuzzy matching is a must have
  (flx-ido-mode 1)
  (setq ido-use-faces nil))

(defun init-auto-complete ()
  (global-company-mode t) ;; set company-mode
  (global-auto-complete-mode t) ;; set auto-complete mode

  (define-key ac-complete-mode-map "\C-p" 'ac-previous)
  (define-key ac-complete-mode-map "\C-n" 'ac-next)
  ;;(define-key ac-complete-mode-map "\r" nil)
  (ac-set-trigger-key "TAB"))

(defun init-hook ()
  ;; (add-hook 'after-change-major-mode-hook (lambda () (column-enforce-mode)))
  (add-hook 'before-save-hook 'whitespace-cleanup))

;; init default settings
(add-hook 'after-init-hook 'init-default)

(defun init-default ()
  (require 'bracketed-paste)
  (require 'window-number)

  (global-flycheck-mode)

  (init-web-mode)
  (init-undo)
  (init-helm-projectile)
  (init-javascript)
  (init-ruby)

  (init-scala)
  (init-alias)
  (init-emacs-setting)
  (init-theme)
  (init-key-chord)
  (init-shortcut)
  (init-ido)
  (init-dirtree)
  (init-auto-complete)
  (init-hook)
  (init-haskell)

  (setq css-indent-offset 2)

  (bracketed-paste-enable)
  (setenv "TERM" "xterm-256color")

  (window-number-mode 1)
  (wn-mode)
  (global-hl-line-mode t)
  ;; (set-face-background hl-line-face "#121212")

  ;; enable mode
  (yas-minor-mode)
  (global-hi-lock-mode 1)
  (global-set-key (kbd "C-x 1") 'zygospore-toggle-delete-other-windows)

  (column-number-mode t)
  (show-paren-mode t)
  )

(defun v-resize (key)
  "interactively resize the window"
  (interactive "cHit +/- to enlarge/shrink")
  (cond
   ((eq key (string-to-char "+"))
    (enlarge-window 1)
    (call-interactively 'v-resize))
   ((eq key (string-to-char "-"))
    (enlarge-window -1)
    (call-interactively 'v-resize))
   (t (push key unread-command-events))))

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

(defun copy-to-x-clipboard ()
  (interactive)
  (if (region-active-p)
      (progn
        (shell-command-on-region (region-beginning) (region-end)
                                 (cond
                                  ((eq system-type 'cygwin) "putclip")
                                  ((eq system-type 'darwin) "pbcopy")
                                  (t "xsel -ib")
                                  ))
        (message "Yanked region to clipboard!")
        (deactivate-mark))
    (message "No region active; can't yank to clipboard!")))

(defun paste-from-x-clipboard()
  (interactive)
  (shell-command
   (cond
    ((eq system-type 'cygwin) "getclip")
    ((eq system-type 'darwin) "pbpaste")
    (t "xsel -ob")
    ) 1))

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

(defun insert-log ()
  "Insert log for each major-mode"
  (interactive)
  (cond ((equal (message "%s" major-mode) "js2-mode")
         (progn (insert "console.log();") (backward-char 2)))
        ((equal (message "%s" major-mode) "ruby-mode")
         (progn (insert "logger.error \"LOG:: => #{}\"") (backward-char 2)))))

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

(defun toggle-vim ()
  (interactive)

  (if (eq input-method-function 'key-chord-input-method)
      (progn
        (key-chord-mode 0)
        (global-unset-key (kbd "C-u"))
        (global-set-key (kbd "C-u") 'evil-scroll-up)
        (evil-mode 1))
    (progn
      (key-chord-mode 1)
      (global-unset-key (kbd "C-u"))
      (global-set-key (kbd "C-u") 'universal-argument)
      (evil-mode 0)
      )))

(defun toggle-beginning-line ()
  "toggle-beginning-line"
  ;; (string (following-char))
  (interactive)
  (cond ((equal (current-column) 0) (progn (message "beginning-of-line-text")(beginning-of-line-text)))
        ((equal (string (preceding-char)) " ") (progn (message "beginngin-of-line")(beginning-of-line)))
        (t (progn (message ":else")(beginning-of-line-text)))))

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

(defun semnav-up (arg)
 ;;;  by Nikolaj Schumacher, 2008-10-20. Released under GPL.
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

(defun grep-selected (start end)
  (interactive "r")
  (grep (concat "grep -nh -e "
                (buffer-substring start end)
                " * .*")))

(add-hook 'eshell-mode-hook
          'lambda nil
          (let ((bashpath (shell-command-to-string "/bin/bash -l -c 'printenv PATH'")))
            (let ((pathlst (split-string bashpath ":")))
              (setq exec-path pathlst))
            (setq eshell-path-env bashpath)
            (setenv "PATH" bashpath)))

;; (eval-after-load 'magit
;;   '(progn
;;      (set-face-background 'magit-item-highlight "#202020")
;;      (set-face-foreground 'magit-diff-add "#40ff40")
;;      (set-face-foreground 'magit-diff-del "#ff4040")
;;      (set-face-foreground 'magit-diff-file-header "#4040ff")))

;; (deftheme magit-classic
;;   "Old-style faces of Magit")

;; (custom-theme-set-faces
;;  'magit-classic

;;  '(magit-header
;;    ((t)))

;;  '(magit-section-title
;;    ((t
;;      :weight bold
;;      :inherit magit-header)))

;;  '(magit-branch
;;    ((t
;;      :weight bold
;;      :inherit magit-header)))

;;  '(magit-diff-file-header
;;    ((t
;;      :inherit magit-header)))

;;  '(magit-diff-hunk-header
;;    ((t
;;      :slant italic
;;      :inherit magit-header)))

;;  '(magit-diff-add
;;    ((((class color) (background light))
;;      :foreground "blue1")
;;     (((class color) (background dark))
;;      :foreground "white")))

;;  '(magit-diff-none
;;    ((t)))

;;  '(magit-diff-del
;;    ((((class color) (background light))
;;      :foreground "red")
;;     (((class color) (background dark))
;;      :foreground "OrangeRed")))

;;  '(magit-item-highlight
;;    ((((class color) (background light))
;;      :background "gray95")
;;     (((class color) (background dark))
;;      :background "dim gray")))

;;  '(magit-item-mark
;;    ((((class color) (background light))
;;      :foreground "red")
;;     (((class color) (background dark))
;;      :foreground "orange"))))

;; (provide-theme 'magit-classic)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(hl-line ((t (:background "color-52")))))

(defun my-log-view-diff (beg end)
  "Overwrite the default log-view-diff, make use of
    log-view-get-marked --lgfang"

  (interactive
   (if (log-view-get-marked) (log-view-get-marked)
     (list (log-view-current-tag (point))
           (log-view-current-tag (point)))))
  (when (string-equal beg end)
    (save-excursion
      (goto-char (point))               ;not marked
      (log-view-msg-next)
      (setq end (log-view-current-tag))))
  (vc-version-diff
   (if log-view-per-file-logs
       (list (log-view-current-file))
     log-view-vc-fileset)
   beg end))

(eval-after-load "log-view" '(fset 'log-view-diff 'my-log-view-diff))

(defun my-log-view-revision ()
  "get marked revision (or revision at point) --lgfang"
  (interactive)
  (let ((revision (if (log-view-get-marked) (car (log-view-get-marked))
                    (log-view-current-tag (point)))))
    (switch-to-buffer-other-window
     (vc-find-revision (log-view-current-file) revision))))
(eval-after-load "log-view"
  '(define-key log-view-mode-map "v" 'my-log-view-revision))

(add-hook 'diff-mode-hook '(lambda () (require 'ansi-color)(ansi-color-apply-on-region (point-min) (point-max))))

(add-to-list 'auto-mode-alist '("\\emacs$" . emacs-lisp-mode))

(define-generic-mode 'ebnf-mode
  '(("(*" . "*)"))
  '("=")
  '(("^[^ \t\n][^=]+" . font-lock-variable-name-face)
    ("['\"].*?['\"]" . font-lock-string-face)
    ("\\?.*\\?" . font-lock-negation-char-face)
    ("\\[\\|\\]\\|{\\|}\\|(\\|)\\||\\|,\\|;" . font-lock-type-face)
    ("[^ \t\n]" . font-lock-function-name-face))
  '("\\.ebnf\\'")
  `(,(lambda () (setq mode-name "EBNF")))
  "Major mode for EBNF metasyntax text highlighting.")

(provide 'ebnf-mode)

(add-to-list 'auto-mode-alist '("\\.ebnf$" . ebnf-mode))

;; custom settings
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (swiper-helm wgrep-ag wgrep-helm flymake-haskell-multi ghc fzf groovy-mode graphql-mode dash-functional helm-dash xref-js2 sass-mode rvm markdown-mode column-enforce-mode alchemist erlang less-css-mode rainbow-delimiters smex jade-mode zygospore slim-mode haml-mode dirtree ido-ubiquitous ido-vertical-mode flx-ido ag io-mode ac-helm ac-js2 ac-dabbrev js2-mode ensime scala-mode2 ruby-hash-syntax ruby-end ruby-interpolation robe wn-mode window-number web-mode evil ace-jump-buffer ace-jump-mode ac-etags key-chord nginx-mode magit helm-ag helm-projectile helm projectile undo-tree info+ yaml-mode minitest bracketed-paste expand-region)))
 '(python-indent-offset 2))
(put 'dired-find-alternate-file 'disabled nil)
