;;; -*- lexical-binding: t; -*-
(advice-add 'nix-straight-get-used-packages
            :before (lambda (&rest r)
                      (message "[nix-doom-emacs] Advising doom installer to gather packages to install...")
                      (advice-add 'doom-autoloads-reload
                                  :override (lambda (&optional file force-p)
                                              (message "[nix-doom-emacs] Skipping generating autoloads...")))
                      (advice-add 'doom--print
                                  :override (lambda (output)
                                            (message output)))))

(advice-add 'y-or-n-p
            :override (lambda (q)
                        (message "%s \n[nix-doom-emacs] --> answering NO" q)
                        nil))

;;; org is not installed from git, so no fixup is needed
(advice-add '+org-fix-package-h
            :override (lambda (&rest r)))

;; just use straight provided by nix
(advice-add 'doom-initialize-core-packages
            :override (lambda (&rest r) (require 'straight)))
