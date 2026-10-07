if exists("b:current_syntax")
  finish
endif

syntax case match

" A task is: start[+duration|-deadline] command.  nextgroup keeps date-like
" strings inside the shell command from being mistaken for schedule fields.
syntax match laterStart /^\s*\zs\%(+\%(\d\+[smhd]\)\+\|\d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}-\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}:\d\{2}\%(:\d\{2}\)\?\)/ contains=laterDate,laterTime,laterTimeSeparator nextgroup=laterExpiryPlus,laterRangeDash,laterCommand skipwhite
syntax match laterExpiryPlus /+/ contained nextgroup=laterDuration
syntax match laterDuration /\%(\d\+[smhd]\)\+/ contained nextgroup=laterCommand skipwhite
syntax match laterRangeDash /-/ contained nextgroup=laterDeadline
syntax match laterDeadline /\%(\d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}-\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}-\d\{2}T\d\{2}:\d\{2}\%(:\d\{2}\)\?\|\d\{2}:\d\{2}\%(:\d\{2}\)\?\)/ contained contains=laterDate,laterTime,laterTimeSeparator nextgroup=laterCommand skipwhite
syntax match laterDate /\%(\d\{4}-\d\{2}-\d\{2}\|\d\{2}-\d\{2}-\d\{2}\|\d\{2}-\d\{2}\)\zeT/ contained
syntax match laterTime /\d\{2}:\d\{2}\%(:\d\{2}\)\?/ contained
syntax match laterTimeSeparator /T/ contained
syntax match laterCommand /\%(\s\)\@<=\S.*$/ contained contains=laterShellOperator,laterString
syntax match laterShellOperator /\(&&\|||\|[|;<>]\)/ contained
syntax region laterString start=/'/ end=/'/ contained
syntax region laterString start=/"/ skip=/\\"/ end=/"/ contained

syntax match laterComment /^\s*#.*$/ contains=laterRunning,laterFailed,laterExpired,laterTodo
syntax match laterRunning /\[running\]/ contained
syntax match laterFailed /\[failed:\d\+\]/ contained
syntax match laterExpired /\[expired\]/ contained
syntax keyword laterTodo TODO FIXME NOTE contained

highlight default link laterStart Type
highlight default link laterExpiryPlus Operator
highlight default link laterDuration Number
highlight default link laterRangeDash Delimiter
highlight default link laterDeadline Constant
highlight default link laterDate Type
highlight default link laterTime Constant
highlight default link laterTimeSeparator Comment
highlight default link laterCommand Identifier
highlight default link laterShellOperator Operator
highlight default link laterString String
highlight default link laterComment Comment
highlight default link laterRunning DiagnosticWarn
highlight default link laterFailed DiagnosticError
highlight default link laterExpired DiagnosticDeprecated
highlight default link laterTodo Todo

let b:current_syntax = "later"
