function set_pal()
    pal()
    pal({[0]=0,128,132,4,137,9,15,3,139,1,2,7,8,133,5,6},1)
end

anims={
    none = {0},
    p_idle = {10, fr = 30},
    p_walk = {9, 10, 11, 10, fr = 8},
    p_attack = {12, 13, 14, fr = 3, next = "p_idle"},
    p_aerial_up = {15, 16, fr = 3},
    p_aerial_down = {20, 20, fr = 1},
    swipe = {25, 26, 27, 28, fr = 3},
    slow_walk = {17, 18, 19, 18, fr = 20},
    slow_dead = {21, fr = 20},
}

function animate(p)
    -- start a new animation
    if p.animstate != p.animplay then
        p.animstate = p.animplay
        p.animindex = 1
        p.animtime = 0
    elseif #anims[p.animstate] > 1 then --continue playing an animation with multiple frames
        p.animtime += 1
        if p.animtime >= anims[p.animstate].fr then --the current frame has been on screen for long enough
            p.animtime = 0
            p.animindex = (p.animindex % #anims[p.animstate]) + 1 --go to the next frame
            --this loops animations
            if p.animindex == 1 and anims[p.animstate].next then --at the moment the animation restarts,
                p.animplay = anims[p.animstate].next                    --play something else instead
                p.animstate = p.animplay
            end
        end
    end
    p.spr = anims[p.animstate][p.animindex] --lastly, update the current sprite number drawn to screen
end

function spr_outline(p)
    local dir_x_offset = p.spr_off_x
    if (p.dir) dir_x_offset = p.w - 8 - p.spr_off_x
    local x,y = p.x + dir_x_offset, p.y + p.spr_off_y

    for i=0,15 do pal(i,0) end
    spr(p.spr, x + 1, y, 1, 1, p.dir)
    spr(p.spr, x - 1, y, 1, 1, p.dir)
    spr(p.spr, x, y + 1, 1, 1, p.dir)
    spr(p.spr, x, y - 1, 1, 1, p.dir)

    if p.pal != nil then
        pal(p.pal)
    else
        set_pal()
    end
    spr(p.spr, x, y, 1, 1, p.dir)
end