pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
--main
--configuration
	--terrain
	dim=256
	tscale=0.5
	hscale=2000
	noisestrength=0.00015
	waterheight=0.3
	lightrange=0.1
	--rendering terrain
	drawdist=80
	farlift=0.1
	aperspstart=60
	lightend=50
	drawstart=1
	drawstep=1
	drawstepdelta=0.3
	colwidth=2
	playerheight=0.05
	--rendering sky
	sgradsize=100
	sgradmin=8
	cheight=10
	cradmin=15
	cradrng=10
	cmaxspd=2
	--rendering water
	wavspd=0.5
	wavdistx=6
	wavdisty=8
	--controls
	mspeed=0.2
	lspeed={h=0.01,v=2}
--data
	terrain={}
	lighting={}
	colour={}
	clouds={}
	pos={x=0,y=0,z=1}
	rot={h=0,v=64}

function _init()
	--srand(0)
	genterrain()
	genclouds()
end
function _update()
	input()
end

function _draw()
 flipscreen()
 drawsky(rot.v)
 drawwater(rot.v)
 drawclouds(rot)
	drawterrain()
	--flipscreen()
	--drawterrainortho()
	--drawminimap(30,5)
	drawlogs()
end

-->8
--map
function psample(array,x,y)
	local tscale=tscale
	local dim=dim
	local xcoord=flr((x*tscale)%dim)
	local ycoord=flr((y*tscale)%dim)
	return array[xcoord][ycoord]
end

function bsample(array,x,y)
	xscaled=(x*tscale)%dim
	yscaled=(y*tscale)%dim
	xf=flr(xscaled)
	yf=flr(yscaled)
	xc=ceil(xscaled)
	yc=ceil(yscaled)
	if xf==xc then xc+=1 end
	if yf==yc then yc+=1 end
	sbl=array[xf][yf]
	sbr=array[xc][yf]
	stl=array[xf][yc]
	str=array[xc][yc]
	su=(stl+str)/2
	sd=(sbl+sbr)/2
	sl=(stl+sbl)/2
	sr=(str+sbr)/2
	du=yc-yscaled
	dd=yscaled-yf
	dr=xc-xscaled
	dl=xscaled-xf
	return (dr*sl+dl*sr+du*sd+dd*su)/(du+dd+dl+dr)
end

function genterrain()
	for i=0,dim do
		terrain[i]={}
		end
	corners(dim)
	dsrecurse(dim,dim)
	genlighting()
end

function corners (dim)
	terrain[0][0]=0.5
	terrain[dim][0]=0.5
	terrain[0][dim]=0.5
	terrain[dim][dim]=0.5
end

function dsrecurse(dim,size) 
	local half = size/2
	if half<1 then return end
	--squares
	for y=half,dim,size do
		for x=half,dim,size do
			square(dim,x%dim,y%dim,half)
		end
	end
	--diamonds
	col=0
	for x=0,dim,half do
		col+=1
		if col%2==1 then
			for y=half,dim,size do
				diamond(dim,x%(dim+1),y%(dim+1),half)
			end
		else
			for y=0,dim,size do
				diamond(dim,x%(dim+1),y%(dim+1),half)
			end
		end
	end
	--recurse
	dsrecurse(dim,size/2)
end

function square (dim, x, y, r)
	d1=dim
	avg=terrain[x-r][y-r]
	avg+=terrain[x-r][y+r]
	avg+=terrain[x+r][y-r]
	avg+=terrain[x+r][y+r]
	
	avg/=4
	avg+=random(r*dim*noisestrength)
	avg=clamp(avg,0,1)
	--mset(x,y,9)
	terrain[x][y]=avg
end

function diamond(dim,x,y,r)
	d1=dim
	avg=terrain[(x-r)%d1][y]
	avg+=terrain[(x+r)%d1][y]
	avg+=terrain[x][(y-r)%d1]
	avg+=terrain[x][(y+r)%d1]
	
	avg/=4
	--avg+=random(dim*r*noisestrength)
	avg=clamp(avg,0,1)
	--mset(x,y,10)
	terrain[x][y]=avg
end

function genlighting()
	for i=0,dim do
		lighting[i]={}
		colour[i]={}
		for j=0,dim do
			h=terrain[i][j]
			if h<waterheight then
				lighting[i][j]=shades[1]
				colour[i][j]=12;
			else
				--lighting
				l=terrain[(i+1)%dim][j]
				r=terrain[(i-1)%dim][j]
				light=l-r
				lightcapped=max(min(light,lightrange),-lightrange)
				mapped=remap(lightcapped,-lightrange,lightrange,1,17)
				lighting[i][j]=shades[flr(mapped)]
				--colour
				colour[i][j]=colfromheight(h)
			end
		end
	end
end

function colfromheight(h)
	if h<waterheight then return 12 end
	if h<0.4 then return 9 end
	if h<0.7 then return 3 end
	return 5
end

function genclouds()
	for i=0,20 do
		local x=rnd(256)
		local y=rnd(cheight)
		local r=rnd(cradrng)+cradmin
		local s=random(cmaxspd)
		clouds[i]={x=x,y=y,r=r,s=s}
	end
end

-->8
--draw
//fill pattern gradient
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

function drawterrain()
	--precalc angle params
	local sinr=sin(rot.h)
	local cosr=cos(rot.h)
	--columns
	local numcols=128/colwidth
	--y buffer for occlusion
	local ybuff={}
	local lastdraw={}
	lastdraw[0]={}
	lastdraw[1]={}
	for i=0,numcols do
		ybuff[i]=128
		lastdraw[0][i]=0
	end
	--distance of samples from player
	local dz=drawstep
	local z=drawstart
	--loop until z=drawdist
	while z<drawdist do
	 --screen left in world space
		local plx=-cosr*z-sinr*z+pos.x
		local ply=sinr*z-cosr*z+pos.y
		--screen right in world space
		local prx=cosr*z-sinr*z+pos.x
		local pry=-sinr*z-cosr*z+pos.y
		--fade terrain into sky
		if z>aperspstart then
			aperspval=remap(z,aperspstart,drawdist,17,1)
			aperspshade=bnot(shades[flr(aperspval)])
		end
		--iterate across screen
		local dx=(prx-plx)/numcols
		local dy=(pry-ply)/numcols
		for i=0,numcols do
			--get height in w&s space
			local height=psample(terrain,plx,ply)
			local ssheight=(pos.z-height)/z*hscale+rot.v-z*farlift
			--check if we need to draw
			if ssheight<ybuff[i] then
				--ground colour
				local col=psample(colour,plx,ply)
				--only draw if not water
				if height>waterheight then
					local sscol=i*colwidth
					--work out the fill pattern
					if z<lightend then
						local lsample=psample(lighting,plx,ply)
						fillp(lsample/1|0b.001)
					elseif z<aperspstart then
						fillp(0)
					else
						fillp(aperspshade/1|0b.101)
					end
					if z-dz>lastdraw[0][i] then
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i]-1,col)
						fillp(shades[17]|0b.001)
						rectfill(sscol,ybuff[i],sscol+colwidth-1,ybuff[i],lastdraw[1][i])
					else
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i],col)
					end
				end
				lastdraw[0][i]=z
				lastdraw[1][i]=col
				ybuff[i]=ssheight
			end
			plx+=dx
			ply+=dy
		end
		dz+=drawstepdelta
		z+=dz
	end
	fillp(shades[17]|0b.001)
	for i=0,numcols do
		local sscol=i*colwidth
		local h=min(ybuff[i],rot.v)
		rectfill(sscol,h,sscol+colwidth-1,h,lastdraw[1][i])
	end
end

function drawsky(hori)
	rectsize=sgradsize/sgradmin
	gradtop=hori-sgradsize
	fillp(shades[sgradmin+1]|0b.011)
	rectfill(0,0,128,gradtop,12)
	for i=1,sgradmin do
		top=rectsize*(i-1)+gradtop
		bottom=rectsize*i+gradtop
		fillp(shades[sgradmin-i+2]|0b.011)
		rectfill(0,top,128,bottom,12)
		hh=2*hori
		if top<0 then
			rectfill(0,max(hh,hh-bottom),128,2*hori-top,12)
		end
	end
end

function drawwater(horizon)
	local wgradsize=15
	local wgradmin=12
	local rectsize=wgradsize/wgradmin
	for i=1,wgradmin do
		local top=rectsize*(i-1)+horizon
		local bottom=rectsize+top
		fillp(shades[17-wgradmin+i-2]/1|0b.1)
		rectfill(0,top,128,bottom,12)
	end
end

function drawclouds(r)
	clip(0,0,128,r.v)
	fillp(bnot(shades[9])|0b.1)
	for c in all (clouds) do
		local x=(c.x+time()*c.s-r.h*128*4)%256-64
		circfill(x,r.v-c.y,c.r,7)
	end
	clip(0,0,128,128)
end

function flipscreen ()
	--values are the screen in memory
 local scbtm=0x6000
 local sctop=0x7fff
 local scsize=sctop-scbtm
 local flpline=64*(rot.v)
 --return if the line is offscreen
 if flpline<0 then return end
 --precalc the lines for water fx
 local offsets={}
 local wavspd=wavspd
 local wavdistx=wavdistx
 local wavdisty=wavdisty
 for i=0,wavdisty do
 	offsets[i]=sin(time()*wavspd+i/wavdisty)
 end
	for i=0,flpline,64 do
		if flpline+i>scsize then return end
		local rowoffset=offsets[(i/64)%wavdisty]*wavdistx*(i/flpline)
		memcpy(scbtm+flpline+i,scbtm+flpline-i+rowoffset,64)
	end
end

function drawminimap (size,scale)
	local hsize=size/2
	for i=0,size do
		for j=0,size do
			x=(flr((i+pos.x)*scale))%dim
			y=(flr((j+pos.y)*scale))%dim
			fillp(0)
			pset(128-size+i,128-size+j,psample(colour,x,y))
		end
	end
end

function drawterrainortho ()
	for i=0,dim do
		for j=0,dim do
			x=(flr(i+pos.x))%dim+1
			y=(flr(j+pos.y))%dim+1
			height=terrain[x][y]
			if height<0.2 then
				pset(i,j,0)
			elseif height<0.4 then
				pset(i,j,1)
			elseif height<0.6 then
				pset(i,j,5)
			elseif height<0.8 then
				pset(i,j,6)
			else
				pset(i,j,7)
			end
			--fillp(lighting[x][y]|0b.001)
			--pset(i,j,colour[x][y])
		end
	end
end

-->8
--update
function input()
	moved=0
 if btn(4) then
  --strafe
		if btn(0) then
		 pos.x-=sin(rot.h-0.25)*mspeed
		 pos.y-=cos(rot.h-0.25)*mspeed
	 	moved=1
	 end
		if btn(1) then
		 pos.x+=sin(rot.h-0.25)*mspeed
		 pos.y+=cos(rot.h-0.25)*mspeed
			moved=1
		end
		--look up and down
		if btn(2) then rot.v+=lspeed.v end
		if btn(3) then rot.v-=lspeed.v end
	else
		--rotate view
		if btn(0) then rot.h-=lspeed.h end
		if btn(1) then rot.h+=lspeed.h end
		--walk forward&backward
		if btn(2) then
		 pos.x-=sin(rot.h)*mspeed
		 pos.y-=cos(rot.h)*mspeed
		 moved=1
	 end
		if btn(3) then
		 pos.x+=sin(rot.h)*mspeed
		 pos.y+=cos(rot.h)*mspeed
		 moved=1
		end
	end
	--limit pos to world bounds
	pos.x = pos.x%(dim/tscale)
	pos.y = pos.y%(dim/tscale)
	--set player's height from terrain
	theight=bsample(terrain,pos.x,pos.y)
	pos.z=max(theight,waterheight)+playerheight
	--walking sounds
	if moved==1 then
		--wlksound()
	end
end
-->8
--utility
function random(range)
	return rnd(range*2) - range
end

function clamp(val, minimin, maximum)
	return max(min(val,maximum),minimum)
end

function remap(v,l1,h1,l2,h2)
	return (v-l1)*(h2-l2)/(h1-l1)+l2
end

function drawlogs()
	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("x=",0,12,7)
	print(pos.x*tscale,8,12,7)
	
	print("y=",0,18,7)
	print(pos.y*tscale,8,18,7)
end
-->8
--sound
function wlksound ()
	if stat(16)==-1 then
		ttype=psample(colour,pos.x,pos.y)
		local stype=0
		if ttype==3 then stype=0 end
		if ttype==9 then stype=1 end
		if ttype==5 then stype=2 end
		if ttype==12 then stype=3 end
		sfx(stype,0,0,8)
	end
end
__gfx__
0000000000000000000000000077000000000000000bb33055555555565656566666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
00000000000000000000000006777000000000000bb3b33355555555656565656666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
0070070000000777777700000667777777000000bbbb333355555555565656566666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
0007700000006777777777000066777777770000b333333355555555656565656666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
00077000067766776677660006777766667777003b33333355555555565656566666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
00700700766766666666667766677777666777070333333355555555656565656666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
00000000676666676677666766667766666667760033333055555555565656566666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
00000000666766777666666666666666666666660004500055555555656565656666666688888888bbbbbbbbcccccccc00000000000000000000000000000000
__label__
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
ccccc7c7c7ccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7
dc7c7c7c7c7c7cccdcccdcccdcccdcccdcccdcccdcccdccc7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdcccdcccdc5555cc55ccdcccdcccdcccdcccdc7c7c7c
c7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccccc55cdcd55cd55ccccccccccccccc7c7c7c7c7
7c7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdcccdc7c7c7c7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdccc55dcdddddddddd55dcccdcccdccc7c7c7c7c7c
c7c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccc55cdcdcdcdcdcdcdcd5555ccccccc7c7c7c7c755
7c7c7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdc55dddddddddddddddddddddd55dccc7c7c7c7c55dc
1111c7c7c7c7c7c7c7c7c7c7ccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cc111111cdcd3d33333d3d3d33dd33333311ccc7c71111c3cd
333311117c7c7c7c7c7c7c7c7cdcccdcccdcccdccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c3c3c33dddd33333333333333dd333333331111113c3333d3
33333333111111c7c7c7c7c7c7ccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c711c3c333333333333333333333dd3333333333111111111133
11333333333333117c7c7c7c7c7cdcccdcccdccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c111133333333333333333333333333333333333333131313131333
313131333333333311c7c7c7c7c7ccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c711c3c3c3333333333333333333333333113311313131311131333111
131113333333333333117c7c7c7ccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c11111133333333333333333333333333333311111111111311131111111111
33313333333333333333111111c7ccccccccccccc7c7c7c7c7c7c7c7c7c7c71111c3c33333333333333333333333333333111111111131111111111111311111
3313131313133333113333333311111111ccdccc7c7c7c7c7c7c7c7c7c11113c3c3c333333333333333333333333333311111111111111111111111111111111
313333333311113333113333c3c3c3c9c311c9ccc7c7c7c7c7c7c7c744c7c7c7c933333333333333333333333333331111111111111111111111111111111111
13133313131113113333111111111111313c4444447c7c7c7c7c7c7c9c393c3c9933333333333333333333113311111111111111111111111111111111111111
3333333131113131333333313131313131113311c94444c7c7c74444c9c9c9993333333333333333333331313111311131313131311131111111111111111111
131313131111111313331333131311131313133344999c4444449999999999993333333333441111111313131111111111111111111111111111111111111111
11113133311111313133333333113194943131999944999999c9c9c9999999999999999494949431319431339411943131313111311111111111111111331111
13131113134411111311131313131344494413999949999999999999999999999999494944444911494449134949494913111311131111441111444449131344
31313399449999949931319433339944949494949999999999c9c9c7999999999994949494449494999999949494999431314411941194949494949494333394
1313111349494949491349449999494949444449999949ccdcccdccc99ccdc444944444444444449494449494949444944444444444444444444444444134444
3131313194949494949999999999999999949494949999cccc99cc99cccc44449494949444944494949494949494944444444444444494949494449444944444
49441313494949494949999999999999494949494999999c49494949494444494444494444444444444449494944494449444444444449444444444444444444
94943131949499949499999999999999994444cc99cc994494999999949494949999999494949444949494949494944494949444944494449444449494449444
444911134449494944499949999999494949493c4c9c9c4444494444444444494949494949494449444444494444444444444444444444444444444444444444
94943131949994949499999994999999949994ccc9ccc49494944444949444449444949944949494449444949494449494949494949494444444449444444444
494413134949494949499949494949494949494c4c7c7c44444444444944444444444444444449444444494949444444491c1c444949491c444444441c441c1c
99999931949499949494949999999994999499ccc7c7c7c7c7c7c7c7c4c7444444444444444494449444949494c3c3c1c1c1c19499c1c1c1c144c1c1c144c1c1
49494913444949494949494949494949494949cc7c7c7c7c7c7c7c7c7c1c4444444444444444334444444949493c333c111c1149491c111c111c111c1144111c
949999319499949494949494949994cccc9994ccc7c7c7c7c7c7c7c7c7c74444444444444444c3444444949494c3c3c3c3c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
4949494949494949494949444949cccccc4949cc7c7c7c7c7c7c7c7c7c7c44444444444444443c444444494949333c333c333c111c111c111c111c111c111c11
9999999499949994949494949999ccccccccccccc7c7c7c7c7c7c7c7c7c7c744444444444444c3c39444949494c3c3c3c3c3c3c3c1c3c1c1c1c1c1c1c1c3c1c1
4949494949494944494944497c49dcccdcccdccc7c7c7c7c7c7c7c7c7c7c7c7c447c44447c111133333333333333333333333333333333333333131313131333
949999949494949494949494c799ccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c744c7c7c7c1c3c333c333c333c333c333c3ddc333c333c311c111c111c3
4949494949494944494949497c49ccdcccdcccdccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c3c3c33dddd33333333333333dd333333331111113c3333d3
999999949994999494949494ccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7ccc111c1cdcd3dc333cd3dcd33cd33c333c1ccc7c7c111c3cd
49497c7c7c7c7c4449494449dcccdcccdcccdcccdc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccdcccdcccdc55dddddddddddddddddddddd55dccc7c7c7c7c55dc
9999c7c7c7c7c7c7c7949494ccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccc55cdcdcdcdcdcdcdcd5555ccccccc7c7c7c7c755
49497c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdcccdc7c7c7c7c7c7c7c7c7c7c7c7c7c7cccdcccdcccdcccdccc55dcdddddddddd55dcccdcccdccc7c7c7c7c7c
9999c7c7c7c7c7c7ccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7c7c7c7c7c7cccccccccccccccccccccc55cdcd55cd55ccccccccccccccc7c7c7c7c7
49497c7c7c7c7cccdcccdcccdcccdcccdcccdcccdcccdccc7c7c7c7c7c7c7c7c7c7cdcccdcccdcccdcccdcccdcccdc5555cc55ccdcccdcccdcccdcccdc7c7c7c
99ccc7c7c7ccccccccccccccccccccccccccccccccccccccc7c7c7c7c7c7c7c7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c7c7
49dcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999cccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999cccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc9999999999cccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999cccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc9999999999cccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999cccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc9999999999cccdcc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999dcdcdc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999cccccc
dcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc9999999999999999
cdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcccdcc9999999999999999

__sfx__
00070000176171862717617166070b600096000860007600006100f6000d600076000e6000c6000b6000a60009600076000d6000c6000b6000a6000a6000c6000b6000c6000c6000e6000c6000a6000760007600
900700001a6101c620146201361000000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000f63709617056070260702600006000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900700001c620156300f6200e62012620146100e6100d610006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 40424344

