local skynet = require "skynet"
local io = io
local root = skynet.getenv "static_path" or "./static/"

local function cachefile(cache, filename)
	local f = io.open (root .. filename)
	if f then
		local content = f:read "a"
		f:close()
		cache[filename] = content
		return content
	else
		cache[filename] = false
	end
end

local staticfile = setmetatable({}, { __mode = "kv", __index = cachefile })

return staticfile
