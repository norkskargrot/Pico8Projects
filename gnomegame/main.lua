function _init()
    --64*64 screen mode
    poke(0x5f2c,3)
    initplayer()
end

function _update()
    updateplayer()
    updbtns()
    updateplants()
end

function _draw()
    cls()
    map(0,0,0,0,16,16)
    drawplants()
    drawplayer()
end