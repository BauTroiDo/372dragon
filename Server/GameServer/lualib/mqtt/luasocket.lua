-- DOC: http://w3.impa.br/~diego/software/luasocket/tcp.html

-- module table
local luasocket = {}
local socket = require "skynet.socket"

-- Open network connection to .host and .port in conn table
-- Store opened socket to conn table
-- Returns true on success, or false and error text on failure
function luasocket.connect(conn)
	local sock, err = socket.open(conn.host, conn.port)
	if not sock then
		return false, "socket.connect failed: "..err
	end
	conn.sock = sock
	return true
end

-- Shutdown network connection
function luasocket.shutdown(conn)
	socket.close(conn.sock)
end

-- Send data to network connection
function luasocket.send(conn, data)
	local ok, err = socket.write(conn.sock, data)
	-- print("    luasocket.send:", ok, err, require("mqtt.tools").hex(data))
	return ok, err
end

-- Receive given amount of data from network connection
function luasocket.receive(conn, size)
	return socket.read(conn.sock, size)
end

-- Set connection's socket to non-blocking mode and set a timeout for it
function luasocket.settimeout(conn, timeout)
end

-- export module table
return luasocket

-- vim: ts=4 sts=4 sw=4 noet ft=lua
