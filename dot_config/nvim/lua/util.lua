local M = {}

---@param opt string #the option to set, must be a key of vim.opt
---@param on any #the value of vim.opt[opt] when option is on
---@param off any #the value of vim.opt[opt] when option is off
---@param name? string #the alias name of this option, will use in notify.
---when not provided, will be same as opt.
---@return function #will return a funtcion to toggle this option
function M.opt_toggle_fun(opt, on, off, name)
	local result = function()
		local message = name or opt
		if vim.opt[opt]:get() == off then
			vim.opt[opt] = on
			message = message .. " Enabled"
		else
			vim.opt[opt] = off
			message = message .. " Disabled"
		end
		vim.notify(message, vim.log.levels.INFO)
	end
	return result
end

--- toggle a variable, for example, vim.g.xxx or vim.b.xxx
---@param variable_name string #the variable name, will toggle vim.g[variable_name]
---@param on any #a value of vim.g[variable_name]
---@param off any #another value of vim.g[variable_name]
---@param name string #alias for notify
---@param buffer boolean #whether use vim.b instead of vim.g
---@return function
function M.variable_toggle_fun(variable_name, on, off, name, buffer)
	local result = function()
		local g_or_b = buffer and "b" or "g"
		local message = name or variable_name
		if vim[g_or_b][variable_name] == off then
			vim[g_or_b][variable_name] = on
			message = message .. " Enabled"
		else
			vim[g_or_b][variable_name] = off
			message = message .. " Disabled"
		end
		vim.notify(message, vim.log.levels.INFO)
	end
	return result
end
return M
