rooms = {
    {
        x1 = 0, y1 = 0, x2 = 15, y2 = 15,
        entities = {
            {typ = "slow", x = 5, y = 5}
        },
    },
    { x1 = 15, y1 = 6, x2 = 22, y2 = 15 },
    { x1 = 15, y1 = 1, x2 = 29, y2 = 6 },
    { x1 = 22, y1 = 6, x2 = 34, y2 = 14 }
}

curr_room = 1
prev_room = 1

function init_map()
    change_room(1)
end

function update_room()
    if (is_in_room(curr_room, p.x, p.y)) return
    for i = 1, #rooms do
        if is_in_room(i, p.x, p.y) then
            change_room(i)
            return
        end
    end
end

function is_in_room(n, x, y)
    x, y = x / 8, y / 8
    local r = rooms[n]
    return x >= r.x1 and x <= r.x2 and y >= r.y1 and y <= r.y2
end

function change_room(n)
    prev_room = curr_room
    curr_room = n
    init_room_entities(rooms[curr_room].entities)
end

function draw_map()
    draw_room(rooms[prev_room])
    draw_room(rooms[curr_room])
end

function draw_room(r)
    map(r.x1, r.y1, r.x1 * 8, r.y1 * 8, r.x2 - r.x1 + 1, r.y2 - r.y1 + 1)
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