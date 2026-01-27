((expression_block
    ("{") @start
    ("}") @end)
  (#set! role block))

((
    ("<<") @start
    (">>") @end)
  (#set! role block))

((
    ("#{") @start
    ("#}") @end)
  (#set! role block))

((
    ("<") @start
    (">") @end)
  (#set! role block))
