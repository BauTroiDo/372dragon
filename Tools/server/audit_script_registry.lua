-- Evaluate only the registry's data table in an empty environment. Never
-- require/construct/call a gameplay module. Independent check of regex census.
local root, out = assert(arg[1]), assert(arg[2])
local table_path = root..'/Game_2/Script/scripts/scripts.lua'
local registry = assert(loadfile(table_path, 't', {}))()
assert(type(registry)=='table')
local rows={}
for id,path in pairs(registry) do
    assert(type(id)=='number' and type(path)=='string')
    rows[#rows+1]={id,path}
end
table.sort(rows,function(a,b)return a[1]<b[1]end)
local report=assert(io.open(out,'w'));local missing=0
for _,row in ipairs(rows) do
    local path=root..'/Game_2/Script/'..row[2]:gsub('%.','/')..'.lua'
    local file=io.open(path,'r');if file then file:close() else missing=missing+1 end
    report:write(row[1],'\t',row[2],'\t',file and 'present' or 'missing','\n')
end
report:close()
print(string.format('actual_registry_ids=%d missing_modules=%d',#rows,missing))
