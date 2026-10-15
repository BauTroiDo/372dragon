-- Pure plans recovered from the original CY recipe Lua. No inventory mutations.
local D={}
for _,id in ipairs({700900,700901,700959,700960})do D[id]=require('cys_recipe_data_'..id)end
local M={}
function M.handles(row)return D[row['脚本ID']]~=nil end
local function available(h,id)
    local family=id//10000000
    local kind=(family==2 or family==5 or family==6)and 'material' or family==4 and 'task' or 'prop'
    local total=0
    for _,item in h:get_prop_bag_container():ipairs(kind)do
        if item and not item:is_lock() and item:get_index()==id then total=total+item:get_lay_count()end
    end
    return total
end
local function group(h,list,count)
    local need={}
    for _,id in ipairs(list or {})do
        local take=math.min(count,available(h,id)-(need[id]or 0))
        if take>0 then need[id]=(need[id]or 0)+take;count=count-take end
        if count==0 then return need end
    end
end
local function choose(list,random,field)
    local roll=random(10000)
    for _,r in ipairs(list)do if roll<=r[field]then return r end end
end
function M.resolve(h,row,roll)
    local data=D[row['脚本ID']];if not data then return row end
    local info=data.CompoundInfo[row.index]
    if not info or info.abilityId~=row['对应技能ID']then return nil end
    local ability=h:get_ability(info.abilityId)
    if not ability or ability.level<info.recipeLevel then return nil end
    local out={};for k,v in pairs(row)do out[k]=v end
    local outputs,need={},nil
    if row['脚本ID']==700900 then
        local level=math.min(ability.level,info.aLevelLimit)
        local matLevel
        for n=0,info.matClassCount-1 do
            local count=math.max(1,info.matCostBase+(level-info.recipeLevel-n)*info.matFactor)
            need=group(h,data.CaiLiaoBiao[info.matClassBase+n],count)
            if need then matLevel=info.recipeLevel+n;break end
        end
        if not need then return nil end
        local aid=info.abilityId==1 and 28 or 27
        local assist=h:get_ability(aid);assist=assist and assist.level or 0
        local denominator=0.2*assist-33
        if denominator==0 then return nil end
        out['活力需求']=math.max(1,math.floor(data.VigorCostList[level]*(1.59090909090909+19.3818181818182/denominator)))
        out['精力需求']=info.energyCost
        out._cys_gain_level=matLevel;out._cys_no_gain=ability.level>info.aLevelLimit
        out._cys_assist_id,out._cys_assist=aid,assist
        if roll then
            if math.random(100)<=5+matLevel/4+assist/2 then
                local picked=choose(data.ChanPinBiao[info.succProductClass],math.random,'Odds')
                if not picked then return nil end
                outputs[#outputs+1]={id=picked.ID,count=1}
            end
            local picked=choose(info.failProductClass[level],math.random,'odds')
            local groupId=picked and picked.prodClass or info.failProductClass.defaultClass
            picked=choose(data.ChanPinBiao[groupId],math.random,'Odds')
            if not picked then return nil end
            outputs[#outputs+1]={id=picked.ID,count=1}
        else outputs[1]={id=data.ChanPinBiao[info.failProductClass.defaultClass][1].ID,count=1}end
    elseif row['脚本ID']==700960 then
        local mat=info.matTbl[1];need={}
        for n,id in ipairs(mat.matList)do need[id]=(need[id]or 0)+mat.count[n]end
        out['活力需求']=info.deleteVigor
        outputs[1]={id=mat.Product,count=1,way=1};out._cys_no_gain=true
    else
        for _,mat in ipairs(info.matTbl)do
            need=group(h,mat.matList,mat.count)
            if need then outputs[1]={id=mat.Product or info.Product,count=1};break end
        end
        if not need then return nil end
        out._cys_no_gain=true
    end
    out._cys_needs,out._cys_outputs=need,outputs
    out.ResultID,out.ResultNum=outputs[1].id,outputs[1].count
    return out
end
return M
