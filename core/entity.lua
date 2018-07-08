local _={}

-- all registered, except services
local _all={}



-- k=1..max, v={entity,draw}
local _drawable={}
-- k=entity, v=draw function
local _uidrawable={}
local _scaleduidrawable={}

-- k=entity, v=upd function
local _updateable={}
local _slowUpdateable={}
local _ai={}
local _keyListeners={}

-- debug
_._all=_all
_._drawable=_drawable

-- read only please
_.getAll=function()
	return _all
end

_.getWorld=function(login)
	local result={}
	for k,entity in pairs(_all) do
		if entity.isInWorld then
			if entity.entity=="Player" and entity.login==login then
				-- client responsible for its player, we dont send it
			else
				table.insert(result,entity)
			end
			
		end
	end
	
	return result
end

_.getLocal=function()
	local result={}
	for k,entity in pairs(_all) do
		if not entity.isRemote then
			table.insert(result,entity)
		end
	end
	
	return result
end

_.getSaving=function()
	return _.getLocal()
end



_.get=function(name)
	return _G[name]
end

local _get=_.get

_.registerWorld=function()
	-- reload not supported yet
	
	--we have editor items
	--assert(Lume.count(_all)==0)
	
	local world=World
	
	
	local register=_.register
	
	-- already in World.entities
	-- register(world.player)
	for k,entity in pairs(World.entities) do
		register(entity)
	end
end

local addToCollision=function(entity)
--	log("addToCollision:"..Entity.toString(entity))
	if entity.w>0 and entity.h>0 and entity.isInWorld then
		Collision.add(entity)
	else
--		log("not square entity:"..entity.entity)
	end
end

local removeFromCollision=function(entity)
	Collision.remove(entity)
end


local activate=function(entity)
--	log("activating:"..Entity.toString(entity))
	
	if entity.entity=="Cauldron" then
		local a=1
	end
	
	
	local entityCode=_get(entity.entity)
	
	if entityCode.activate then
		entityCode.activate(entity)
	end
	
	
	if entity.isDrawable then
		
		
		table.insert(_drawable,{entity=entity,draw=entityCode.draw})
		-- _drawable[entity]=entityCode.draw
	end
	
	if entity.isUiDrawable then
		_uidrawable[entity]=entityCode.drawUi
	end	
	
	if entity.isScaledUiDrawable then
		_scaleduidrawable[entity]=entityCode.drawScaledUi
	end
	
	if not entity.isRemote then
		local fnUpdate=entityCode.update
		if fnUpdate~=nil then
			_updateable[entity]=fnUpdate
		end
		
		local fnSlowUpdate=entityCode.slowUpdate
		if fnSlowUpdate~=nil then
			_slowUpdateable[entity]=fnSlowUpdate
		end
	end
	
	
	if entity.aiEnabled then
		_ai[entity]=entityCode.updateAi
	end
	
	if entityCode.keypressed~=nil then
		_keyListeners[entity]=entityCode.keypressed
	end
	
	
	entity.isActive=true
	addToCollision(entity)
end

local removeDrawable=function(entity,container)
	log("drawables before remove:"..#container)
	for k,info in ipairs(container) do
		if info.entity==entity then 
			table.remove(container,k)
			-- container[k]=nil wrong way (sort crash on nil)
			return
		end
	end
	
	log("drawables after remove:"..#container)
	
	log("error: removeDrawable")
end


local deactivate=function(entity)
	log("deactivating:"..Entity.toString(entity))
	local entityCode=_get(entity.entity)
	
	if entityCode.deactivate then
		entityCode.deactivate(entity)
	end
	
	-- problem: entity.isDrawable was changed
	-- make setDrawable func? ok
	
	if entity.isDrawable then
		--_drawable[entity]=nil
		removeDrawable(entity,_drawable)
		-- table_removeByVal(_drawable,entityCode.draw)
	end
	
	if entity.isUiDrawable then
		table_removeByVal(_uidrawable,entityCode.drawUi)
	end
	
	if entity.isScaledUiDrawable then
		local isRemoved=table_removeByVal(_scaleduidrawable,entityCode.drawScaledUi)
	end
	
	local fnUpdate=entityCode.update
	if fnUpdate~=nil then
		local isRemoved=table_removeByVal(_updateable,fnUpdate)
		assert(isRemoved)
	end
	
	local fnSlowUpdate=entityCode.slowUpdate
	if fnSlowUpdate~=nil then
		local isRemoved=table_removeByVal(_slowUpdateable,fnSlowUpdate)
		assert(isRemoved)
	end
	

	if entity.aiEnabled then
		local isRemoved=table_removeByVal(_ai,entityCode.updateAi)
		if not isRemoved then
			local a=1
		end
		
		
		assert(isRemoved)
	end
	
	if entityCode.keypressed~=nil then
		_keyListeners[entity]=nil
	end
	
	entity.isActive=false
end




_.isRegistered=function(entity)
	local key=Lume.find(_all,entity)
	local result=key~=nil
	return result
end

_.register=function(entity)
--	log("registering:"..pack(entity))
	-- service entity created at runtime, and do not need to be serialized
	local isService=entity.id==nil
	local isActive=not (entity.isActive==false) -- true or nil
	
	if not isService then
		if Config.isDebug then
			local alreadyRegistered,regged=Lume.find(_all,entity)
			if alreadyRegistered then
				log("error: attempt to register entity twice:"..Entity.toString(entity))
			end
			
			
		end
		
		
		table.insert(_all,entity)
	end
	
	
	if isActive then
		activate(entity)
	else
		
	end
end


-- nil entityLogin means local entity
_.delete=function(entityName,entityId,entityLogin)
	log("deleting entity:"..entityId.." n:"..entityName.." l:"..tostring(entityLogin))
	local entity=_.find(entityName,entityId,entityLogin)
	assert(entity)
	
	if entity.isActive then deactivate(entity) end
	
	
	local isRemoved=table_removeByVal(_all,entity)
	assert(isRemoved)
	
-- local only, remote should react to event	
--	local event=Event.new()
--	event.code="entity_remove"
--	event.entityName=entityName
--	event.entityId=entityId
--	event.entityLogin=entityLogin

	if entity.isInWorld then 
		Entity.removeFromWorld(entity)
	end
	

	return entity
end

_.unregister=_.delete

-- nil login means local entity (same login as current)
_.find=function(entityName,id,login)
	if login==nil then login=Session.login end
	
	for k,entity in pairs(_all) do
		if entity.entity==entityName and entity.id==id and entity.login==login then
			return entity
		end
	end
	
	return nil
end




local compareByY=function(info1,info2)
	if info2==nil then
		a=1
	end
	
	
	local entity1=info1.entity
	local entity2=info2.entity
	if entity1.y>entity2.y then return false end
	if entity1.y<entity2.y then return true end
	return false
end

local updateYSort=function()
--	local testSort={} 
--	local e1={y=10}
--	local e2={y=2}
--	local e3={y=40}
	
	
--	testSort[e1]="e1"
--	testSort[e2]="e2"
--	testSort[e3]="e3"
	
--	local sorter=function(a, b)
--		return a.y > b.y 
--	end
--	local beforeSort=Inspect(testSort)
--	table.sort(testSort,sorter)
--	local afterSort=Inspect(testSort)
	
	
--	local beforeSort2=Inspect(_drawable)
	table.sort(_drawable,compareByY)
--	local afterSort2=Inspect(_drawable)
	
--	local a
end




_.draw=function()
	
	updateYSort()
	
-- bottom origin - later	
--		LG.draw(entity.sprite,entity.x,entity.y-entity.height)
	
	for k,info in ipairs(_drawable) do
		local entity=info.entity
--		log("draw:"..entity.entity.." at:"..xy(entity.x,entity.y))
		info.draw(entity)
	end
	
	local activeEntity=Session.selectedEntity
	if activeEntity~=nil then
		LG.rectangle('line',activeEntity.x-1,activeEntity.y-1,activeEntity.w+2,activeEntity.h+2)
	end
	
		
end

_.drawUi=function()
	for entity,code in pairs(_uidrawable) do
		code(entity)
	end
end

_.drawScaledUi=function()
	local test=Util.dump(_scaleduidrawable)
	for entity,code in pairs(_scaleduidrawable) do
		code(entity)
	end
end

_.setActive=function(entity, isActive)
	-- todo: easier, allow same state
	-- assert(entity.isActive~=isActive)
	if entity.isActive==isActive then
		log("warn: entity have same active state")
		return
	end
	
	entity.isActive=isActive
	
	if isActive then
		activate(entity)
	else
		deactivate(entity)
	end
	
	
end


_.setDrawable=function(entity, isDrawable)
	if entity.isDrawable==isDrawable then
		-- todo: uncomment for optimizations
		--log("warn: entity have same active state")
		return
	end
	
	entity.isDrawable=isDrawable
	
	if isDrawable then
		local entityCode=_get(entity.entity)
		
		table.insert(_drawable,{entity=entity,draw=entityCode.draw})
	else
		removeDrawable(entity,_drawable)
	end
	
end

_.setSprite=function(entity,spriteName)
	entity.spriteName=spriteName
	
	local sprite=Img[spriteName]
	
	entity.w=sprite:getWidth()
	entity.h=sprite:getHeight()
	
	-- notify collision system?
end

	


_.setAiEnabled=function(entity, aiEnabled)
	if entity.aiEnabled==aiEnabled then
		log("warn: entity have same aiEnabled state")
		return
	end
	
	
	
end


_.update=function(dt)
	for entity,updateFunc in pairs(_updateable) do
		updateFunc(entity,dt)
	end
	
	-- todo: update some ai's every frame, instead all at 200
	if Session.frame%200==0 then
		for entity,updateFunc in pairs(_ai) do
			updateFunc(entity,dt)
		end
	end
	
end


_.slowUpdate=function()
		for entity,updateFunc in pairs(_slowUpdateable) do
		updateFunc(entity)
	end
end



_.keypressed=function(key,unicode)
	--local isProcessed=false
	
	-- todo: sort
	-- todo: locking
	for entity,fnPressed in pairs(_keyListeners) do
		local isProcessed=fnPressed(entity,key,unicode)
		if isProcessed then return true end
	end
	
	return false
end

-- client side
_.transferToServer=function(entities)
	if Session.isServer then
		_.acceptAtServer(entities)
		return
	end
	
	
	for k,entity in pairs(entities) do
		entity.isTransferring=true
	end
	
	-- из ивентов можно мержить
	local event=Event.new()
	event.entities=entities
	event.code="transfer_to_server"
end

local getProto=function(entity,entityCode)
	local result=entityCode.new({isProto=true})
	return result
end


_.acceptAtServer=function(entities)
	log("Entity.acceptAtServer")
	local login=nil
	for k,entity in pairs(entities) do
		-- register
		if login==nil then
			login=entity.login
		end
		
		entity.prevId=entity.id
		
		local entityCode=Entity.get(entity.entity)
		local proto=getProto(entity,entityCode)
		if proto.aiEnabled then
			entity.aiEnabled=true
		end
		
		if entity.login~=Session.login then
			entity.id=Id.new(entity.entity)
			entity.login=Session.login
			Entity.register(entity)
		else
			if not Entity.isRegistered(entity) then
				Entity.register(entity)
			end
		end
	end
	
	assert(login~=nil)
	
	-- send back to entities_transferred
	
	local response={}
	response.cmd="entities_transferred"
	
	-- todo: лучше сделать у каждой сущности, но можно позже, пока что все с одного логина
	response.originalLogin=login
	response.entities=entities
	
	Server.send(response)
end

_.debugPrint=function()
	log("Entity debug print start: -------[")
	log("All:")
	
	local toString=Entity.toString
	
	for k,v in pairs(_all) do
		log(toString(v))
	end
	
	log("Drawable:")
	for k,v in pairs(_drawable) do
		log(toString(v.entity))
	end
	
	log("Entity debug print end:   ]-------")
end

_.toString=function(entity)
	if entity==nil then return "nil" end
	local result=entity.entity.." id:"..tostring(entity.id).." rm:"..tostring(entity.isRemote)..
		" xywh:"..xywh(entity).." l:"..entity.login
	return result
end




-- Collision.getAtPoint
--_.getAt=function(x,y)
--	-- wp
--	local result={}
	
--	return result
--end

--should be called after move to update collision sytem
_.onMoved=function(entity)
	-- log("Entity moved:"..Entity.toString(entity))
	Collision.moved(entity)
end




_.getCenter=function(entity)
	local x=entity.x+(entity.w/2)
	local y=entity.y+(entity.h/2)
	
	return x,y
end

_.placeInWorld=function(entity)
	entity.isInWorld=true
		addToCollision(entity)
	_.setActive(entity,true)
end

_.removeFromWorld=function(entity)
	if entity.isInWorld then
		entity.isInWorld=false
		removeFromCollision(entity)
	else
		-- todo:uncomment for optimizing
		--log("warn: removeFromWorld: entity not in world")
	end
end

_.getCount=function()
	return #_all
end



return _
