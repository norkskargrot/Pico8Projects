entities = {}
e_damage_immunity_frames = 20

-- Array must be initiaised after code to contain function references
function init_entity_types()
    entity_types = {
        slow = {
            upd = slow_u,
            w = 3, h = 7,
            firstanim = "slow_walk",
            deadanim = "slow_dead",
            spr_off_x = -2, spr_off_y = 0,
            alignment = false,
            health = 3
        }
    }
end

function init_room_entities(entities_to_init)
    entities = {}
    for k,v in pairs(entities_to_init) do
        init_entity(v.x * 8, v.y * 8, v.typ)
    end
end

-- Expects position and a type string
function init_entity(x, y, typ)
    typ = entity_types[typ]

    local n = {}
    n.x, n.y, n.w, n.h = x, y, typ.w, typ.h
    n.dx, n.dy = 0,0
    n.spr_off_x, n.spr_off_y = typ.spr_off_x, typ.spr_off_y
    n.dir = true
    n.typ = typ
    n.animplay = typ.firstanim
    n.health = typ.health
    n.damage_time = 0
    n.upd = typ.upd
    n.alignment = typ.alignment

    add(entities, n)
end

function update_entities()
    for k,v in pairs(entities) do
        v.upd(v)
        v.damage_time = max(v.damage_time - 1, 0)
    end
end

function draw_entities()
    for k,v in pairs(entities) do
        animate(v)
        v.pal = nil
        if (v.damage_time > 0) v.pal = {11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11}
        spr_outline(v)
    end
end

-- Shared functions
function hurt_player(v)
    if (boxboxoverlap(p,v)) then
        damage_p(sgn(p.x - v.x))
    end
end

function damage_e(e, x_bounce)
    if (e.damage_time > 0) return
    e.damage_time = e_damage_immunity_frames

    e.dx = x_bounce * 4
    e.dy = -0.8

    e.health -= 1
    if (e.health <= 0) then
        e.upd = justphys_u
        e.animplay = e.typ.deadanim
        e.alignment = true
    end
end

function wall_in_front(p)
    local x = p.x + sgn(p.dx)
    return is_solid(x, p.y) or is_solid(x + p.w, p.y)
end

function cliff_in_front(p)
    if p.dir then
        return (not is_solid_or_slope(p.x, p.y + p.h + 4))
    else
        return (not is_solid_or_slope(p.x + p.w, p.y + p.h + 4))
    end
end

function justphys_u(p)
    update_phys_obj(p)
end

-- The slow zombie
function slow_u (p)
    if (wall_in_front(p)) p.dir = not p.dir
    if (cliff_in_front(p)) p.dir = not p.dir
    p.dx += p.dir and -0.1 or 0.1
    update_phys_obj(p)
    hurt_player(p)
end