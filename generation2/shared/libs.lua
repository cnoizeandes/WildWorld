-- connect all the libs
Pow=require "shared.lib.powlov.pow"
Img=require "shared.res.img"
Flux=Pow.flux

Entity=Pow.entity
BaseEntity=Pow.baseEntity



-- shortcuts
log=Pow.debug.log
draw=love.graphics.draw

serialize=Pow.pack
deserialize=Pow.unpack
_ets=Entity.toString
_ref=Entity.get_reference

-- resolve entity from reference dto
-- defined for client and server separatedly
_deref=nil
