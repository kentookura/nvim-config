; ============================================================
; queries/highlights.scm
; ============================================================

; ---- Prose / description ---------------------------------------------------
(description_line) @comment

; ---- Command prompt --------------------------------------------------------
; (command_simple "$ " @keyword.operator)
; (command_heredoc "$ " @keyword.operator)
; 
(command_text_plain) @string.special
(command_text_heredoc) @string.special
 
; ; ---- Continuations ---------------------------------------------------------
; (command_continuation "> " @keyword.operator)
(continuation_text) @string
; 
; ; ---- Heredoc ---------------------------------------------------------------
; (heredoc_redirect "<<" @keyword.operator)
(heredoc_start) @tag
; 
; (heredoc_line "> " @keyword.operator)
; (heredoc_line_content) @string   ; fallback if injection disabled
; 
; (heredoc_end "> " @keyword.operator)
(heredoc_terminator) @tag
; 
; ; ---- Expected output -------------------------------------------------------
(output_text) @string
(output_modifier) @attribute
; 
; ; ---- Exit status -----------------------------------------------------------
(exit_status "[" @punctuation.bracket)
(exit_status "]" @punctuation.bracket)
(exit_code) @number
