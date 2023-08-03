--config
cam_speed_x = 2
cam_speed_y = 0.1
cam_pos_x = 32
cam_pos_y = 40
cam_push_bound = 8
cam_dir_bound = 18

--initialise camera
cam = {}
cam.x, cam.y = 0, 0
cam.goalx, cam.goaly = 0, 0
cam.dir = 1

function update_cam()
    local room = rooms[curr_room]

    -- Camera x axis
    local px = p.x + flr(p.w / 2) - cam_pos_x
    local push_bound = cam.x + cam_pos_x - cam.dir * cam_push_bound
    local dir_bound_A = cam.x + cam_pos_x - cam.dir * cam_dir_bound
    local dir_bound_B = cam.x + cam_pos_x + cam.dir * cam_push_bound
    local room_bound_L = room.x1 * 8
    local room_bound_R = (room.x2 - 7) * 8
    if cam.dir > 0 then
        if p.x >= push_bound then
            cam.goalx = p.x - cam_pos_x + cam.dir * cam_push_bound
        end
        if (p.x <= dir_bound_A) cam.dir = -1
        if (p.x >= dir_bound_B and cam.goalx > room_bound_R) cam.dir = -1
    else
        if p.x <= push_bound then
            cam.goalx = p.x - cam_pos_x + cam.dir * cam_push_bound
        end
        if (p.x >= dir_bound_A) cam.dir = 1
        if (p.x <= dir_bound_B and cam.goalx < room_bound_L) cam.dir = 1
    end
    --limit goalx to current room
    cam.goalx = min(room_bound_R, max(room_bound_L, cam.goalx))
    --linearly move camera to goal x
    local camx_diff = cam.goalx - cam.x
    cam.x = cam.x + sgn(camx_diff) * min(cam_speed_x, abs(camx_diff))

    -- Camera y axis
    local py = p.y - cam_pos_y
    if (cam.goaly < py) cam.goaly = py
    if (is_grounded(p)) cam.goaly = py
    --limit goaly to current room
    cam.goaly = min((room.y2 - 7) * 8, max(room.y1 * 8, cam.goaly))
    --move camera to goal y with an easing curve
    cam.y = cam.y + (cam.goaly - cam.y) * cam_speed_y

    camera(cam.x, cam.y)
    --draw_cam_debug(dir_bound_A, dir_bound_B, push_bound)
end

function draw_cam_debug(dir_bound_A, dir_bound_B, push_bound)
    --line(p.x, 0, p.x, 127, 12)
    line(dir_bound_A, 0, dir_bound_A, 127, 9)
    line(dir_bound_B, 0, dir_bound_B, 127, 10)
    line(push_bound, 0, push_bound, 127, 11)
end