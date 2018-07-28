local _={}

_.new=function(options)
	local result=BaseEntity.new(options)
	
	result.entity="Cauldron"
	result.x=0
	result.y=0
	Entity.setSprite(result,"cauldron")
	result.isDrawable=true
	result.isInWorld=false
	--result.aiEnabled=true
	result.canPickup=true
	
	BaseEntity.init(result,options)
	
	return result
end

_.draw=function(entity)
	if not entity.isInWorld then return end
	
	local sprite=Img[entity.spriteName]
	LG.draw(sprite,entity.x,entity.y)
end

-- place self in world
_.use=function(cauldron,x,y)
	-- todo: destroy on stack end
	
	log(
		"cauldron use. isRegistered:"..tostring(Entity.isRegistered(cauldron)).." "..Entity.toString(cauldron)
	)

	Entity.usePlaceable(cauldron,x,y)


end



return _