local _={}

_.name="HorseSmall"

_.new=function(options)
	local result=BaseEntity.new(options)
	
	result.x=0
	result.y=0
	
	result.mountX=7
	result.mountY=17
	
	result.originX=7
	result.originY=18	
	
	result.footX=7
	result.footY=22
	
	Entity.setSprite(result,"horse_small")
	result.isDrawable=true
	result.aiEnabled=true
	result.isMountable=true
	
	Entity.afterCreated(result,_,options)
	
	return result
end

_.draw=DrawableBehaviour.draw

_.updateAi=require("misc/ai/pantera_ai")

return _