-- game specific server code


local _entityName='ServerService'
local _=BaseEntity.new(_entityName, true)

_.isService=true

local _server=Pow.server
local _event=Pow.net.event
local _serverUpdate=_server.update
local _serverLateUpdate=_server.lateUpdate


local createPlayer=function(event)
	local playerName=event.player_name
	local login=event.login
	
	local player=Player.new()
	player.name=playerName
	-- todo: start coord
	player.x=100
	player.y=20
	
	Db.add(player, "player")
	
	local responseEvent=_event.new("create_player_response")
	responseEvent.player=player
	
	responseEvent.target="login"
	responseEvent.targetLogin=login
	
	_event.process(responseEvent)
	
	log('new event: create_player_response')
	
end

local getLevelEntities=function(levelName)
	local levelContainer=Db.getLevelContainer(levelName)
	return levelContainer
end


local getLevelState=function(levelName)
	-- todo state это набор сущностей
	local state={}
	state.bg="main"
	state.entities=getLevelEntities(levelName)
	return state
end


-- player has been created by createPlayer, present in Db
local getPlayerState=function(playerId)
	local player=Player.getById(playerId)
	assert(player)
	
	-- todo: do not return everything server knows about player
	return player
end



local getFullState=function(playerId)
	local player=getPlayerState(playerId)
	local levelState=getLevelState(player.levelName)
	local result={}
	
	result.level=levelState
	result.player=player
	
	return result
end



-- client picked player, and wants to start game. send him game state
local gameStart=function(event)
	log("game_start:"..Pow.pack(event))
	
	local login=event.login
	local playerId=event.playerId
	-- todo: put this player into world, set active
	
	
	local fullState=getFullState(playerId)
	
	local responseEvent=_event.new("full_state")
	responseEvent.target="login"
	responseEvent.targetLogin=login
	responseEvent.state=fullState
	_event.process(responseEvent)
	
	
end

local movePlayer=function(event)
	local responseEvent=_event.new("move")
	responseEvent.target="all"
	responseEvent.x=event.x
	responseEvent.y=event.y
	
	responseEvent.actorRef=event.actorRef

	_event.process(responseEvent)
end


local doMove=function(event)
	local actor=Db.getByRef(event.actorRef, "player")
	Movable.move(actor,event.x,event.y)
end


_.start=function()
	_event.addHandler("create_player", createPlayer)
	_event.addHandler("game_start", gameStart)
	_event.addHandler("intent_move", movePlayer)
	_event.addHandler("move", doMove)
	
	
	_server.listen(ConfigService.port)
	
end

_.update=function(dt)
	_serverUpdate(dt)
end

_.lateUpdate=function(dt)
	_serverLateUpdate(dt)
end




return _