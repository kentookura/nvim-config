; ============================================================
; queries/injections.scm
;
; 1. Inject bash into command lines and continuations
; 2. Inject the appropriate language into heredoc body lines,
;    determined by the heredoc_start delimiter name.
; ============================================================

; ---- Commands → bash injection --------------------------------------------

(command_simple
  (command_text_plain) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-children true))

(command_heredoc
  (command_text_heredoc) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-children true))

(command_continuation
  (continuation_text) @injection.content
  (#set! injection.language "bash"))

; lua
(test_block_heredoc
  (command_heredoc
    (command_text_heredoc
      (heredoc_redirect
        (heredoc_start) @_delim)))
  (heredoc
    (heredoc_line
      (heredoc_line_content) @injection.content))
  (#match? @_delim "^LUA$")
  (#set! injection.language "lua"))
; 
; ; Generic fallback: lowercase the delimiter and use as language name,
; ; excluding common non-language sentinel names.
; (test_block_heredoc
;   (command_heredoc
;     (command_text_heredoc
;       (heredoc_redirect
;         (heredoc_start) @injection.language)))
;   (heredoc
;     (heredoc_line
;       (heredoc_line_content) @injection.content))
;   (#lua-match? @injection.language "^[A-Z][A-Z0-9_]+$")
;   (#not-match? @injection.language "^(EOF|END|HEREDOC|INPUT|TEXT|DATA|CONTENT|STDIN)$")
;   (#gsub! @injection.language "^(.+)$" (string.lower)))
