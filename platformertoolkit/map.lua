function draw_map()
    map(0, 0, 0, 0, 16, 16)
end

function is_solid_area(x, y, w, h, f)
    return is_solid(x, y, f)
            or is_solid(x + w, y, f)
            or is_solid(x, y + h, f)
            or is_solid(x + w, y + h, f)
end

function is_solid(x, y, f)
    local m = mget(x / 8, y / 8)
    local colflgs = 0b00000001
    if (f != nil and y / 8 > f) colflgs = 0b00000011
    return band(fget(m), colflgs) > 0
end