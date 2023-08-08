--config
p_acc = 0.3
p_drag = 0.63
p_grav = 0.08
p_jump = 1.7
p_cyote_frames = 10
p_jumpbuff_frames = 10
p_damaged_immunity_frames = 20

--setting up the player
p = {}
--physics
p.x, p.y = 8, 8
p.dx, p.dy = 0, 0
p.w, p.h = 2, 3
p.cyote, p.jumpbuff = 0, 0
p.on_slope = false
p.jumped = false
p.collflgs = 0b00000001
--drawing
p.spr_off_x = - 1
p.spr_off_y = -1
p.animplay = "p_walk"

--gameplay
p.damage_time = 0
p.armoured = true
p.alignment = true

function update_p()
    p.damage_time = max(p.damage_time - 1, 0)

    p_physics()
    p_anim()
    if btnp(4) then
        local x = p.x
        if not p.dir then x += p.w end
        init_projectile(x, p.y - 2, 0, 0, p.dir, "sword_swipe")
    end
end

function p_physics()
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

    --y axis gravity
    p.dy += p_grav

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
    if p.jumped or not p.on_slope then
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
    --if p.y >= fy then
    if p.dy >= 0 then
        p.y = fy
        p.dy = 0
        return true
    end
    --end
    return false
end

function p_anim()
    if (p.dx < 0) p.dir = true
    if (p.dx > 0) p.dir = false
    
    if p.animstate == "p_idle" or p.animstate == "p_walk" then
        if not is_grounded(p) then
            if p.dy > 0 then
                p.animplay = "p_aerial_up"
            else
                p.animplay = "p_aerial_down"
            end
        elseif abs(p.dx) > 0.3 then
            p.animplay = "p_walk"
        elseif abs(p.dx) < 0.3 then
            p.animplay = "p_idle"
        end
    elseif p.animstate == "p_aerial_up" or p.animstate == "p_aerial_down" then
        if p.dy > 0 then
            p.animplay = "p_aerial_up"
        else
            p.animplay = "p_aerial_down"
        end
        if is_grounded(p) then
            p.animplay = "p_idle"
        end
    end

    -- Attacking
    if (btnp(4)) p.animplay = "p_attack"
end

function damage_p(x_bounce)
    if (p.damage_time > 0) return
    p.damage_time = p_damaged_immunity_frames

    p.dx = x_bounce * 4
    p.dy = -1

    if p.armoured then
        p.armoured = false
    else
        --stop()
    end
end

function draw_p()
    --rect(p.x, p.y, p.x + p.w, p.y + p.h, 8)
    --pset(p.x + flr(p.w / 2), p.y + p.h, 7)
    animate(p)
    spr_outline(p)
    p.pal = nil
    if (p.damage_time > 0) p.pal = {11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11}
    set_pal()
end

function is_grounded(p)
    return p.on_slope or is_solid_area(p.x, p.y + 1, p.w, p.h, p.collflgs)
end