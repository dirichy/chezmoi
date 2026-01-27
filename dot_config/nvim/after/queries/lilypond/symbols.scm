(lilypond_program
  (assignment_lhs
    (symbol) @name
    (#set! role variable)
  ) @subtree
)

((named_context
  (symbol)
  .
  (
    (punctuation) @operator
    (#match? @operator "^=$")
  )
  .
  [(symbol) (string)] @name)
  (#set! role struct)
  (#set! displayname.query "lilypond/context-name.scm")
) @subtree @displayname.target
