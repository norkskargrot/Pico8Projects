projectile_types = {
    sword_swipe = {
        anim = "none",
        w = 8, h = 5,
        spr_off_x = 0, spr_off_y = 0,
        lifetime = 10,
        alignment = true,
    },
}

projectiles = {}

function init_projectile(x, y, dx, dy, dir, typ)
    typ = projectile_types[typ]
    local n = {}
    n.x, n.y = x, y
    if (dir) n.x -= typ.w
    n.dx, n.dy = dx, dy
    n.dir = dir
    n.typ = typ
    n.spr_off_x, n.spr_off_y = typ.spr_off_x, typ.spr_off_y
    print(n.spr_off_x)
    n.w, n.h = typ.w, typ.h
    n.lifetime = typ.lifetime
    n.animplay = typ.anim
    n.alignment = typ.alignment
    add(projectiles, n)
end

function update_projectiles()
    for k,v in pairs(projectiles) do
        if (v.alignment) then
            for k,e in pairs(entities) do
                if (boxboxoverlap(v,e) and v.alignment != e.alignment) damage_e(e, sgn(e.x - p.x))
            end
        else
            if (boxboxoverlap(v,p) and v.alignment != p.alignment) damage_p(damage_p(sgn(p.x - v.x)))
        end

        v.x += v.dx
        v.y += v.dy
        v.lifetime = v.lifetime - 1
        if (v.lifetime == 0) del(projectiles, v)
    end
end

function draw_projectiles()
    for k,v in pairs(projectiles) do
        animate(v)
        spr_outline(v)
    end 
end