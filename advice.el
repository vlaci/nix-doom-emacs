;;; -*- lexical-binding: t; -*-
(advice-add 'nix-straight-get-used-packages
            :before (lambda (&rest r)
                      (message "[nix-doom-emacs] Advising doom installer to gather packages to install...")
                      (advice-add 'doom-cli-reload-autoloads
                                  :override (lambda (&optional file force-p)
                                              (message "[nix-doom-emacs] Skipping generating autoloads...")))
                      (advice-add 'doom--format-print
                                  :around (lambda (orig-print &rest r)
                                            (let ((noninteractive nil))
                                              (apply orig-print r))))))

(advice-add 'y-or-n-p
            :override (lambda (q)
                        (message "%s \n[nix-doom-emacs] --> answering NO" q)
                        nil))
