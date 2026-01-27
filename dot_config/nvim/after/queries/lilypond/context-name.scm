(named_context
  (symbol) @result
  .
  (
    (punctuation) @punctuation
    (#match? @punctuation "^=$")
  )
)

(named_context
  (
    (punctuation) @punctuation
    (#match? @punctuation "^=$")
  )
  .
  [(string) (symbol)] @result
  .
  (#prefix! @result " ")
)
