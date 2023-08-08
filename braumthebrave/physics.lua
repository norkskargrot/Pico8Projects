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
        elseif is_solid_area(p.x + i, p.y, p.w, p.h, 0b00000001) then
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
    p.collflgs = 0b00000001
    if p.dy > 0 and not is_solid_area(p.x, p.y, p.w, p.h, 0b00000010) then
        if (not btn(3)) p.collflgs = 0b00000011
    end

    --y axis collision
    if not p.on_slope then
        for i = p.dy, 0, -sgn(p.dy) do
            if is_solid_area(p.x, p.y + i, p.w, p.h, p.collflgs) then
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