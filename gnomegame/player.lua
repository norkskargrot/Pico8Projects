local friction=0.8

function initplayer()
    p={}
    p.x,p.y=32,32
    p.dx,p.dy=0,0
    p.w,p.h=5,5
end

function updateplayer()
    local input={x=0,y=0}
    if (btn(0)) p.dx-=0.5
    if (btn(1)) p.dx+=0.5


    if (btnd(2)) p.dy=-5
    p.dy+=0.5

    p.dx*=friction

    for i=p.dx,0,-sgn(p.dx) do
        if not solidarea(p.x+i,p.y,p.w,p.h) then
            p.x+=i
            break
        else
            p.dx=0
        end
    end
    for i=p.dy,0,-sgn(p.dy) do
        if not solidarea(p.x,p.y+i,p.w,p.h) then 
            p.y+=i
            break
        else
            p.dy=0
        end
    end

    if (btnd(4)) createplant(p.x+p.w/2,p.y+p.h+1)
end

function drawplayer()
    rect(p.x,p.y,p.x+p.w,p.y+p.h,12)
end