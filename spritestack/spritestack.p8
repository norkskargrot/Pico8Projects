pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--global

typs={
--car
	{row=0,ssize=1,csize=4,
		tox=2,toy=6},
--bike
	{row=2,ssize=1,csize=2,
		tox=0,toy=5},
--bus
	{row=4,ssize=2,csize=6,
		tox=2,toy=7},
}

camr=0
framecount=0
physobjs={}
enms={}
dust={}
envobjs={}

function _init()
	p=initvehicle()
	p.x,p.y=0,0
	
	for i=0,3 do
		add(enms,initvehicle())
	end
	
	for i=0,10 do
		add(envobjs,{x=rnd(256),y=rnd(256)})
	end
end

function _update60()
	framecount+=1
	
	updateplayer()
	camr=camr+(p.r-camr)*0.03

	for k,v in pairs(enms) do
		updateenm(v)
	end
	
	for k,v in pairs(dust) do
		v.x+=v.dx
		v.y+=v.dy
		v.dx*=0.97
		v.dy*=0.97
		v.s+=v.ds
		v.t-=1
		if (v.t<=0) del(dust,v)
	end
end

function _draw()
	cls(9)
	
	local camx=p.x-64.5+16*cos(camr)
	local camy=p.y-64.5-16*sin(camr)
	camera(camx,camy)
	
	drawterrain(camx,camy)
	
	drawtracks(p)
	for k,v in pairs(enms) do
		drawtracks(v)
	end
	
	for k,v in pairs(envobjs) do
		local x=camx+(v.x-camx)%256-64
		local y=camy+(v.y-camy)%256-64
		spr(15,x,y)
	end
	
	for k,v in pairs(enms) do
		local onscx,onscy=-camx+v.x,-camy+v.y
		if onscx+v.csize<0 or
					onscx-v.csize>127 or
					onscy+v.csize<0 or
					onscy-v.csize>127 then
			local clmpx=min(max(onscx,0),127)
			local clmpy=min(max(onscy,0),127)
			camera()
			circfill(clmpx,clmpy,1,7)
			camera(camx,camy)
		else
			drawcar(v)
		end
	end
	
	drawcar(p)
	
	for k,v in pairs(dust) do
		fillp(shades[16-flr(v.t*15/100)]|0b.1)
		circfill(v.x,v.y,v.s,7)
	end
	
	camera()
	--print(stat(1),1,1,0)
end


-->8
--drawing
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

function drawcar(v)
	local x,y,r=v.x,v.y,v.r
	local typ=typs[v.typ]
	local row,s=typ.row,typ.ssize
	local mdy=s+1
	
	for i=0,4 do 
		rspr(x,y-i,r,i*mdy,row-(s-1)/2,s)
	end
	--collider
	--circ(v.x,v.y,v.csize,12)
end

function drawtracks(v)
	for k,a in pairs(v.tracks) do
		local t=a.track
		for i=1,#t-1 do
			fillp(shades[ceil((#t-i)*16/50)]|0b.1)
			local p1,p2=t[i],t[i+1]
			line(p1.x,p1.y,p2.x,p2.y,9)
		end
	end
end

--tline sprite roattion
function rspr(x,y,sw_rot,mx,my,r)    
 local cs, ss = cos(sw_rot), -sin(sw_rot)    
 local ssx, ssy, cx, cy = mx - 0.3, my - 0.3, mx+r/2, my+r/2

 ssy -=cy
 ssx -=cx

 local delta_px = -ssx*8

 --this just draw a bounding box to show the exact draw area
 --rect(x-delta_px,y-delta_px,x+delta_px,y+delta_px,5)

 local sx, sy =  cs * ssx + cx, -ss * ssx + cy

 for py = y-delta_px, y+delta_px do
     tline(x-delta_px, py, x+delta_px, py, sx + ss * ssy, sy + cs * ssy, cs/8, -ss/8)
     ssy+=1/8
 end
end

function drawterrain(camx,camy)
	local midx,midy=camx|0xfff0,camy|0xfff0
	for i=midx,midx+128,16 do
		for j=midy,midy+128,16 do
			local wx,wy=i+camx|0xf,j+camy|0xf
			local val=
				9*sin(wx/800)+
				7*cos(wy/1200)+
				9*sin((wx+2*wy)/1000)
			val=abs(val)/25
			--val=((val/25)+1)/2
			local r=12+val*8
			fillp(shades[14-flr(val*12)]|0b.1)
			circfill(i+camx|0xf,j+camy|0xf,r,15)
		end
	end
end

-->8
--physics

function initvehicle()
	local n={}
	n.x,n.y=rnd(128),rnd(128)
	n.dx,n.dy=0,0
	n.spd,n.r=0,0
	n.typ=ceil(rnd(3))
	n.csize=typs[n.typ].csize
	n.trn=rnd(0.005)+0.005
	n.tracks={}
	local tox,toy=typs[n.typ].tox,typs[n.typ].toy
	add(n.tracks,{ox=tox,oy=toy,track={{x=n.x,y=n.y}}})
	--add(n.tracks,{ox=tox,oy=-toy,track={{x=n.x,y=n.y}}})
	if n.typ!=2 then
		add(n.tracks,{ox=-tox,oy=toy,track={{x=n.x,y=n.y}}})
		--add(n.tracks,{ox=-tox,oy=-toy,track={{x=n.x,y=n.y}}})
	end
	add(physobjs,n)
	return n
end

function updatevehicle(v)
	v.dx+=v.acc*cos(v.r)
	v.dy-=v.acc*sin(v.r)
	
	local oldx,oldy=v.x,v.y
	
	v.x+=v.dx
	v.y+=v.dy
	v.dx*=0.95
	v.dy*=0.95
	
	local hit=false
	for k,a in pairs(physobjs) do
		if a!=v then
			local d=dist(a,v)
			if d<(v.csize+a.csize) then
				circlecollide(a,v)
				hit=true
			end
		end
	end
	
	if (hit) v.x,v.y=oldx+v.dx,oldy+v.dy
	
	updatetrack(v)
	
	if abs(v.dr)>0.008 and
				magnit(v.dx,v.dy)>0.5 and
				framecount%2==0 then
		local sr,cr=sin(v.r),cos(v.r)
		local x,y=v.x,v.y
		for k,a in pairs(v.tracks) do
			local t=a.track
			local nx=x+a.ox*sr-a.oy*cr
			local ny=y+a.ox*cr+a.oy*sr
			add(dust,{
			x=nx,
			y=ny,
			dx=v.dx,dy=v.dy,
			t=100,
			s=0,
			ds=rnd(0.1)})
		end
	end
end

function circlecollide(a,b)
	local tangy=-(b.x-a.x)
	local tangx=b.y-a.y
	local tanglength=sqrt(tangy*tangy+tangx*tangx)
	tangx/=tanglength
	tangy/=tanglength
	
	local relvx=a.dx-b.dx
	local relvy=a.dy-b.dy
	
	local l=relvx*tangx+relvy*tangy
	local relvparallelx=tangx*l
	local relvparallely=tangy*l
	local relvperpx=relvx-relvparallelx
	local relvperpy=relvy-relvparallely
	
	a.dx-=relvperpx
	a.dy-=relvperpy
	b.dx+=relvperpx
	b.dy+=relvperpy
end

function updatetrack(v)
	local x,y,r=v.x,v.y,v.r
	local sr,cr=sin(r),cos(r)
	for k,a in pairs(v.tracks) do
		local t=a.track
		local nx=x+a.ox*sr-a.oy*cr
		local ny=y+a.ox*cr+a.oy*sr
		if framecount%10==0 then
			add(t,{x=nx,y=y+a.oy*sr})
			if (#t>50) del(t,t[1])
		else
			t[#t].x=nx
			t[#t].y=ny
		end
	end
end
-->8
--player
function updateplayer()
	p.dr=0
	if (btn(0)) p.dr-=0.01
	if (btn(1)) p.dr+=0.01
	p.r+=p.dr
	
	p.acc=0
	if (btn(2)) p.acc=0.08
	if (btn(3)) p.acc=-0.05
	
	updatevehicle(p)
end

-->8
--enemies

function updateenm(v)
	local gdir=-atan2(p.x-v.x,p.y-v.y)	
	gdir=(gdir-v.r+0.5)%1-0.5
	v.dr=gdir
	v.r+=sgn(gdir)*v.trn
	
	v.acc=0.07
	updatevehicle(v)
end
-->8
--misc
function dist(a,b)
 return magnit(a.x-b.x,a.y-b.y)
end

function magnit(a,b)
	local a0,b0=abs(a),abs(b)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566660
00700700550000555502205582222288082cc2800088880000000000000000000000000000000000000000000000000000000000000000000000000005666666
0007700000000000222222228800008808800cc00088880000000000000000000000000000000000000000000000000000000000000000000000000005556655
0007700000000000222222228800008808800cc00088880000000000000000000000000000000000000000000000000000000000000000000000000005555555
0070070000000000222222228800008808800cc00088880000000000000000000000000000000000000000000000000000000000000000000000000004445555
00000000550000555502205582222288082cc2800088880000000000000000000000000000000000000000000000000000000000000000000000000000444400
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004400000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000060000000df000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000550055005522550026d2200000d20000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000060000000df000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
055000000000055005599999999195500999999999919aa009919191919190000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000
000000000000000009999999999999900900000000001aa001000000000010000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000
000000000000000009999999999999900900000000001aa001000000000010000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000
000000000000000009999999999999900900000000001aa001000000000010000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000
055000000000055005599999999995500999999999999aa009919191919190000aaaaaaaaaaaa000000000000000000000000000000000000000000000000000
__map__
0100020003000400050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1100120013001400150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021002223002425002627002829000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
