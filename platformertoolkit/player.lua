--config
p_acc=0.8
p_drag=0.8
p_grav=0.5
p_jump=5
p_cyote_frames=5
p_jumpbuff_frames=5     

--setting up the player
p={}
p.x,p.y=8,8
p.dx,p.dy=0,0
p.w,p.h=7,7
p.cyote,p.jumpbuff=0,0
p.spr=2

function update_p ()
    --update cyote time and jumpbuffer
    p.cyote=max(p.cyote-1,0)
    if (is_grounded(p)) p.cyote=p_cyote_frames
    p.jumpbuff=max(p.jumpbuff-1,0)
    if (btnp(2)) p.jumpbuff=p_jumpbuff_frames

    --x axis input, accellaration, and drag
    local inx=0
    if (btn(0)) inx-=1
    if (btn(1)) inx+=1
    p.dx=(p.dx+inx*p_acc)*p_drag

    --y axis gravity and jumping
    p.dy+=p_grav
    if (p.cyote>0 and p.jumpbuff>0) then
        p.dy=-p_jump
        p.cyote,p.jumpbuff=0,0
    end

    --x axis collision
    for i=p.dx,0,-sgn(p.dx) do
        if is_solid_area(p.x+i, p.y, p.w, p.h, 0b00000001) then
            p.dx=0
        else
            p.x+=i
            break
        end
    end

    --oneway platform collision
    local collflgs=0b00000001
    if p.dy>0 and not is_solid_area(p.x,p.y,p.w,p.h,0b00000010) then
        if (not btn(3)) collflgs=0b00000011
    end

    --y axis collision
    for i=p.dy,0,-sgn(p.dy) do
        if is_solid_area(p.x, p.y+i, p.w, p.h, collflgs) then
            p.dy=0
        else
            p.y+=i
            break
        end
    end
end

function draw_p()
    spr(p.spr,p.x,p.y)
end

function is_grounded(p)
    return is_solid_area(p.x,p.y+1,p.w,p.h)
end