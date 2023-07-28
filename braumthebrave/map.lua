function draw_map()
    map(0, 0, 0, 0, 16, 16)
end

function is_solid_area(x, y, w, h, f)
    if (not f) f = 0b00000011
    return is_solid(x, y, f)
            or is_solid(x + w, y, f)
            or is_solid(x, y + h, f)
            or is_solid(x + w, y + h, f)
end

function is_solid(x, y, f)
    if (not f) f = 0b00000011
    local m = mget(x / 8, y / 8)
    local lx, ly = x % 8, y % 8
    return band(fget(m), f) > 0
end