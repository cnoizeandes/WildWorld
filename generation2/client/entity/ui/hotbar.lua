local _=BaseEntity.new("hotbar",true)


_.drawUi=function()
	-- background
	love.graphics.draw(Img.ui_low,0,0)
	
	-- todo : draw actions/items
end


return _