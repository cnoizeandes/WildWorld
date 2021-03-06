-- entity manager. single instance.
-- single entity code in base_entity

local _={}

-- _.update=

-- key-index, value - draw - {entity,draw}
local _drawable={}
local _updatable={}
local _lateUpdatable={}

-- ai should not update every turn, or update by parts
local _aiUpdatable={}

-- entity-fnSim(entity)
local _simulations={}

local _keyPressedListeners={}
local _mousePressedListeners={}
local _uiDraws={}
local _uiDrawsUnscaled={}

-- возмжоность получить все зарегенные
local _all={}

-- функция вызывается при удалении сущности с параметром сущности
_.on_removed=nil
_.beforeAdd=nil

--добавить сущность в менеджер
-- use Db.add
_.add=function(entity)
	log('adding entity:'.._.toString(entity),'entity')
	
	local beforeAdd=_.beforeAdd
	if beforeAdd~=nil then
		beforeAdd(entity)
	end
	
	--todo: рассмотреть случай с рефрешем с сервера когда ссылки ломаются на сущность. (если вообще ломаются)
	--table.insert(_all, entity)
	_all[entity]=true
	
	-- entityCode is module with draw,update etc contolling current entity data/dto
	local entityCode=_.getCode(entity)
	
	if entityCode==nil or entity.entity_name=="panther" then
		local a=1
	end
	
	if entityCode==nil then
		local a=1
	end
	
	
	local draw=entityCode.draw
	if draw~=nil then
		table.insert(_drawable,{entity=entity,draw=draw})
	end
	
	local update=entityCode.update
	if update~=nil then
		_updatable[entity]=update
	end
	
	local lateUpdate=entityCode.lateUpdate
	if lateUpdate~=nil then
		_lateUpdatable[entity]=lateUpdate
	end
	
	local drawUi=entityCode.drawUi
	if drawUi~=nil then
		_uiDraws[entity]=drawUi
	end
	
	local drawUnscaledUi=entityCode.drawUnscaledUi
	if drawUnscaledUi~=nil then
		_uiDrawsUnscaled[entity]=drawUnscaledUi
	end
	
	local keyPressed=entityCode.keyPressed
	if keyPressed~=nil then
		_keyPressedListeners[entity]=keyPressed
	end
	
	local mousePressed=entityCode.mousePressed
	if mousePressed~=nil then
		_mousePressedListeners[entity]=mousePressed
	end
	
	local updateAi=entityCode.updateAi
	if updateAi~=nil then
		_aiUpdatable[entity]=updateAi
	end
	
	local simulation=entityCode.update_simulation
	if simulation~=nil then
		_simulations[entity]=simulation
	end
	
	if not entity.isService then
		CollisionService.addEntity(entity)
	end
end

-- drawables are array to make it sortable
local removeDrawable=function(entity,container)
	--local countBefore
	-- log("drawables before remove:"..#container)
	for k,info in ipairs(container) do
		if info.entity==entity then 
			table.remove(container,k)
			-- container[k]=nil wrong way (sort crash on nil)
			
			--log("drawables after remove:"..#container)
			return
		end
	end
	
	local count=#container
	-- log("drawables after remove:"..count)
	
	if count>0 then
		log("error: removeDrawable failed. Entity was not in drawables:".._ets(entity))
	end
end

-- chain: db,entity,collision
_.remove=function(entity)
	removeDrawable(entity,_drawable)
	_all[entity]=nil
	_updatable[entity]=nil
	_lateUpdatable[entity]=nil
	_keyPressedListeners[entity]=nil
	_uiDraws[entity]=nil
	_uiDrawsUnscaled[entity]=nil
	_mousePressedListeners[entity]=nil
	_aiUpdatable[entity]=nil
	_simulations[entity]=nil
	CollisionService.removeEntity(entity)
	
	if _.on_removed~=nil then
		_.on_removed(entity)
	end
end

local compareByDrawLayer=function(info1,info2)
	local entity1=info1.entity
	local entity2=info2.entity
	if entity1.drawLayer>entity2.drawLayer then return false end
	if entity1.drawLayer<entity2.drawLayer then return true end
	return false
end

_.draw=function()
	-- todo: optimize
	table.sort(_drawable,compareByDrawLayer)
	
	for k,drawInfo in ipairs(_drawable) do
		--log("drawing:".._ets(drawInfo.entity))
		drawInfo.draw(drawInfo.entity)
		
	end
end

_.drawUi=function()
	for entity,draw in pairs(_uiDraws) do
		draw()
	end
end

_.drawUnscaledUi=function()
	for entity,draw in pairs(_uiDrawsUnscaled) do
		draw()
	end
end

local _aiKey=nil
local function getNextAiFn()
	
	local entity,fnUpdate=next(_aiUpdatable, _aiKey)
	_aiKey=entity
--	local result=_aiUpdatable[_aiIndex]
--	_aiIndex=_aiIndex+1

	return fnUpdate,entity
end

local _simulationKey=nil
local function getNextSimulationFn()
	local entity,fn=next(_simulations, _simulationKey)
	_simulationKey=entity
	return fn,entity
end



local _isSimulationOrAi=false

_.update=function(dt)
	for entity,updateProc in pairs(_updatable) do
		updateProc(dt)
	end
	
	local frameNumber=Pow.get_frame()
	if frameNumber%60==0 then
		-- log("update ai")
--		for entity,updateAiProc in pairs(_aiUpdatable) do
--			updateAiProc(entity,dt)
--		end
		_isSimulationOrAi=not _isSimulationOrAi

		if _isSimulationOrAi then
			local fnNextAi,entity=getNextAiFn()
			if fnNextAi~=nil then
				fnNextAi(entity)
			end
		else
			local fnNextSimulation,entity=getNextSimulationFn()
			if fnNextSimulation~=nil then
				fnNextSimulation(entity)
			end
		end
		
	end
end


_.lateUpdate=function(dt)
	for entity,updateProc in pairs(_lateUpdatable) do
		updateProc(dt)
	end	
end


_.keyPressed=function(key)
	for entity,listener in pairs(_keyPressedListeners) do
		listener(key)
	end
end

-- 
_.mousePressed=function(gameX,gameY,button,istouch)
	for entity,listener in pairs(_mousePressedListeners) do
		listener(gameX,gameY,button,istouch)
	end
end


_.toString=function(entity)
	if entity==nil then return "nil" end
	
	local result=entity.entity_name
	
-- its ok, ServerService	
--	if entity.level_name==nil then
--		local a=1
--	end
	
		
		
	if entity.id~=nil then
		result=result.." id:"..tostring(entity.id)..' xy:'..
			tostring(entity.x)..','..tostring(entity.y).." lvl:"..tostring(entity.level_name)
	end
	
	return result
end

local _entityCode={}

-- register code that corresponds to data object
_.addCode=function(entity_name,code)
	_entityCode[entity_name]=code
end


-- description of code functions:
-- draw/upd/etc code for entity data/dto
_.getCode=function(entity)
	if entity.isService then
		-- service does not separate data, everything is a single module
		return entity
	else
		local result = _.getCodeByName(entity.entity_name)
		
		return result
	end
end

_.getCodeByName=function(entity_name)
		local result=_entityCode[entity_name]
		if (result==nil) then
			-- log("error: entity has no code:"..entity_name)
		end
		
		return result 
end



_.getCenter=function(entity)
	if entity==nil then
		local a=1
		-- load refactoring, no player
	end
	
	local centerX=entity.x+(entity.w/2)
	local centerY=entity.y+(entity.h/2)
	
	return centerX,centerY
end

-- x,y,w,h
_.getCollisionBox=function(entity)
	local x=entity.x
	local y=entity.y
	local w=entity.w
	local h=entity.h
	local collisionX=entity.collisionX
	local collisionY=entity.collisionY
	if collisionX==nil then collisionX=0 end
	if collisionY==nil then collisionY=0 end
	
	if x==nil or y==nil or w==nil or h==nil then
		log("warn: entity has no box shape (x,y,w,h):".._ets(entity))
		return nil
	end
	
	-- todo: cache this, store as calculated fields of entity
	local collisionBoxX = x + collisionX
	local collisionBoxY = y + collisionY
	
	local collisionBoxW=w-collisionX
	local collisionBoxH=h-collisionY
	
	return collisionBoxX,collisionBoxY,collisionBoxW,collisionBoxH
end

_.equals=function(entity1,entity2)
	if entity1==nil or entity2==nil then 
		return false 
	end
	
	return entity1.id==entity2.id and entity1.entity_name==entity2.entity_name
end

_.unload_state=function()
--	local player=GameState.getPlayer()
--	if player==nil then 
--		-- это происходит на первом получении стейта 
--		-- log("error: not unloading (player is nil)")
--		return 
--	end
	
	if GameState.level==nil then
		-- nothing to unload
		return
	end
	
	
	local level_name=GameState.level.level_name--player.level_name
	
	log("entity:unload_state. level:"..level_name)
	
	for entity,has_entity in pairs(_all) do
		local entity_level_name=entity.level_name
		-- opt: на клиенте можно быстрее
		if level_name==entity_level_name then
			--log("unload:".._ets(entity))
			_.remove(entity)
		end
	end
end

-- light reference
-- reverse: find_by_ref
_.get_reference=function(entity)
	local result={}
	
	result.id=entity.id
	result.entity_name=entity.entity_name
	
	-- todo: может быть избыточно но удобно, понаблюдать
	result.level_name=entity.level_name
	
	return result
end




_.log=function()
	log("logging all entities:")
	for entity,has_entity in pairs(_all) do
		log(_ets(entity))
	end
	
end


-- local state
-- duck typing: local state attached to entity
-- todo: resolve entity update (store locals detached, by ref?)
_.get_locals=function(entity)
	local entity_locals=entity.locals
	if entity_locals==nil then
		entity_locals={}
		entity.locals=entity_locals
	end
	
	return entity_locals
end

-- в gen2 это movable
--_.on_moved=function(movedEntity)
		
--	-- wip paste from gen1
--	-- todo: move collision model 
--	-- todo: condition when
----	if entity.worldId~=nil then
----		Collision.moved(movedEntity)
----	end
	
--	-- todo: move to mountable
--	if movedEntity.mountedBy~=nil then
--		local rider=_deref(movedEntity.mounted_by)
--		local riderX,riderY=Mountable.get_rider_point(movedEntity,rider)
--		-- wip
--		Entity.move(rider,riderX,riderY)
--	end
	
--end


--_.smooth_move=function(entity, duration_sec, x, y)
--	-- wip
--	log("start move:".._ets(entity))
--	local entity_locals=_.get_locals(entity)
--	local prev_tween=entity_locals.move_tween
--	if prev_tween~=nil then
--		log("cancel prev move")
--		prev_tween:stop()
--	end
	
--	local on_complete=function() 
--		entity_locals.move_tween=nil
--		log("end move:".._ets(entity))
--	end
	
--		local on_update=function() 
--		--wip
--		Entity.on_moved(entity)
--	end
	
--	-- wip
	
	
--end

return _

