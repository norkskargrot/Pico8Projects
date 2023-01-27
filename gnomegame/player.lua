--config
p_acc=0.4
p_drag=0.6
p_grav=0.2
p_jump=2.6
p_cyote_frames=5
p_jumpbuff_frames=5
p_width,p_height=3,5

--setting up the player
p={}
p.x,p.y=8,8
p.dx,p.dy=0,0
p.w,p.h=p_width,p_height
p.cyote,p.jumpbuff=0,0
p.spr=2
p.dir=false
p.animcycle=0
p.collflgs=0b00000001

function update_p ()
    p_movement()
    if btnp(3) and is_grounded(p) and mget(standing_on(p))==1 then
        plant_seed(standing_on(p))
    end
end

function p_movement ()
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
            --climb slopes
            local climb_height=ceil(abs(i/2))
            if not is_solid_area(p.x+i, p.y-climb_height, p.w, p.h, 0b00000001) then
                p.y-=climb_height
            else
                p.dx=0
            end
        else
            p.x+=i
            break
        end
    end

    --oneway platform collision
    p.collflgs=0b00000001
    if p.dy>0 and not is_solid_area(p.x,p.y,p.w,p.h,0b00000010) then
        if (not btn(3)) p.collflgs=0b00000011
    end

    --y axis collision
    for i=p.dy,0,-sgn(p.dy) do
        if is_solid_area(p.x, p.y+i, p.w, p.h, p.collflgs) then
            p.dy=0
        else
            p.y+=i
            break
        end
    end
end

function draw_p()
    p.animcycle+=p.dx
    p.spr=16+(p.animcycle/4)%2
    if (abs(p.dx)>0.1) p.dir=p.dx<0
    if (not is_grounded(p)) p.spr=18
    spr(p.spr,p.x-2,p.y-2,1,1,p.dir)
end

function is_grounded(p)
    return is_solid_area(p.x,p.y+1,p.w,p.h,p.collflgs)
end

function standing_on(p)
    return flr((p.x+p.w/2)/8),(flr((p.y+1+p.h)/8))
end