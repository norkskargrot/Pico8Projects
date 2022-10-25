plants={}

function createplant(x,y)
    if (not issolid(x,y)) return
    fx=flr(x/8)*8
    if (x%8>3) fx+=8
    fy=flr(y/8)*8
    local newplant={x=fx,y=fy}
    newplant.points={}

    --initialise vine in direction 1
    local currpoint
    if (issolid(fx-8,fy-8)) then currpoint=initialpoint(newplant,0,-1)
    elseif (issolid(fx-8,fy)) then currpoint=initialpoint(newplant,-1,0)
    else currpoint=initialpoint(newplant,0,1)
    end
    currpoint.c=12
    for i=0,8 do
        currpoint=(newpoint(currpoint))
    end

    --initialise vine in direction 2
    if (issolid(fx,fy-8)) then currpoint=initialpoint(newplant,0,-1)
    elseif (issolid(fx,fy)) then currpoint=initialpoint(newplant,1,0)
    else currpoint=initialpoint(newplant,0,1)
    end
    currpoint.c=11
    
    add(plants,newplant)
end

function initialpoint(plant,dx,dy)
    local newpoint={}
    newpoint.x,newpoint.y=plant.x+dx*8,plant.y+dy*8
    newpoint.dx,newpoint.dy=dx,dy
    newpoint.points={}
    add(plant.points,newpoint)
    return newpoint
end

function newpoint(prevpoint)
    local newpoint={}
    local dx,dy=0,0
    newpoint.x,newpoint.y=prevpoint.x+prevpoint.dx*8,prevpoint.y+prevpoint.dy*8
    newpoint.dx,newpoint.dy=dx,dy
    newpoint.points={}
    newpoint.c=prevpoint.c
    add(prevpoint.points,newpoint)
    return newpoint
end

function updateplants()

end

function drawplants()
    for k,v in pairs(plants) do
        circfill(v.x,v.y,1,4)
        local activepoints={v}
        while #activepoints>0 do
            for i=#activepoints,1,-1 do
                local currpoint=activepoints[i]
                for k,p in pairs(currpoint.points) do
                    add(activepoints,p)
                    line(p.x,p.y,currpoint.x,currpoint.y,p.c)
                    pset(currpoint.x,currpoint.y,8)
                end
                deli(activepoints,i)
            end
        end
    end
end
