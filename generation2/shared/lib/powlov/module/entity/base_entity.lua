-- global BaseEntity

local _={}

-- todo: check is name used
_.new=function(entityName,isService)
	assert(entityName)
	local result={}
	
	if not isService then
		result.id=Id.new(entityName)
	end
	
	result.isService=isService
	result.entityName=entityName
	result.drawLayer=0
	
	
	return result
end

-- light reference
-- reverse: Db.getByRef
_.getReference=function(entity)
	local result={}
	
	result.id=entity.id
	-- result.login=entity.login no local ent/thin client
	result.entityName=entity.entityName
	
	return result
end

_.referenceEquals=function(ref1,ref2)
	if ref1.id~=ref2.id then return false end
	
	if ref1.entityName~=ref2.entityName then return false end
	
	return true
end




_.draw=function(entity)
	local spriteName=entity.sprite
	if (spriteName==nil) then
		return
	end
	-- todo: cache it, do not query every frame
	local sprite=Img.get(spriteName)
	log('drawing:'..Entity.toString(entity))
	love.graphics.draw(sprite,entity.x,entity.y)
end

return _