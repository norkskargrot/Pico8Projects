pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
p={x=0,y=0,r=0}
xfov=32
wheight=100

v={
	{x=10,y=10,col=3},
	{x=10,y=-10,col=11},
	{x=-10,y=-10,col=9},
	{x=-10,y=10,col=15}
}

w={
	{1,2,4},
	{2,3,8},
	{3,4,14},
	{4,1,12}
}

function _init()
end

function _update()
	if btn(0) then
		p.x-=sin(p.r-0.25)
		p.y+=cos(p.r-0.25)
	end
	if btn(1) then
		p.x+=sin(p.r-0.25)
		p.y-=cos(p.r-0.25)
	end
	if btn(2) then
		p.x+=sin(p.r)
		p.y-=cos(p.r)
	end
	if btn(3) then
		p.x-=sin(p.r)
		p.y+=cos(p.r)
	end
	if btn(4) then
		p.r+=0.01
	end
	if btn(5) then
		p.r-=0.01
	end
end

function _draw()
	cls()
	local newverts=transformverts(p,v)
	drawortho(p,w,v,false,0,0)	
	drawortho(p,w,newverts,true,30,0)
	draw3d(w,newverts)
end

function draw3d(walls,verts)
	camera(-64,-64)
	for k,w in pairs(walls) do
		v1=verts[w[1]]
		v2=verts[w[2]]
		if v1.y>0 and v2.y>0 then
			drawwall(v1,v2,w[3])
		elseif v1.y<0 and v2.y>0 then
			v1.y=0.01
			v1.x=intersect(v1.x,v1.y,v2.x,v2.y)
			drawwall(v1,v2,w[3])
		elseif v2.y<0 and v1.y>0then
			v2.y=0.01 
			v2.x=intersect(v2.x,v2.y,v1.x,v1.y)
			drawwall(v1,v2,w[3])
		end
	end
	camera(0,0)
end

function drawwall(v1,v2,col)
	local v1x=v1.x*xfov/v1.y
	local v1y1=-wheight/v1.y
	local v1y2=wheight/v1.y
	local v2x=v2.x*xfov/v2.y
	local v2y1=-wheight/v2.y
	local v2y2=wheight/v2.y
	//vetical
	line(v1x,v1y1,v1x,v1y2,v1.col)
	line(v2x,v2y1,v2x,v2y2,v2.col)
	//horizontal
	line(v1x,v1y1,v2x,v2y1,col)
	line(v1x,v1y2,v2x,v2y2,col)
end

function transformverts(p,verts)
	newverts={}
	for k,v in pairs(verts) do
		local newvert={x=0,y=0}
		shiftx=v.x-p.x
		shifty=v.y-p.y
		newvert.x=shiftx*cos(p.r)+shifty*sin(p.r)
		newvert.y=shiftx*sin(p.r)-shifty*cos(p.r)
		newvert.col=v.col
		newverts[k]=newvert
	end
	return newverts
end

function drawortho(p,walls,verts,playerstill,x,y)
	rectfill(x,y,x+30,y+30,1)
	rect(x,y,x+30,y+30,7)
	camera(-x-15,-y-15)
	--player
	local llngth=5
	if playerstill then
		line(0,0,0,llngth,7)
		pset(0,0,15)
	else
		local lendx=p.x+sin(-p.r)*llngth
		local lendy=p.y+cos(-p.r)*llngth
		line(p.x,p.y,lendx,lendy,7)
		pset(p.x,p.y,15)
	end
	--walls
	for k,w in pairs(walls) do
		line(verts[w[1]].x,verts[w[1]].y,verts[w[2]].x,verts[w[2]].y,w[3])
	end
	
	--verts
	for k,v in pairs(verts) do
		pset(v.x,v.y,v.col)
	end
	camera(0,0)
end
-->8
--utility
function xprod(v1x,v1y,v2x,v2y)
	return v1x*v2y+v1y*v2x
end

function intersectv1(x1,y1,x2,y2,x3,y3,x4,y4)
	local x=xprod(x1,y1,x2,y2)
	local y=xprod(x3,y3,x4,y4)
	local det=xprod(x1-x2,y1-y2,x3-x4,y3-y4)
	print(det,0,0,7)
	x=xprod(x,x1-x2,y,x3-x4)--/det
	y=xprod(x,y1-y2,y,y3-y4)--/det
	return x,y
end

function intersect(x1,y1,x2,y2)
	local m=(y2-y1)/(x2-x1)
	local b=y1-m*x1
	return (0.01-b)/m
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
