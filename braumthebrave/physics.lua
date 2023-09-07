function update_phys_obj(p)
    --y axis gravity
    p.dy += p_grav

    -- x axis drag
    p.dx *= p_drag

    --x axis collision
    for i = p.dx, 0, -sgn(p.dx) do
        local hit = false
        if p.on_slope then
            if is_solid(p.x + i, p.y + p.h / 2) or is_solid(p.x + i + p.w, p.y + p.h / 2) then
                hit = true
            end
        elseif is_solid_area(p.x + i, p.y, p.w, p.h) then
            hit = true
        end

        if hit then
            p.dx = 0
        else
            p.x += i
            break
        end
    end

    --oneway platform detection
    p.oneway_col_tile_y = ceil(((p.y + p.h) / 8))
    if (btn(3)) p.oneway_col_tile_y += 1

    --y axis collision
    if not p.on_slope then
        for i = p.dy, 0, -sgn(p.dy) do
            if is_solid_area(p.x, p.y + i, p.w, p.h, p.oneway_col_tile_y) then
                p.dy = 0
            else
                p.y += i
                break
            end
        end
    end

    --slope handling
    p.on_slope = slope_lift(p)
end

function boxboxoverlap(a,b)
    return not (a.x>=b.x+b.w+1 
        or a.y>=b.y+b.h
        or a.x+a.w<b.x 
        or a.y+a.h+1<b.y)
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

function is_solid_or_slope(x, y, f)
    local m = mget(x / 8, y / 8)
    local colflgs = 0b11111101
    if (f != nil and y / 8 > f) colflgs = 0b11111111
    return band(fget(m), colflgs) > 0
end