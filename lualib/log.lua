local skynet = require "skynet"
local os = os
local string = string
local math = math

local log = {}

local cache_ti
local cache_str
local function fmttime()
	local ti = math.floor(skynet.time())
	if ti ~= cache_ti then
		cache_ti = ti
		cache_str = os.date("%F %T",ti)
	end
	return cache_str
end

function log.printf(...)
	skynet.error(string.format("[%s] %s",fmttime(),string.format(...)))
end

return log
