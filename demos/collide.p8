pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- wall and actor collisions
-- by zep

actor = {} -- all actors

-- make an actor
-- and add to global collection
-- x,y means center of the actor
-- in map tiles
function make_actor(k, x, y)
	a={
		k = k,
		x = x,
		y = y,
		dx = 0,
		dy = 0,		
		frame = 0,
		t = 0,
		friction = 0.15,
		bounce  = 0.3,
		frames = 2,
		
		-- half-width and half-height
		-- slightly less than 0.5 so
		-- that will fit through 1-wide
		-- holes.
		w = 0.4,
		h = 0.4
	}
	
	add(actor,a)
	
	return a
end

function _init()

	-- create some actors
	
	-- make player
	pl = make_actor(21,2,2)
	pl.frames=4
	
	-- bouncy ball
	local ball = make_actor(33,8.5,11)
	ball.dx=0.05
	ball.dy=-0.1
	ball.friction=0.02
	ball.bounce=1
	
	-- red ball: bounce forever
	-- (because no friction and
	-- max bounce)
	local ball = make_actor(49,7,8)
	ball.dx=-0.1
	ball.dy=0.15
	ball.friction=0
	ball.bounce=1
	
	-- treasure
	
	for i=0,16 do
		a = make_actor(35,8+cos(i/16)*3,
		    10+sin(i/16)*3)
		a.w=0.25 a.h=0.25
	end
	
	-- blue peopleoids
	
	a = make_actor(5,7,5)
	a.frames=4
	a.dx=1/8
	a.friction=0.1
	
	for i=1,6 do
	 a = make_actor(5,20+i,24)
	 a.frames=4
	 a.dx=1/8
	 a.friction=0.1
	end
	
end

-- for any given point on the
-- map, true if there is wall
-- there.

function solid(x, y)
	-- grab the cel value
	val=mget(x, y)
	
	-- check if flag 1 is set (the
	-- orange toggle button in the 
	-- sprite editor)
	return fget(val, 1)
	
end

-- solid_area
-- check if a rectangle overlaps
-- with any walls

--(this version only works for
--actors less than one tile big)

function solid_area(x,y,w,h)
	return 
		solid(x-w,y-h) or
		solid(x+w,y-h) or
		solid(x-w,y+h) or
		solid(x+w,y+h)
end


-- true if [a] will hit another
-- actor after moving dx,dy

-- also handle bounce response
-- (cheat version: both actors
-- end up with the velocity of
-- the fastest moving actor)

function solid_actor(a, dx, dy)
	for a2 in all(actor) do
		if a2 != a then
		
			local x=(a.x+dx) - a2.x
			local y=(a.y+dy) - a2.y
			
			if ((abs(x) < (a.w+a2.w)) and
					 (abs(y) < (a.h+a2.h)))
			then
				
				-- moving together?
				-- this allows actors to
				-- overlap initially 
				-- without sticking together    
				
				-- process each axis separately
				
				-- along x
				
				if (dx != 0 and abs(x) <
				    abs(a.x-a2.x))
				then
					
					v=abs(a.dx)>abs(a2.dx) and 
					  a.dx or a2.dx
					a.dx,a2.dx = v,v
					
					local ca=
					 collide_event(a,a2) or
					 collide_event(a2,a)
					return not ca
				end
				
				-- along y
				
				if (dy != 0 and abs(y) <
					   abs(a.y-a2.y)) then
					v=abs(a.dy)>abs(a2.dy) and 
					  a.dy or a2.dy
					a.dy,a2.dy = v,v
					
					local ca=
					 collide_event(a,a2) or
					 collide_event(a2,a)
					return not ca
				end
				
			end
		end
	end
	
	return false
end


-- checks both walls and actors
function solid_a(a, dx, dy)
	if solid_area(a.x+dx,a.y+dy,
				a.w,a.h) then
				return true end
	return solid_actor(a, dx, dy) 
end

-- return true when something
-- was collected / destroyed,
-- indicating that the two
-- actors shouldn't bounce off
-- each other

function collide_event(a1,a2)
	
	-- player collects treasure
	if (a1==pl and a2.k==35) then
		del(actor,a2)
		sfx(3)
		return true
	end
	
	sfx(2) -- generic bump sound
	
	return false
end

function move_actor(a)

	-- only move actor along x
	-- if the resulting position
	-- will not overlap with a wall

	if not solid_a(a, a.dx, 0) then
		a.x += a.dx
	else
		a.dx *= -a.bounce
	end

	-- ditto for y

	if not solid_a(a, 0, a.dy) then
		a.y += a.dy
	else
		a.dy *= -a.bounce
	end
	
	-- apply friction
	-- (comment for no inertia)
	
	a.dx *= (1-a.friction)
	a.dy *= (1-a.friction)
	
	-- advance one frame every
	-- time actor moves 1/4 of
	-- a tile
	
	a.frame += abs(a.dx) * 4
	a.frame += abs(a.dy) * 4
	a.frame %= a.frames

	a.t += 1
	
end

function control_player(pl)

	accel = 0.05
	if (btn(0)) pl.dx -= accel 
	if (btn(1)) pl.dx += accel 
	if (btn(2)) pl.dy -= accel 
	if (btn(3)) pl.dy += accel 
	
end

function _update()
	control_player(pl)
	foreach(actor, move_actor)
end

function draw_actor(a)
	local sx = (a.x * 8) - 4
	local sy = (a.y * 8) - 4
	spr(a.k + a.frame, sx, sy)
end

function _draw()
	cls()
	
	room_x=flr(pl.x/16)
	room_y=flr(pl.y/16)
	camera(room_x*128,room_y*128)
	
	map()
	foreach(actor,draw_actor)
	
end

__gfx__
000000003bbbbbb7dccccc770cccccc00000000000ccc70000ccc70000ccc70000ccc70000000000000000000000000000000000000000000000000000000000
000000003000000bd0000077d000007c101110100cccccc00cccccc00cccccc00cccccc000000000000000000000000000000000000000000000000000000000
000000003000070bd000000cd000770c000000000cffffc00cffffc00cffffc00cffffc000000000000000000000000000000000000000000000000000000000
000000003000000bd000000cd000770c000000000c5ff5c00c5ff5c00c5ff5c00c5ff5c000000000000000000000000000000000000000000000000000000000
000000003000000bd000000cd000000c000000000cffffc00cffffcc0cffffc0ccffffc000000000000000000000000000000000000000000000000000000000
000000003000000bd000000cd000000c00101101ccccccccccccccc0cccccccc0ccccccc00000000000000000000000000000000000000000000000000000000
000000003000000bd000000cd000000c000000000cccccc00cccccc00cccccc00cccccc000000000000000000000000000000000000000000000000000000000
00000000111111115111111101111110000000000c0000c0c00000c00c0000c00c00000c00000000000000000000000000000000000000000000000000000000
aaaaaaaa00ffff0000ffff0000000000000000000770077077000770077007700770007700000000000000000000000000000000000000000000000000000000
a000000a00dffd0000dffd0000000000000000000e7007e0e77007e00e7007e00e70077e00000000000000000000000000000000000000000000000000000000
a000000a00ffff0000ffff0000000000000000000e7007e00e7007e00e7007e00e7007e000000000000000000000000000000000000000000000000000000000
a000000a0882288ff882288000000000000000000777777007777770077777700777777000000000000000000000000000000000000000000000000000000000
a000000af08228000082280f00000000000000000717717007177170071771700717717000000000000000000000000000000000000000000000000000000000
a000000a008558000085580000000000000000000077770000777700007777000077770000000000000000000000000000000000000000000000000000000000
a000000a005005000500005000000000000000000077770000777770007777000777770000000000000000000000000000000000000000000000000000000000
aaaaaaaa066006606600006600000000000000000700070000700000007000700000070000000000000000000000000000000000000000000000000000000000
0000000000aaaa000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a0000a00700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000770a70007707000aa000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000770a7000770700aa7a0000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000000a7000000700aaaa0000a7aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000000a70000007000aa000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a0000a00700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888887788888877800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888887788888877800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008e8888888e88888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008eee88888eee888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008ee888008ee888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc7700000000
d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d0000077d000007700000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
51111111511111115111111151111111511111115111111151111111511111115111111151111111511111115111111151111111511111115111111100000000
dccccc7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dccccc7700000000
d000007700000000000000000000000000000000000000000000000000000000000000001011101000000000000000000000000000000000d000007700000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000010110100000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
51111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005111111100000000
dccccc770000000000000000000000000000000000000000000000000cccccc0000000000000000000000000000000000000000000000000dccccc7700000000
d0000077000000000000000000000000000000000000000000000000d000007c000000000000000000000000000000000000000010111010d000007700000000
d000000c000000000000000000000000000000000000000000000000d000770c000000000000000000000000000000000000000000000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000770c000000000000000000000000000000000000000000000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000101101d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000c000000000000000000000000000000000000000000000000d000000c00000000
51111111000000000000000000000000000000000000000000000000011111100000000000000000000000000ffff00000000000000000005111111100000000
0cccccc0dccccc77dccccc77dccccc77000000000000000000000000000000000000000000000000000000000dffd00000000000000000000cccccc000000000
d000007cd0000077d0000077d0000077000000000000000000000000101110100000000000000000000000000ffff0000000000000000000d000007c00000000
d000770cd000000cd000000cd000000c00000000000000000000000000000000000000000000000000000000882288f00000000000000000d000770c00000000
d000770cd000000cd000000cd000000c0000000000000000000000000000000000000000000000000000000f082280000000000000000000d000770c00000000
d000000cd000000cd000000cd000000c00000000000000000000000000000000000000000000000000000000085580000000000000000000d000000c00000000
d000000cd000000cd000000cd000000c00000000000000000000000000101101000000000000000000000000050050000000000000000000d000000c00000000
d000000cd000000cd000000cd000000c00000000000000000000000000000000000000000000000000000000660066000000000000000000d000000c00000000
01111110511111115111111151111111000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000
dccccc7700000000000000000000000000000000000000000000000000000000000000003bbbbbb700000000000000000000000000000000dccccc7700000000
d000007700000000101110100000000000000000000000000000000000000000000000003000000b00000000000000000000000000000000d000007700000000
d000000c00000000000000000000000000000000000000000000000000000000000000003000070b00000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000003000000b00000000000000000000000000000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000000000000ccc70003000000b00000000000000000000000000000000d000000c00000000
d000000c00000000001011010000000000000000000000000000000000000000cccccc003000000b00000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000cffffc003000000b00000000000000000000000000000000d000000c00000000
5111111100000000000000000000000000000000000000000000000000000000c5ff5c0011111111000000000000000000000000000000005111111100000000
dccccc7700000000dccccc770000000000000000008888000000000000000000cffffc000000000000000000000000000cccccc000000000dccccc7700000000
d000007700000000d0000077000000000000000018888880000000000000000cccccccc0000000000000000000000000d000007c00000000d000007700000000
d000000c00000000d000000c0000000000000000288888880000000000000000cccccc00000000000000000000000000d000770c00000000d000000c00000000
d000000c00000000d000000c00000000000000002e8e8e8e0000000000000000c0000c00000000000000000000000000d000770c00000000d000000c00000000
d000000c00000000d000000c00000000000000002e8e8e8e000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c00000000d000000c000000000000000022888888000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c00000000d000000c000000000000000002288880000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
51111111000000005111111100000000000000000022220000000000000000000000000000000000000000000000000001111110000000005111111100000000
dccccc770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dccccc7700000000dccccc7700000000
d00000770000000000000000000000000000000000000000101110100000000000000000000000000000000000000000d000007700000000d000007700000000
d000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000001011010000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000d000000c00000000d000000c00000000
51111111000000000000000000000000000000000000000000000000000000000a0000a000000000000000000000000051111111000000005111111100000000
dccccc7700000000000000000000000000000000000000000000000000000000a000770a000000003bbbbbb700000000dccccc77000000000cccccc000000000
d000007700000000000000000000000000000000000000000000000000000000a000770a101110103000000b00000000d000007700000000d000007c00000000
d000000c00000000000000000000000000000000000000000000000000000000a000000a000000003000070b00000000d000000c00000000d000770c00000000
d000000c00000000000000000000000000000000000000000000000000000000a000000a000000003000000b00000000d000000c00000000d000770c00000000
d000000c000000000000000000000000000000000000000000000000000000000a0000a0000000003000000b00000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000000000000000000000aaaa00001011013000000b00000000d000000c00000000d000000c00000000
d000000c0000000000000000000000000000000000000000000000000000000000000000000000003000000b00000000d000000c00000000d000000c00000000
51111111000000000000000000000000000000000000000000000000000000000000000000000000111111110000000051111111000000000111111000000000
0cccccc00000000000000000dccccc77dccccc77dccccc770000000000000000000000003bbbbbb73bbbbbb7000000000000000000000000dccccc7700000000
d000007c1011101000000000d0000077d0000077d00000770000000000000000000000003000000b3000000b000000000000000000000000d000007700000000
d000770c0000000000000000d000000cd000000cd000000c0000000000000000000000003000070b3000070b000000000000000000000000d000000c00000000
d000770c0000000000000000d000000cd000000cd000000c0000000000000000000000003000000b3000000b000000000000000000000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c0000000000000000000000003000000b3000000b000000000000000000000000d000000c00000000
d000000c0010110100000000d000000cd000000cd000000c0000000000000000000000003000000b3000000b000000000000000000000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c0000000000000000000000003000000b3000000b000000000000000000000000d000000c00000000
01111110000000000000000051111111511111115111111100000000000000000000000011111111111111110000000000000000000000005111111100000000
dccccc770000000000000000dccccc77dccccc77dccccc77000000000000000000000000000000000000000000000000dccccc7700000000dccccc7700000000
d00000770000000000000000d0000077d0000077d0000077000000000000000000000000101110100000000000000000d000007700000000d000007700000000
d000000c0000000000000000d000000cd000000cd000000c000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c000000000000000000000000001011010000000000000000d000000c00000000d000000c00000000
d000000c0000000000000000d000000cd000000cd000000c000000000000000000000000000000000000000000000000d000000c00000000d000000c00000000
51111111000000000000000051111111511111115111111100000000000000000000000000000000000000000000000051111111000000005111111100000000
dccccc77000000000000000000000000000000000000000000000000dccccc77dccccc77dccccc77dccccc77dccccc77dccccc7700000000dccccc7700000000
d0000077000000000000000000000000000000000000000000000000d0000077d0000077d0000077d0000077d0000077d000007710111010d000007700000000
d000000c000000000000000000000000000000000000000000000000d000000cd000000cd000000cd000000cd000000cd000000c00000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000cd000000cd000000cd000000cd000000cd000000c00000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000cd000000cd000000cd000000cd000000cd000000c00000000d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000cd000000cd000000cd000000cd000000cd000000c00101101d000000c00000000
d000000c000000000000000000000000000000000000000000000000d000000cd000000cd000000cd000000cd000000cd000000c00000000d000000c00000000
51111111000000000000000000000000000000000000000000000000511111115111111151111111511111115111111151111111000000005111111100000000
dccccc77000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccc000000000
d000007700000000000000001011101000000000000000000000000000000000000000000000000000000000000000000000000000000000d000007c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000770c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000770c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
d000000c00000000000000000010110100000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
d000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000c00000000
51111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000
0cccccc0dccccc77dccccc77dccccc77dccccc770cccccc0dccccc77dccccc77dccccc77dccccc77dccccc77dccccc77dccccc770cccccc0dccccc7700000000
d000007cd0000077d0000077d0000077d0000077d000007cd0000077d0000077d0000077d0000077d0000077d0000077d0000077d000007cd000007700000000
d000770cd000000cd000000cd000000cd000000cd000770cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000770cd000000c00000000
d000770cd000000cd000000cd000000cd000000cd000770cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000770cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
d000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000cd000000c00000000
01111110511111115111111151111111511111110111111051111111511111115111111151111111511111115111111151111111011111105111111100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000770077000000707077707770700000000000000000000000000000007070000077700000707070707770777000000000000000000000000000000000
70700000070007000000707070007070700000000000000000000000000000007070000000700000707070707070707000000000000000000000000000000000
07000000070007000000777077707070777000000000000000000000000000007770000007700000777077707770777000000000000000000000000000000000
70700000070007000000007000707070707000000000000000000000000000000070000000700000007000700070707000000000000000000000000000000000
70700000777077700700007077707770777000000000000000000000000000007770000077700700007000700070777000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000400000000000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000202000003000000000004000202000000000000000004040000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000202000004000000000000000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000202000000040000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000040000000000000000000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000400000000000000000202000000000002020202000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000400000000000000000000000002020202000000040002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304000000000000000000000000000000000000000002020202000400000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000400000000000202000000000002020202000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000400000000000000000000000202000404040000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300020200000000000000000202000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200020200000000040000000202000202000000000004040000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200000000000000000000000000000202000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020302020202030202020202020202020200000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002020202020200000000020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000404000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000040400000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000004000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000004040000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000040000000000000004000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000040000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c55012540075100050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100003073020750217201171000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000400002a3602e350313300030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
