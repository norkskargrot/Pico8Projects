
function draw_map()
    map(0,0,0,0,16,16)
end

function is_solid_area(x,y,w,h,f)
    if (not f) f=0b00000011
    return (
        is_solid(x,y,f) or
        is_solid(x+w,y,f) or
        is_solid(x,y+h,f) or
        is_solid(x+w,y+h,f)
    )
end

function is_solid(x,y,f)
    if (not f) f=0b00000011
    local m=mget(x/8,y/8)
    if (fget(m,2)) return (y%8)-(x%8)/2>-1
    if (fget(m,3)) return (y%8)-(x%8)/2>=3
    if (fget(m,4)) return (y%8)+(x%8)/2>=7
    if (fget(m,5)) return (y%8)+(x%8)/2>=3
    return(band(fget(m), f)>0)
end
