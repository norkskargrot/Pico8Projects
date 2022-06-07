pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--main

function _init()
	cls()
	--srand(0)
	memset(0x8000,0,0x7fff)
	gennoise()
	gennormals()
	drawmap()
end

function _update()
	if (btn(0)) p.r-=rotspeed
	if (btn(1)) p.r+=rotspeed
	p.r=p.r%1
	
	if (btn(2)) then
	 p.x-=sin(p.r)*movspeed
	 p.y-=cos(p.r)*movspeed
	end
	if (btn(3)) then
	 p.x+=sin(p.r)*movspeed
	 p.y+=cos(p.r)*movspeed
	end
	p.z=getmapdata(p.x,p.y)+10
end

function _draw()
	cls(12)
	drawterrain()
	drawminimap()
	--drawmap()
	print("pos="..p.x..","..p.y..","..p.z,1,1,7)
	print("cpu="..stat(1),1,7,7)
end
-->8
--map
--[[
each map location is two bytes

00000000 00000000
	`-'`--'	  `----'
		|		|				    |
		| normal  height
		|							 
terraintype

]]--

function getheight(x,y)
end

function getmapdata(x,y)
	x,y=(x%128)&0xffff,(y%128)&0xffff
	local v=peek2(0x8000+x*2+y*256)
	local	h,n
	h=(v&0b0000000000111111)
	n=(v&0b0000111100000000)>>8
	return h,n
end

function noiseset(x,y,v)
	v=min(max(v,0),64)
	v=v&0b00111111
	poke(0x8000+x*2+y*256,v)
end

function noiseget(x,y)
	local v=peek(0x8000+x*2+y*256)
	return v&0b00111111
end

function normalset(x,y,v)
	v=min(max(v,0),64)
	v=v&0b00001111
	poke(0x8000+x*2+1+y*256,v)
end

function normalget(x,y)
	local v=peek(0x8000+x*2+1+y*256)
	return v&0b00001111
end

function gennormals()
	local norms={}
	local maxi=0
	for i=0,127 do
		norms[i]={}
		for j=0,127 do
			local h1=noiseget(i,j)
			local h2=noiseget((i+1)%128,j)
			v=min(max(h2-h1+8,0),15)
			normalset(i,j,v)
			maxi=max(abs(h2-h1),v)
		end
	end
	printh("max="..maxi)
end

function gennoise()
	--init array to random values
	local arr={}
	for i=0,127 do
		arr[i]={}
		for j=0,127 do
			arr[i][j]=rnd(64)-32
		end
	end
	
	--smooth 40 times, store detail
	--from in progress smoothing
	--smoothing also normalises
	local detail={}
	for i=0,10 do
		arr=smooth(arr)
		arr=normalisearr(arr,64)
		if (i==5) detail=arr
		printh(i.." "..stat(0))
	end
	
	--combine the main and detail 
	--arrays and set the map
	for i=0,127 do
		for j=0,127 do
			local v=arr[i][j]
			v+=detail[j][i]/3
			v=min(max(v+32,0.001),63.999)
			noiseset(i,j,v)
			pset(i,j,v/4)
		end
	end
end

function smooth(arr)
	local new={}
	for i=0,127 do
		new[i]={}
		for j=0,127 do
	 	--sample 8 surrounding pixels
			local v=arr[i][j]
			v+=arr[(i-1)%128][j]
			v+=arr[(i+1)%128][j]
			v+=arr[i][(j-1)%128]
			v+=arr[i][(j+1)%128]
			v/=5
			new[i][j]=v
			pset(i,j,(v+32)/4)
		end
	end

	return new
end
-->8
--utility
function normalisearr(arr,rng)
	local maximum=0
	for i=0,127 do
		for j=0,127 do
			maximum=max(abs(arr[i][j]),maximum)
		end
	end
	
	maximum+=0x.0001
	
	for i=0,127 do
		for j=0,127 do
			arr[i][j]=(rng/2*arr[i][j])/maximum
		end
	end
	
	return arr
end
-->8
--draw
--fill pattern gradient
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

cols={12,9,3,6}

function drawterrain()
	local ldist=500
	local tscale=10
	local colwidth=4
	local dz,ddz=1,1
	
	local z=15
	local pz=p.z
	local numcols=128/colwidth
	local ybuff={}
	for i=0,numcols do ybuff[i]=127 end
	local sinr,cosr=sin(p.r),cos(p.r)
	while z<ldist do
		local srz,crz=sinr*z*0.5,cosr*z*0.5
		local lx,ly,rx,ry,dx,dy
		lx=(-crz-srz)/tscale+p.x
		ly=(srz-crz)/tscale+p.y
		rx=(crz-srz)/tscale+p.x
		ry=(-srz-crz)/tscale+p.y
		dx=(rx-lx)/numcols
		dy=(ry-ly)/numcols
		for i=0,numcols do
			local h,n=getmapdata(lx,ly)
			local ssy=64+((pz-h)/z)*100
			local yb=ybuff[i]
			if ssy<yb then
				fillp(shades[n+1]|0b.001)
				local ssx=i*colwidth
				local ttype=cols[flr(h/16)+1]
				rectfill(ssx,ssy,ssx+colwidth,yb,ttype)
				ybuff[i]=ssy
			end
			lx+=dx
			ly+=dy
		end
		z+=dz
		dz+=ddz
	end
end

function drawmap()
	for i=0,127 do
		for j=0,127 do
			local	h,n=getmapdata(i,j)
			fillp(shades[n+1]|0b.001)
			local ttype=cols[flr(h/16)+1]
			pset(i,j,ttype)
		end
	end
end

function drawminimap()
	for i=0,32 do
		for j=0,32 do
			local	h,n=getmapdata(p.x+16-i,p.y+16-j)
			fillp(shades[n+1]|0b.001)
			local ttype=cols[flr(h/16)+1]
			pset(96+i,j,ttype)
		end
	end
	fillp()
	line(112,16,112+sin(p.r)*3,16+cos(p.r)*3,7)
	pset(112,16,8)
end

-->8
--player
p={}
p.x,p.y,p.r=0,0,0.25
rotspeed=0.005
movspeed=0.1
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
