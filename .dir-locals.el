

((nil . ((dir-local-sentinal . "Test")))
 (verilog-ts-mode . ((verilog-ext-sentinal . "Other sentinal")
                      (eval . (setq verilog-ext-project-alist
                                    `(("DirectConverter"
                                       :root ,(projectile-project-root)
                                       :files ,(f-files (projectile-project-root) (lambda (file)
                                                                (s-matches? (rx "." (opt "s") "v" (opt "h") eol) file)) t)
                                       )))))))
