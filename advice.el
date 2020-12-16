;;; -*- lexical-binding: t; -*-

;;; Skip Emacs's own package verification and let Nix do it for us.
;;;
;;; Having gnupg around the build triggers Emacs to use it for package signature
;;; verification. This would not work anyway because the build sandbox does not
;;; have a properly configured user home and environment.
(setq package-check-signature nil)

;;; For gccEmacs compatibility
(with-eval-after-load "comp"
  ;; The advice for 'kill-emacs would result in eln files being written before
  ;; doom would set up proper load paths
  (add-to-list 'comp-never-optimize-functions 'kill-emacs))

(defun nix-straight-inhibit-kill-emacs (arg)
  (message "[nix-doom-emacs] Inhibiting (kill-emacs)"))

(advice-add 'nix-straight-get-used-packages
            :around (lambda (orig-fn &rest r)
                      (message "[nix-doom-emacs] Advising doom installer to gather packages to install...")
                      (advice-add 'doom-autoloads-reload
                                  :override (lambda (&optional file force-p)
                                              (message "[nix-doom-emacs] Skipping generating autoloads...")))
                      (advice-add 'doom--print
                                  :override (lambda (output)
                                              (message output)))
                      (advice-add 'kill-emacs
                                  :override #'nix-straight-inhibit-kill-emacs)
                      (apply orig-fn r)
                      (advice-remove 'kill-emacs 'nix-straight-inhibit-kill-emacs)))

(advice-add 'y-or-n-p
            :override (lambda (q)
                        (message "%s \n[nix-doom-emacs] --> answering NO" q)
                        nil))

;;; org is not installed from git, so no fixup is needed
(advice-add '+org-fix-package-h
            :override (lambda (&rest r)))

;; just use straight provided by nix
(advice-add 'doom-initialize-core-packages
            :override (lambda (&rest r)
                        (require 'straight)
                        (straight--make-build-cache-available)))
