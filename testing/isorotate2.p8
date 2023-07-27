pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
p={x=16,y=16,r=0.1,h=4}
col={
	{11,3,1,0},
	{6,13,5,1},
}

function _update()
	local sinr,cosr=sin(p.r),cos(p.r)
	local spd=0.3
	--if (btn(0)) p.x,p.y=p.x-cosr*spd,p.y-sinr*spd
	---if (btn(1)) p.x,p.y=p.x+cosr*spd,p.y+sinr*spd
	--if (btn(2)) p.x,p.y=p.x+sinr*spd,p.y-cosr*spd
	--if (btn(3)) p.x,p.y=p.x-sinr*spd,p.y+cosr*spd
	if (btn(0)) p.r=(p.r-0.003)%1
	if (btn(1)) p.r=(p.r+0.003)%1
	
	--tilting controls
	--if (btn(2)) p.h+=0.1
	--if (btn(3)) p.h-=0.1
end

function _draw()
	cls()
	
	--precompute
	local sinr,cosr=sin(p.r),cos(p.r)
	
	--camera
	local cx=p.x%1*cosr+p.y%1*sinr
	local cy=p.y%1*cosr-p.x%1*sinr
	camera(cx*8,cy*4)
	
	--size of map section to draw
	local s=20
	
	--set up sprites
	local spri=48+flr(((p.r-0.125)*16)%4)
	local cpyaddr=512+flr(p.r*16)
	for i=0,16 do
		local voff=i*64
		poke4(512+20+voff,peek4(cpyaddr+voff))
	end
	
	--work out draw order
	local fi,fj=1,1
	local qr=(p.r+0.25)%1
	if (qr>0.5) fi=-1
	if (qr<0.25 or qr>0.75) fj=-1
	
	--draw tiles
	for i=-s*fi,s*fi,fi do
		for j=-s*fj,s*fj,fj do
			local x=8*(i*sinr+j*cosr)
			local y=p.h*(i*cosr-j*sinr)
			local m=mget(j+p.x,i+p.y)
			local h=fget(m)*8-p.h
		 local shade=flr(max(1,min(17,6-y*0.2-h/6)))
			fillp(shades[shade]|0b.01)
			spr(21,64+x,64+y-h+4,1,2)
			pal(3,0)
			pal(11,0)
			spr(spri,64+x,64+y-h-1)
			line(63+x,68+y-h,63+x,68+y-h+16,0)
			line(72+x,68+y-h,72+x,68+y-h+16,0)
			--spr(spri,64+x-1,64+y-h)
			--spr(spri,64+x+1,64+y-h)
			pal()
			spr(spri,64+x,64+y-h)
		end
	end
	camera()
	--rectfill(0,0,24,13,7)
	--print(p.r*4,1,1,0)
	--print(1,7,r,0)
end
-->8
shades={
 0b0000000000000000,
 0b1000000000000000,
 0b1000000000100000,
 0b1010000000100000,
 0b1010000010100000,
 0b1010010010100000,
 0b1010010010100001,
 0b1010010110100001,
 0b1010010110100101,
 0b1110010110100101,
 0b1110010110110101,
 0b1111010110110101,
 0b1111010111110101,
 0b1111110111110101,
 0b1111110111110111,
 0b1111111111110111,
 0b1111111111111111
}
__gfx__
00000000333113333333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000311111133111111333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700311111133111111333111133333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111113111111333111133333113333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111113111111333111133333113333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700311111133111111333111133333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000311111133111111333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333113333333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555ddddddddd55555d51111111555555d550055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555d5d5dd5ddd5555555551111111155d555550500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555ddddddddd5d5555551111111155555d55000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
55d5555ddddddddd55555d55111111115d5555555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555dd5ddd5d5d55555115111111555555555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
55555d555ddddddd555555551111111555555d555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
5d555555ddddddd5d55555d111111111155555550500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555d5dddd5ddd5555555551111111555555d50055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
55d55555dddd5dd555d5555111111115155d55550055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555d5dddddddd555555d11111111555555550500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555ddddddd555555555511111155d5555d55000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
5d55555dddd5ddddd555555511111111555555555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555dddddddd55d5555551111111555d555d5000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
555555d5dddddddd555555d511111115155555555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
555d555d5dddddd5d5555551511111115d555d550500005000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555ddddd5ddd555d5555111115115d5555550055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000000003000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
033b33300333b333b3333b33333b3330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333333333333333333b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b33333bb333333b333333b3b3333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0333b330333b333033b333330333b333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033000003000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000
__gff__
0000010203042020212121030300000000000000000000000000000000000000000000000000000000000000000000000303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010201010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101020101010101010101010101010101010102010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101040401010101010102010101010101010202010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010102020202010101010102020101010102020202020101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102020202020202020102020101010201020202010101020201010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102020202020201010202010101010202020202020202020201020101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020202030203020203020202010101010102020302010202020201020101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010203030304040303030204020101010102030302010203030302010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010201020203020304050404030302020202020202030303020203040402010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010202010203030405050504030302020202020203030302020303030301010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010303030202030405050404030303020202020303040302020202020202010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020102030304040303020203030303030404040301020201020202010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101030202030303030203020301030304040505040301020102020201010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020202020303030302030202030304040404030202020202020202010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020202010202020202020203030203030303020202020202010102010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010102020303040403030302030203020202020101020101010102010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010202020303040403030202020202020101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010202020303040403030202020202010101010101020202010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010202010202030303020201010101010101010202030202010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101020102020302020101010102020202030303020101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101020202020202010202020201010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
