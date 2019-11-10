;;; -*- lexical-binding: t; -*-
(advice-add 'nix-straight-get-used-packages
            :before (lambda (&rest r)
                      (message "Advising doom installer to gather packages to install...")
                      (advice-add 'doom-reload-autoloads
                                  :override (lambda (&optional file force-p)
                                              (message "Skipping generating autoloads...")))
                      (advice-add 'doom--format-print
                                  :around (lambda (orig-print &rest r)
                                            (let ((noninteractive nil))
                                              (apply orig-print r))))))
