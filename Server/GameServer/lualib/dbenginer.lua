local mongo = require "skynet.db.mongo"
local server_conf = require "server_conf"
local class = require "class"
local dbenginer = class("dbenginer")

function dbenginer:getinstance()
    if dbenginer.instance == nil then dbenginer.instance = dbenginer:new() end
    return dbenginer.instance
end

function dbenginer:ctor()
	self.id = nil
end

function dbenginer:init(db, db_name, id)
	self:connect(server_conf[db])
	self.db_name = db_name
	self.id = id
end

function dbenginer:connect(args)
	self.client = mongo.client(
		{
			host = args.host,
            port = tonumber(args.port)
		}
	)
    self.client[args.db_name]:auth(args.username, args.password)
    return self.client ~= nil
end

function dbenginer:disconnect()
    self.client:disconnect()
end

function dbenginer:insert(args)
    local db = self.client:getDB(self.db_name)
    local c = db:getCollection(args.collection)
    c:insert(args.doc)
end

function dbenginer:safe_insert(args)
    local db = self.client:getDB(self.db_name)
    local c = db:getCollection(args.collection)
    return c:safe_insert(args.doc)
end

function dbenginer:safe_update(args)
    local db = self.client:getDB(self.db_name)
    local c = db:getCollection(args.collection)
    return c:safe_update(args.selector, args.update, args.upsert, args.multi)
end

function dbenginer:insertBatch(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	c:batch_insert(args.docs)
end

function dbenginer:delete(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	c:delete(args.selector, args.single)
end

function dbenginer:drop(args)
	local db = self.client:getDB(self.db_name)
	local r = db:runCommand("drop", args.collection)
	return r
end

function dbenginer:findOne(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
    local result = c:findOne(args.query, args.selector)
	return result
end

function dbenginer:findAll(args)
	print("findAll args =", table.tostr(args))
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	local result = {}
	local cursor = c:find(args.query, args.selector)
	if args.sorter ~= nil then
        if #args.sorter  > 0 then
            cursor = cursor:sort(table.unpack(args.sorter ))
        else
            cursor = cursor:sort(args.sorter )
        end
    end
	if args.skip ~= nil then
		cursor:skip(args.skip)
	end
	if args.limit ~= nil then
		cursor:limit(args.limit)
	end
	while cursor:hasNext() do
		local document = cursor:next()
		table.insert(result, document)
	end
    cursor:close()

    if #result > 0 then
        return result
    end
end

function dbenginer:update(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	return c:update(args.selector, args.update, args.upsert, args.multi)
end

function dbenginer:findAndModify(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	args.collection = nil
	return c:findAndModify(args)
end

function dbenginer:createIndex(args)
	local db = self.client:getDB(self.db_name)
	local c = db:getCollection(args.collection)
	local result = c:createIndex(args.keys, args.option)
	return result
end

function dbenginer:runCommand(...)
	local db = self.client:getDB(self.db_name)
	local result = db:runCommand(...)
	return result
end

return dbenginer
