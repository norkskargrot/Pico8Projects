pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--[[
credit to @zeg_ on twitter
https://twitter.com/zeg___/status/1445450299825557504?s=20
]]--
local fcount=0
mapsizex,mapsizey=64,32
fireh=128
switches={}

for i=0,mapsizex do
	for j=0,mapsizey do
		local m=mget(i,j)
		if m==21 then
		 add(switches,{dir=1,x=i*8,y=j*8})
		 mset(i,j,0)
		end
	end
end

function _update60()
	cls(8)
	fcount+=1
	pupd(p)
	updbtns()
end

function _draw()
	movebelts()
	
	local camx=min(max(p.x-64,0),mapsizex*8-128)
	local camy=min(max(p.y-64,0),mapsizey*8-128)
	
	camera(camx,camy)
	--drawfire(camx,camy)
	map(0,0,0,0,mapsizex,mapsizey)
	drawplayer(p)
	drawdust()
	drawswitches()
	--drawwater(2,camx)
	camera()
	
	if btn(5) then
		local y0,y1=0,mapsizey
		rectfill(0,64,127,127,1)
		for i=0,64 do
			tline(0,i+64,127,i+64,0,i/2,0.5,0)
		end
		pset(p.x/4,p.y/4+64,7)
		pset(p.x/4,p.y/4+65,7)
	end
	
	--print(stat(7),1,1,7)
	--print(stat(1),1,8,7)
end

function shrinkscreen(camx,camy,d)
	poke(0x5f54,0x60)
	camera()
	local v=128-2*d
	sspr(0,0,128,128,d,d,v,v)
	poke(0x5f54,0x00)
	camera(camx,camy)
end
-->8
--physics

function solidarea(x,y,w,h,oneway)
	if (oneway==nil) oneway=false
	return issolid(x,y,oneway) or
	       issolid(x+w,y,oneway) or
	       issolid(x,y+h,oneway) or
	       issolid(x+w,y+h,oneway)
end

function issolid(x,y,oneway)
	if (oneway==nil) oneway=false
	local m=mget(x/8,y/8)
	--check for slopes
	if (fget(m,3)) return (x%8-y%8<1)
	if (fget(m,2)) return (y%8+x%8>7)	

	--check one way platforms
	if (oneway) return fget(m,0) or fget(m,4)
	--check for normal solid
	return fget(m,0)
	--return fget(mget(x/8,y/8),0)
end

function grounded(p)
 return solidarea(p.x,p.y+1,p.w,p.h,p.oneway)
end

function getslope(p)
	local p1=mget((p.x+p.dx)/8,(p.y+p.h)/8)
	local p2=mget((p.x+p.dx+p.w)/8,(p.y+p.h)/8)
	local sl=fget(p1,3)
	local sr=fget(p2,2)
	return sl,sr
end
-->8
--utility
btns={false,false,false,false,false,false}

function updbtns()
	for i=0,5 do
		btns[i+1]=btn(i)
	end
end

function btnd(n)
	return (btn(n)==true and btns[n+1]==false)
end

-->8
--player

--[[
-arrow left and right to move
-up to jump
	-move towards wall in-air to 
	walljump
-z to slide
	-zero friction when sliding, 
	allowing for big speed boosts
--]]
		

p={}
p.dx,p.dy=0,0
p.x,p.y=8,64
p.w,p.h=3,7
p.f=0
p.onewaycoll=true
p.walltime=0
p.cyotetime=0
p.jumpqueue=0

walltime=10
cyotetime=10
jumpqueue=10

function pupd(p)
	--timers
	p.walltime=max(p.walltime-1,0)
	p.cyotetime=max(p.cyotetime-1,0)
	p.jumpqueue=max(p.jumpqueue-1,0)
	
	if (grounded(p)) p.cyotetime=cyotetime
	
	--x-axis acc
	local acc=0.1
	if (not grounded(p)) acc=0.02
	p.inx=0
	if not btn(4) then
		if (btn(0)) p.inx-=acc
		if (btn(1)) p.inx+=acc
	end
	
	--conveyor belts
	local dxmod=0
	local pmap=mget((p.x+p.w/2)/8,(p.y+p.h+1)/8)
	if (pmap==28) dxmod+=0.08
	if (pmap==29) dxmod-=0.08
	if (btn(4)) dxmod/=2
	p.dx+=p.inx+dxmod
	
	--slopes
	local sl,sr=getslope(p)
	if sl then
		if (p.dx<0) p.dx*=0.95
		if (p.dx>=-0.1 and btn(4)) p.dx+=0.05
	end
	if sr then
		if (p.dx>0) p.dx*=0.95
		if (p.dx<=0.1 and btn(4)) p.dx-=0.05
	end
	
	--dust
	if grounded(p) and abs(p.dx)>0.2 then
	 rundust(p.x,p.y+8,-p.inx)
	end
	
	--check one-way platforms
	if not p.oneway and p.dy>0 then
		if not solidarea(p.x,p.y,p.w,p.h,true) then
			p.oneway=true
		end
	end
	if (btn(3)) p.oneway=false
	
	--detect wall sliding
	local checkdist=sgn(p.inx+p.dx)*3
	if  abs(p.dx)>0
	and solidarea(p.x+checkdist,p.y,p.w,p.h,false)
	and not grounded(p) then
		p.dy=min(p.dy+0.15,0.3)
		p.walltime=walltime
		p.walldir=-sgn(p.dx)
	else
		--fastfall
		if btn(3) then
			p.dy+=0.3
		else
			p.dy+=0.15
		end
	end
	
	--jumping
	if btnd(2) then
		p.jumpqueue=jumpqueue
	end
	if p.jumpqueue>0 then
		if grounded(p)
					or p.cyotetime>0 then
		 p.dy=-2.8
		 p.cyotetime=0
		 p.jumpqueue=0
		 jumpdust(p.x,p.y+8)
		 p.oneway=false
		elseif p.walltime>0 then
			p.dy=-1.8
			p.dx=p.walldir*1.5
			p.walltime=0
		 p.jumpqueue=0
		 walljumpdust(p.x+p.w/2,p.y+8,p.walldir)
			p.oneway=false
		end
	end
	
	--x-axis movement+collision		
	--slope handling
	local sl,sr=getslope(p)
	if (sl or sr) then
		p.x+=p.dx
		while solidarea(p.x,p.y,p.w,p.h,p,p.oneway) do
			p.y-=1
		end
	else --non-slope
		for i=p.dx,0,-sgn(p.dx) do
			if solidarea(p.x+i,p.y,p.w,p.h,p.oneway) then
				p.dx=0
			else
				p.x+=i
				break
			end
		end
	end
	
	--y-axis movement+collision
	for i=p.dy,0,-sgn(p.dy) do
		if solidarea(p.x,p.y+i,p.w,p.h,p.oneway) then
			p.dy=0
		else
			p.y+=i
			break
		end
	end
	
	--x-axis slowdown
	if not btn(4) then
		if grounded(p) then
			p.dx*=0.9
		else
			p.dx*=0.98
		end
	end
	
	--switches
	for k,v in pairs(switches) do
		if abs(p.x-p.w-v.x)<8 and abs(p.y-v.y)<8 then
			v.dir=sgn(p.dx)
		end
	end
	
	--animation logic
	if (abs(p.inx)>0) p.dir=p.inx>0
	p.f=(p.f+abs(p.dx)/3)%7
	p.spri=64+p.f
	if (p.inx==0) p.spri=72
	if (abs(p.dx)<0.1) p.spri=64
	if not grounded(p) then
		if btn(3) then
 		p.spri=64
 	else
 		p.spri=67
 	end
	elseif btn(4) then
		p.spri=71
		if (abs(p.dx)>0.2) p.spri=74
	end
	if (p.walltime==walltime) p.spri=73
end

function drawplayer(p)
	local px,py=p.x-2,p.y
		
	pal(7,0)
	spr(p.spri,px+1,py,1,1,p.dir,false)
	spr(p.spri,px-1,py,1,1,p.dir,false)
	spr(p.spri,px,py+1,1,1,p.dir,false)
	spr(p.spri,px,py-1,1,1,p.dir,false)
	pal()
	spr(p.spri,px,py,1,1,p.dir,false)
end
-->8
--effects

function boosteranim()
	memset()
end

--fire
fireparts={}
for i=0,400 do
	add(fireparts,
		{x=rnd(177),
			y=rnd(256),
			rmod=rnd(4)-2,
		})
end

function drawfire(camx,camy)
	local hmod=192-fireh
	--update positions
	for k,v in pairs(fireparts) do
		v.y=(v.y-rnd(0.8))%256
		v.sx=(v.x-camx/2)%177+camx-25
		v.sy=v.y+camy/2+hmod
		v.r=v.y/6+v.rmod
	end
	--orange
	for k,v in pairs(fireparts) do
		if (v.y<128) circfill(v.sx,v.sy,v.r,9)
	end
	--yellow
	for k,v in pairs(fireparts) do
		if (v.y<192) circfill(v.sx,v.sy,v.r-10,10)
	end
	--white
	for k,v in pairs(fireparts) do
		if (v.y<256) circfill(v.sx,v.sy,v.r-20,7)
	end
end

--dust particles
dustparts={}

function drawdust()
	local todel={}
	for k,v in pairs(dustparts) do
		v.x+=v.dx
		v.y+=v.dy
		v.dx*=0.9
		v.dy*=0.9
		v.age-=1
		circfill(v.x,v.y,v.r,7)
		if (v.age<=0) add(todel,v)
	end
	for k,v in pairs(todel) do
		del(dustparts,v)
	end
end

function jumpdust(x,y)
	for i=0,4 do
		add(dustparts,
			{x=x,y=y,
				dx=rnd(2)-1,dy=-rnd(1),
				r=0.5+rnd(1.5),
				age=20+rnd(10)
			}
		)
	end
end

function walljumpdust(x,y,dirx)
	for i=0,4 do
		add(dustparts,
			{x=x,y=y,
				dx=rnd(0.5)*dirx,dy=rnd(2)-1,
				r=0.5+rnd(1.5),
				age=20+rnd(10)
			}
		)
	end
end

function rundust(x,y,dirx)
	if fcount%10==0 then
		add(dustparts,
			{x=x,y=y,
				dx=rnd(1)*dirx,dy=-rnd(0.5),
				r=0.5+rnd(1.5),
				age=20+rnd(10)
			}
		)
	end
end

--[[
function drawwater(h,camx)
	pal(10,1)
	poke(0x5f54,0x60)
	for i=0,127 do
		local x=camx+i
		local y=(32-h)*8
		y+=sin((x+time()*20)/20)
		y+=2*sin((x-time()*20)/80)
		--line(x,y,x,32*8,1)
		sspr(x,y,1,16,x,y)
		pset(x,y,12)
	end
	pal()
	poke(0x5f54,0x00)
end
]]--
-->8
--factory objects

--switches
function drawswitches()
	for k,v in pairs(switches) do
		local sp=21
		if (v.dir==1) sp=22
		spr(sp,v.x,v.y)
	end
end

--belts
function movebelts()
 if (fcount%2!=0) return
	local sp=28
	local ad=512*(sp\16)+4*(sp%16)
	poke4(ad,peek4(ad)<<>4)
	ad=512*(sp\16)+4*(sp%16)+64
	poke4(ad,peek4(ad)<<>4)
	ad=512*(sp\16)+4*(sp%16)+64*7
	poke4(ad,peek4(ad)>><4)
	
	sp=29
	ad=512*(sp\16)+4*(sp%16)
	poke4(ad,peek4(ad)>><4)
	ad=512*(sp\16)+4*(sp%16)+64
	poke4(ad,peek4(ad)>><4)
	ad=512*(sp\16)+4*(sp%16)+64*7
	poke4(ad,peek4(ad)<<>4)
end
__gfx__
00000000ddddaaaa0000000000000000022222200222222000000000666666660222222002222220000000000222222066666666000000006666666666666666
00000000addddaaa2222222222222222222222220222222022222000d111111602222222022222200002222222222220dddddddd00000020d111111111111116
00700700991111992222222222222222222222220222222022222200d1d11d1602222222022ee22000222222222222201000100000000020d1d1111111111d16
00077000999111192222222222222222222222220222222022222220d11111160222222202122e2002222222222222200101010100000022d111111111111116
000770001111111d2222222222222222222222220222222022222220d11111160222222202112e2002222222222222200010001000000022d111111111111116
00700700d1d11d162222222222222222222222220222222022222220d1d11d16002222220221122002222222222222201111111100000020d111111111111116
00000000d11111162222222222222222222222220222222022222220d1111116000222220222222002222222222222200000000000000020d111111111111116
00000000dddddddd0000000002222220000000000222222002222220dddddddd000000000222222002222220022222200000000000000000d111111111111116
d00000000000000d6666699aa9966666022222200000000000000000000000000000000000000000000000000000000066dd66dd66dd66ddd111111111111116
dd000000000000ddd11111999911111d2222222000000000000000000000000000000000000000000000000000000000dd11dd11dd11dd11d111111111111116
9dd0000000000dd9d1d11d1991d11d1d22222220cc000000000000cc00000000000000000000000000000000000000001166611d1166611dd111111111111116
91da00000000ad19d11111166111111d222222201c0000000000001c00000000000000000000000000000000000000001dd1d6111dd1d611d111111111111116
d91da000000ad19dd11111166111111d22222220006000000000060000000000000000000000000000000000000000001d111d111d111d11d111111111111116
d111aa0000aa111dd1d11d1661d11d1d22222200000600000000600000000000000000000000000000000000000000001d61dd111d61dd11d1d1111111111d16
d1111aa00aa1111dd11111166111111d222220000666666006666660000000000000000000000000000000000000000011ddd11d11ddd11dd111111111111116
dddd19aaaa91dddddddddddddddddddd000000000d1111600d1111600000000000000000000000000000000000000000dd11dd11dd11dd11dddddddddddddddd
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
00770000007700000077000000770000007700000077000000770000000000000000000000077000000000000000000000000000000000000000000000000000
00770000007700000077000000770000007700000077000000770000000000000007700000077000000000000000000000000000000000000000000000000000
00077000000770000007770070077770000777000007700000077000000000000007700000007770000000000000000000000000000000000000000000000000
00077700007777007077707007777007707770700077770000777000007700000000777000777707000770000000000000000000000000000000000000000000
00077700070777000707707000077000070770700777770000777000007700000077770700007707000770000000000000000000000000000000000000000000
00077000000770000077700007777700007770000077700000077000000770000000770700777000070077700000000000000000000000000000000000000000
00077000007077000700070070000077070007000070770000077000007777000077700000070000007777070000000000000000000000000000000000000000
00077000000707000700007000000000070000700007070000077000007777700707000000700000770770070000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
8888888888888888888888888888888888888888888888888888888888888888ddddaaaaddddaaaaddddaaaa8888888888888888888888888888888888888888
8888888888888888888888888888888888888888888888888888888888888888addddaaaaddddaaaaddddaaa8888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888889911119999111199991111998888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888889991111999911119999111198888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888889999111199991111999911118888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888881999911119999111199991118888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888881199991111999911119999118888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888881119999111199991111999918888888888888888888888888888888888888888
888888888888888888888888ef888888888888888888888888888888888888fedddddddddddddddddddddddd8888888888888888888888888888888888888888
8888888888888888888fffffeeffffffffffffffffffffffffffffffffffffee1111111d1111111d1111111dfffff88888888888888888888888888888888888
888888888888888888eeeeee22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee221111111d1111111d1111111deeeeef8888888888888888888888888888888888
88888888888888888e22222222222222222222222222222222222222222222221111111d1111111d1111111d2222eef888888888888888888888888888888888
88888888888888888222222222222222222222222222222222222222222222221111111d1111111d1111111d22222ee888888888888888888888888888888888
88888888888888888222222222222222222222222222222222222222222222221111111d1111111d1111111d222222e888888888888888888888888888888888
88888888888888888222222222222222222222222222222222222222222222221111111d1111111d1111111d222222e888888888888888888888888888888888
8888888888888888822222e822888888822222e88888888888888888888888221111111d1111111d1111111d822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e8888888888888888888888888822222e88888888888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e8888888888888888888888888822222effffff88888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e88888888888888888888888888222222eeeeeef8888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e8888888888888888888888888822222222222eef888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e88888888888888888888888888222222222222ee888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e888888888888888888888888888222222222222e888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e888888888888888888888888888822222222222e888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e888888888888888888888888888888888822222e888888888822222e888888888888888888888888888888888
8888888888888888822222e888888888822222e888888888888888888888888888888888822222e888888888822222e888888888ddddaaaaddddaaaaddddaaaa
88888888888fffffe22222e8888888f8e22222e888888888888888888888888888888888822222e888888888822222e888888888addddaaaaddddaaaaddddaaa
8888888888eeeeee222222e8888888e8222222e888888888888888888888888888888888822222e888888888822222e888888888991111999911119999111199
888888888e222222222222e88888882e222222e888888888888888888888888888888888822222e888888888822222e888888888999111199991111999911119
8888888882222222222222e888888822222222e888888888888888888888888888888888822222e888888888822222e888888888999911119999111199991111
8888888882222222222222e888888828222222e888888888888888888888888888888888822222e888888888822222e888888888199991111999911119999111
8888888882222222222222e888888828222222e888888888888888888888888888888888822222e888888888822222e888888888119999111199991111999911
88888888822222e8822222e888888888822222e888888888888888888888888888888888822222e888888888822222e888888888111999911119999111199991
88888888822222e8822222e888888888822222e888888778888888888888888888888888822222e888888888822222e888888888dddddddddddddddddddddddd
88888888822222e8822222effffff888822222e888888778888888888888888888888888822222e888888888822222e8888fffff1111111d1111111d1111111d
88888888822222e88222222eeeeeef88822222e888777788788888888888888888888888822222e888888888822222e888eeeeee1111111d1111111d1111111d
88888888822222e8822222222222eef8822222e887887777888888888888888888888888822222e888888888822222e88e2222221111111d1111111d1111111d
88888888822222e88222222222222ee8822222e888887788888888888888888888888888822222e888888888822222e8822222221111111d1111111d1111111d
88888888822222e888222222222222e8822222e888877777888888888888888888888888822222e888888888822222e8822222221111111d1111111d1111111d
88888888822222e888822222222222e8822222e887788888788888888888888888888888822222e888888888822222e8822222221111111d1111111d1111111d
88888888822222e888888888822222e8822222e888888888888888888888888888888888822222e888888888822222e8822222e81111111d1111111d1111111d
ddddaaaaddddaaaaddddaaaaddddaaaaddddaaaaddddaaaaddddaaaa8888888888888888822222e888888888822222e8822222e8dddddddddddddddddddddddd
addddaaaaddddaaaaddddaaaaddddaaaaddddaaaaddddaaaaddddaaa88888888888888f8e22222e888888888822222e8822222e81111111d1111111d1111111d
9911119999111199991111999911119999111199991111999911119988888888888888e8222222e888888888822222e8822222e81111111d1111111d1111111d
99911119999111199991111999911119999111199991111999911119888888888888882e222222e888888888822222e8822222e81111111d1111111d1111111d
999911119999111199991111999911119999111199991111999911118888888888888822222222e888888888822222e8822222e81111111d1111111d1111111d
199991111999911119999111199991111999911119999111199991118888888888888828222222e888888888822222e8822222e81111111d1111111d1111111d
119999111199991111999911119999111199991111999911119999118888888888888828222222e888888888822222e8822222e81111111d1111111d1111111d
111999911119999111199991111999911119999111199991111999918888888888888888822222e888888888822222e8822222e81111111d1111111d1111111d
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd88888888ddddaaaaddddaaaaddddaaaaddddaaaa822222e8dddddddddddddddddddddddd
1111111d1111111d1111111d1111111d1111111d1111111d1111111d88888888addddaaaaddddaaaaddddaaaaddddaaa822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888899111199991111999911119999111199822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888899911119999111199991111999911119822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888899991111999911119999111199991111822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888819999111199991111999911119999111822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888811999911119999111199991111999911822222e81111111d1111111d1111111d
1111111d1111111d1111111d1111111d1111111d1111111d1111111d8888888811199991111999911119999111199991822222e81111111d1111111d1111111d
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
000300000000000300000000100003030b070b07000000000000000003030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c071c1c1c1c1c070707070700000000000000000000070707000000000000000000000707070000000000000000000007070707071d1d1d1d1d070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070000000000000000000000000000000007070707070707070707070707070707070707070707070700000000000000000000000000000000070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070000000000000000000000000000000007000000000000000000000000000000000000000000000700000000000000000000000000000000070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000700000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070000000000000000000000000000000007000000000000000000000000000000000000000000000700000000000000000000000000000000070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000000000000070000000000000000000000000000000000000000000007000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c07070c0c0c0710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011070c0c0c07070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070000070700000007070c0c071000000000000000000000000000000000000000000000000000000000000000000000000011070c0c0707000000070700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000007070000000707000007071000000000000707070707070c0c0c0700000000070c0c0c070707070707000000000011070700000707000000070700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070700000007070000070707100000000007070707070700000007000000000700000007070707070700000000110707070000070700000007070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000707000000070707070707070710000000070707070707000000070000000007000000070707070707000000110707070707070707000000070700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000707000000070707070707070707000000000000000000000000070000000007000000000000000000000000070707070707070707000000070700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c0c070700000000000000000000000000000000000000000000000007070707070700000000000000000000000000000000000000000000000007070c0c0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000111c1c1c1c070000000000000000000000000000071d1d1d1d100000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070707070710000000000000000000000000000707070707070c0c0c0c0c0c0c0c0c0c0c0c0c0c0707070707070000000000000000000000000011070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001107070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070707070707071c1c1c1c1c1c07070707071d1d1d1d1d1d070710000000000000000000001107071c1c1c1c1c1c07070707071d1d1d1d1d1d0707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
