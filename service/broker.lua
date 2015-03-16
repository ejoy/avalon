local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"

local roomkeeper
local lobby
local address_table = {}
local action_method = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		if err ~= sockethelper.socket_error then
			log.printf("%s error : %s", address_table[id], err)
		end
	end
end

action_method["/"] = function(header)
	return skynet.call(lobby, "lua", header)
end

local function dispatch_room(room, header)
	local r = skynet.call(roomkeeper, "lua", "query", room)
	if not r then
		return 404, "Invalid or closed room."
	end
	return 200, skynet.call(r, "lua", "web", header)
end

local function handle_socket(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			local action = urllib.parse(url)
			local f = action_method[action]
			if not f then
				local room = tonumber(action:sub(2))
				if room then
					response(id, dispatch_room(room, header))
				else
					response(id, 404, "404 Not found")
				end
			else
				response(id, 200, f(header))
			end
		end
	else
		if url ~= sockethelper.socket_error then
			log.printf("%s error: %s", address_table[id], url)
		end
	end
end

skynet.start(function()
	roomkeeper = assert(skynet.uniqueservice "roomkeeper")
	lobby = assert(skynet.uniqueservice "lobby")
	skynet.dispatch("lua", function(_,_,id, ipaddr)
		address_table[id] = ipaddr
		socket.start(id)
		pcall(handle_socket, id)
		socket.close(id)
	end)
end)
