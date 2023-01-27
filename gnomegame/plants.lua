plants={}

function plant_seed(x,y)
    local plant={}
    mset(x,y,2)
    mset(x-1,y-2,32)
    mset(x,y-2,32)
    mset(x+1,y-2,32)
    plant.x,plant.y=x*8+3,y*8-1
    add(plants,plant)
end

function draw_plants()
    for k,v in pairs(plants) do
        pset(v.x,v.y,3)
    end
end