local skynet = require "skynet"
local socket = require "socket"

skynet.start(function()
	assert(skynet.uniqueservice "roomkeeper")
	local broker_n = tonumber(skynet.getenv "broker")
	local broker = {}
	for i= 1, broker_n do
		broker[i] = assert(skynet.newservice("broker"))
	end

	local roomkeeper = skynet.uniqueservice "roomkeeper"

	local address = skynet.getenv "listen"
	skynet.error("Listening "..address)
	local id = assert(socket.listen(address))
	local balance = 1
	socket.start(id , function(id, addr)
		skynet.send(broker[balance], "lua", id, addr)
		balance = balance + 1
		if balance > #broker then
			balance = 1
		end
	end)
end)
