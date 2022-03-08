pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
px=8
py=8
dx=0
dy=0
acc=0.2
maxspd=2
drag=0.9

function _init()

end
-->8
--update
function _update60()
	if btn(0) then dx-=acc end
	if btn(1) then dx+=acc end
	if btn(2) then dy-=acc end
	if btn(3) then dy+=acc end
	
	dx*=drag
	dy*=drag
	dx=min(max(dx,-maxspd),maxspd)
	dy=min(max(dy,-maxspd),maxspd)
	
	if solidarea(px+dx,py,7,7) then
		dx=-dx
		playsound(abs(dx))
	else
		px+=dx
	end
	if solidarea(px,py+dy,7,7) then
		dy=-dy
		playsound(abs(dy))
	else
		py+=dy
	end
end

function playsound(spd)
		if spd>0.5 then
			sfx(0)
		end
end

function solidarea(x,y,w,h)
	return 
		solid(x,y) or
		solid(x+w,y) or
		solid(x,y+h) or
		solid(x+w,y+h)
end

function solid(x,y)
	local tile=mget(x/8,y/8)
	return fget(tile,0)
end
-->8
--draw
function _draw()
	cls()
	map(0,0,0,0,16,16)
	fillp(0xffff|0b.011)
	map(0,0,0,0,16,16,1)
	fillp(0x0000.0000)
	spr(1,px,py)
	pset(posx,posy,8)
	map(0,0,0,-4,16,16,1)
end
__gfx__
00000000077777700445554005455045999994990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000776666774555445545554455999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766666675554555455545555999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766666675454555454555554999a99990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766666675554555555545555949999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766666674555555545554455999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077666677554555545545555499999a990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700440554055545550999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020302020303030302030302030200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040404040404040404040304040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304040404040404040404040204040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0302040404040404020404040204040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202040204040404030404040404040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0302020204040302030404040404040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040404040404020404040404040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040204040404020404040404040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304040304040404030404040404040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304040304040404020202020304030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304020204040404030404040404040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040404040404030404040404040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040404040403020404020202040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0204040203020404040404030404040200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304040404040404040404020404040300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020303030302020303030203020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000857008500085000000012300157001570014700155002450015700157001570015700167001670016700167001670016700167001670016700167001670016700167001650016500000000000000000
001000003905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
