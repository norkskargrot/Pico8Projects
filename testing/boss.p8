pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
clipdist=2
hscale=40
vscale=500

function _init()
	p={}
	p.x,p.y=32,32
	p.dx,p.dy=0,0
	p.rot=0
	p.col=7
	
	b={}
	b.x,b.y=64+40,64+40
	b.col=8
	
	camera(-64,-64)
end

function _update()
	if (btn(0)) p.dx+=0.001
	if (btn(1)) p.dx-=0.001
	if (btn(2)) p.dy-=0.5
	if (btn(3)) p.dy+=0.5
	
	local dirx=(b.x-p.x)
	local diry=(b.y-p.y)
	local r=sqrt(dirx*dirx+diry*diry)
	local sang=atan2(diry,dirx)
	local eang=sang+(180*p.dx)/(3.14*r)
	local newr=max(5,r+p.dy)
	p.x=b.x-sin(eang)*newr
	p.y=b.y-cos(eang)*newr
	p.rot=eang+0.5
	
	p.dx*=0.8
	p.dy*=0.8
	
	--b.x=sin(time()/10)*20+64
	--b.y=cos(time()/10)*20+64
end

function _draw()
	cls()
	drawbuilding()
	drawboss()
end

function drawboss()
	local newp=trnsfmpoint(b.x,b.y)
	
	local x=hscale*newp.x/newp.y
	local y=vscale/newp.y
	sspr(8,0,8,8,-y,-y,2*y,2*y)
end
-->8
--buildings
brad=40

verts={
	{x=64-brad,y=64-brad},
	{x=64-brad,y=64+brad},
	{x=64+brad,y=64+brad},
	{x=64+brad,y=64-brad}
}

walls={
	{2,1},
	{3,2},
	{4,3},
	{1,4},
}

building={}

function drawbuilding()
	drawortho()
end

function drawortho()
	local newverts={}
	for k,v in pairs(verts) do
		newverts[k]=trnsfmpoint(v.x,v.y)
	end
		
	for k,v in pairs(walls) do
		local p1=newverts[v[1]]
		local p2=newverts[v[2]]
		if p1.y<clipdist and p2.y<clipdist then
		
		elseif p1.y<clipdist then
			drawwall(getclipped(p1,p2),p2)
		elseif p2.y<clipdist then
			drawwall(p1,getclipped(p2,p1))
		else
			drawwall(p1,p2)
		end
	end
end

function drawwall(p1,p2)
	local x1=hscale*p1.x/p1.y
	local x2=hscale*p2.x/p2.y
	local y1=vscale/p1.y
	local y2=vscale/p2.y
	
	for i=x1,x2 do
		local p=(i-x1)/(x2-x1)
		local y=lerp(p,y1,y2)
		local sprsheetx=16+(8/p)%8
		sspr(sprsheetx,0,1,8,i,-y,1,2*y)
	end
end

function getclipped(p1,p2)
	local dx=p2.x-p1.x
	local dy=p2.y-p1.y
	local newv={}
	newv.x=p1.x+dx*(clipdist-p1.y)/dy
	newv.y=clipdist
	return newv
end
	
function lerp(v,l,h)
	return v*(h-l)+l
end

function trnsfmpoint(vx,vy)
	local newvert={}
	local shiftx=vx-p.x
	local shifty=vy-p.y
	local sinr=sin(-p.rot)
	local cosr=cos(-p.rot)
	newvert.x=shiftx*cosr+shifty*sinr
	newvert.y=shiftx*sinr-shifty*cosr
	return newvert
end
__gfx__
00000000000770006555655500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770006555655500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077007706666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000700770075565556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770005565556500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000770006666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007006555655500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007006555655500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
