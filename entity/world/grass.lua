local _={}

_.new=function(options)
	local result=BaseEntity.new(options)
	
	local isProto=false
	if options then
		isProto = options.isProto or false
	end
	
	local spriteName=Lume.randomchoice({"grass","grass2","grass3"})	
	Entity.setSprite(result,spriteName)
	result.entity="Grass"
	result.x=0
	result.y=0
	result.isDrawable=true
	
	BaseEntity.init(result,options)
	
	return result
end

_.draw=DrawableBehaviour.draw



return _