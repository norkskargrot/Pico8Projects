pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
x=0
y=0
dx=2
dy=1
a=0
cls()
::☉::
a+=1
for i=0,2 do
	local m=a*0.3
	pal(8+(i+m)%3,i+8)
	pal(i+8,8+(i+m)%3,1)
end
if a%2==0 then
	memcpy(24576,24640,8127)
end
for i=0,2000 do
	pset(rnd(128),rnd(128),0)
end
if x>127 or x<0 then dx=-dx+rnd(0.4)-0.2 end
if y>127 or y<0 then dy=-dy+rnd(0.4)-0.2 end
x+=dx
y+=dy
circfill(x,y,8,10)
flip()
goto ☉
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
