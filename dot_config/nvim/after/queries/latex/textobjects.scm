;;extends
;; -*- scheme -*-
;; queries/latex/textobjects.scm

;; --- 外层数学对象 (包括所有环境和定界符)
((displayed_equation) @tex.math.outer)
((inline_formula)   @tex.math.outer)
((math_environment) @tex.math.outer)

;; --- 内层数学对象 (不含定界符，仅内容)
((displayed_equation) @tex.math.inner
  (#offset! @tex.math.inner 0 2 0 -2))
((inline_formula)    @tex.math.inner
  (#offset! @tex.math.inner 0 2 0 -2))
((math_environment)  @tex.math.inner
(#offset! @tex.math.inner 1 0 -1 999999))

;; 捕获所有 LaTeX 环境的外层（包括 \begin{…} 和 \end{…}）
; ((environment) @latex.env.outer)
;
; ;; 捕获所有 LaTeX 环境的内层（仅环境内部内容，不含边界）
; ((environment) @latex.env.inner)
