--config
p_acc = 0.6
p_drag = 0.65
p_grav = 0.3
p_jump = 2.5
p_cyote_frames = 5
p_jumpbuff_frames = 5
p_apexglide_frames = 5
p_apexglide_grav = 0.1

--setting up the player
p = {}
p.x, p.y = 8, 8
p.dx, p.dy = 0, 0
p.w, p.h = 3, 5
p.cyote, p.jumpbuff, p.apexglide = 0, 0, 0
p.on_slope = false
p.jumped = false
p.oneway_col_tile_y = 0

function update_p()
    --update cyote time and jumpbuffer
    p.cyote = max(p.cyote - 1, 0)
    if (is_grounded(p)) p.cyote = p_cyote_frames
    p.jumpbuff = max(p.jumpbuff - 1, 0)
    if (btnp(2)) p.jumpbuff = p_jumpbuff_frames
    --x axis input, accellaration, and drag
    local inx = 0
    if (btn(0)) inx -= 1
    if (btn(1)) inx += 1
    p.dx = (p.dx + inx * p_acc) * p_drag

    --y axis gravity and apex glide
    p.apexglide = max(p.apexglide - 1, 0)
    if p.dy < 0 and p.dy + p_grav > 0 then
        p.apexglide = p_apexglide_frames
        p.dy = 0
    end
    if p.apexglide <= 0 then
        p.dy += p_grav
    else
        p.dy += p_apexglide_grav
    end

    --jumping
    p.jumped = false
    if p.cyote > 0 and p.jumpbuff > 0 then
        p.jumped = true
        p.dy = -p_jump
        p.cyote, p.jumpbuff = 0, 0
    end

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

    p.oneway_col_tile_y = ceil(((p.y + p.h) / 8))
    if (btn(3)) p.oneway_col_tile_y += 1

    --y axis collision
    if p.jumped or not p.on_slope then
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

function slope_lift(p)
    local x, y = p.x + flr(p.w / 2), p.y + p.h
    local tile = mget(x / 8, y / 8)
    if fget(tile) & 0b11111100 == 0 then
        return false
    end
    local lx, hlx = x % 8, flr(x % 8 / 2)
    local fy = flr(y / 8) * 8
    if (fget(tile, 2)) fy = fy + 7 - lx
    if (fget(tile, 3)) fy = fy - 1 + lx
    if (fget(tile, 4)) fy = fy + 6 - hlx
    if (fget(tile, 5)) fy = fy + 2 - hlx
    if (fget(tile, 6)) fy = fy - 1 + hlx
    if (fget(tile, 7)) fy = fy + 3 + hlx
    fy = fy - p.h
    if p.y >= fy then
        p.y = fy
        p.dy = 0
        return true
    end
    return false
end

function draw_p()
    rectfill(p.x, p.y, p.x + p.w, p.y + p.h, 8)
    pset(p.x + flr(p.w / 2), p.y + p.h, 7)
end

function is_grounded(p)
    return p.on_slope or is_solid_area(p.x, p.y + 1, p.w, p.h, p.oneway_col_tile_y)
end