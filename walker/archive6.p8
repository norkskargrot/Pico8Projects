pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
--main
--configuration
	--terrain
	wsize=64
	tsize=256
	tscale=0.8
	hscale=7000
	whscale=10
	wnoiscale=0.1
	tnoiscale=0.01
	waterheight=1
	lightrange=0.09
	lightmin=1
	lightmax=10
	--rendering terrain
	drawdist=8000
	objdrawdist=300
	fov=0.7
	aperspstart=200
	lightend=190
	drawstart=5
	drawstep=1
	drawstepdeltanear=0.8
	drawstepdeltafar=50
	colwidth=3
	playerheight=0.15
	--rendering sky
	sgradsize=120
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
	mspeed=1
	lspeed={h=0.01,v=2}
	showingmap=false
--data
	world={}
	terrain={}
	lighting={}
	clouds={}
	objects={}
	wateronscreen=false
	mapopenening=false
	isunderwater=false
	mopntime=0
	currentstate=0
	controlsenabled=true
		--current states:
			--0=normal
			--1=mapopen
	pos={x=wsize/2*tsize,y=wsize/2*tsize,z=1}
	--pos={x=0,y=0,z=1}
	rot={h=2,v=64}

function _init()
	srand(1)
	world=gennoise(wsize,wnoiscale)
	terrain=gennoise(tsize,tnoiscale)
	genlighting()
	genclouds()
	objs=genobjs()
	--dummytdata()
end
function _update()
	input()
end

function _draw()
	if currentstate==0 then
		drawworld()
	elseif currentstate==1 then
		if mapopening then
			if mopntime<1 then
				lmopntime=mopntime
				mopntime+=0.2
				if mopntime<0 then
					drawworld()
				end
				drawmap(mopntime,lmopntime)
			else
				controlsenabled=true
			end
		else
			if mopntime>-1 then
				lmopntime=mopntime
				mopntime-=0.2
				drawworld()
				drawmap(mopntime,lmopntime)
			else
				controlsenabled=true
				currentstate=0
			end
		end
	end
	drawlogs()
end

function drawworld()
 	flipscreen()
 	drawwater(rot.v)
	 drawsky(rot.v)
	 drawclouds(rot)
	 local vobjs=getvisobjs()
		vobjs=drawterrain(vobjs)
		drawobjs(vobjs)
		--drawortho(vobjs)
end

-->8
--map
function getheight(x,y)
	local harea=arrgetws(terrain,x,y)
	local hwrld=wget(x,y)
	return harea+hwrld*whscale
end

function wget(x,y)
	local lx=(x%tsize)/tsize
	local ly=(y%tsize)/tsize
	local ax=((x/tsize)&0xffff)%wsize
	local ay=((y/tsize)&0xffff)%wsize
	local ax1=(((x/tsize)&0xffff)+1)%wsize
	local ay1=(((y/tsize)&0xffff)+1)%wsize
	if lx+ly<1 then
		local h=arrgetas(world,ax,ay)
		local dx=arrgetas(world,ax1,ay)-h
		local dy=arrgetas(world,ax,ay1)-h
		return h+lx*dx+ly*dy
	else
		local h=arrgetas(world,ax1,ay1)
		local dx=arrgetas(world,ax,ay1)-h
		local dy=arrgetas(world,ax1,ay)-h
		return h+(1-lx)*dx+(1-ly)*dy
	end
end

function arrset(arr,x,y,val)
	local byte=arr[flr(x/4)][y]
	byte=byte&(~(0x.ff<<((2-(x%4))*8)))
	val=val&0x.ff
	local shft=val<<((2-(x%4))*8)
	local newbyte=byte|shft
	arr[flr(x/4)][y]=newbyte
end

function arrgetws(arr,x,y)
	local tscale=tscale
	local dim=tsize
 x=((x*tscale)%dim)&0xffff
 y=((y*tscale)%dim)&0xffff
	local byte=arr[(x>>2)&0xffff][y]
	return (byte<<((x%4-2)<<3))&0x.ff
end

function arrgetas(arr,x,y)
	local byte=arr[(x>>2)&0xffff][y]
	return (byte<<((x%4-2)<<3))&0x.ff
end

function lset(x,y,val)
	local byte=lighting[flr(x/8)][y]
	byte=byte&(~(0x.f<<((2-(x%8))*4)))
	val=val&0x.f
	local shft=val<<((4-(x%8))*4)
	local newbyte=byte|shft
	lighting[flr(x/8)][y]=newbyte
end

function lget(x,y,ws)
	if ws then
		local tscale=tscale
		local dim=tsize
	 x=((x*tscale)%dim)&0xffff
	 y=((y*tscale)%dim)&0xffff
	end
	local byte=lighting[(x>>3)&0xffff][y]
	return (byte<<((x%8-4)<<2))&0x.f
end

function gennoise(dim,noiscale)
	local arr={}
	--initialise array of zeros
	for i=0,dim/4 do
		arr[i]={}
		for j=0,dim do
			arr[i][j]=0
		end
	end
	--generate the terrain height
	corners(arr,dim)
	dsrecurse(arr,dim,dim,noiscale)
	return arr
end

function corners (arr,dim)
	arrset(arr,0,0,0.5)
	arrset(arr,dim,0,0.5)
	arrset(arr,0,dim,0.5)
	arrset(arr,dim,dim,0.5)
end

function dsrecurse(arr,dim,size,noiscale) 
	local half = size/2
	if half<1 then return end
	--squares
	for y=half,dim,size do
		for x=half,dim,size do
			square(arr,dim,x%dim,y%dim,half,noiscale)
		end
	end
	--diamonds
	col=0
	for x=0,dim,half do
		col+=1
		if col%2==1 then
			for y=half,dim,size do
				diamond(arr,dim,x%(dim+1),y%(dim+1),half)
			end
		else
			for y=0,dim,size do
				diamond(arr,dim,x%(dim+1),y%(dim+1),half)
			end
		end
	end
	--recurse
	dsrecurse(arr,dim,size/2,noiscale)
end

function square (arr,dim,x,y,r,noiscale)
	local avg=arrgetas(arr,x-r,y-r)
	avg+=arrgetas(arr,x-r,y+r)
	avg+=arrgetas(arr,x+r,y-r)
	avg+=arrgetas(arr,x+r,y+r)
	avg/=4
	
	local range=r*noiscale
	avg+=rnd(range*2)-range
	avg=mid(0,avg,0x.ff)
	arrset(arr,x,y,avg)
end

function diamond(arr,dim,x,y,r)
	d1=dim
	avg=arrgetas(arr,(x-r)%d1,y)
	avg+=arrgetas(arr,(x+r)%d1,y)
	avg+=arrgetas(arr,x,(y-r)%d1)
	avg+=arrgetas(arr,x,(y+r)%d1)
	
	avg/=4
	--avg+=random(dim*r*noisestrength)
	avg=mid(0,avg,0x.ff)
	arrset(arr,x,y,avg)
end


function genlighting()
	local lrange=lightrange
	local lmin=lightmin
	local lmax=lightmax
	local dim=tsize
	for i=0,dim/8 do
		lighting[i]={}
		for j=0,dim do
			lighting[i][j]=0
		end
	end
	for i=0,dim do
		for j=0,dim do
			h=arrgetas(terrain,i,j)
			--lighting
			l1=arrgetas(terrain,(i+1)%dim,j)
			r1=arrgetas(terrain,(i-1)%dim,j)
			l2=arrgetas(terrain,(i+2)%dim,j)
			r2=arrgetas(terrain,(i-2)%dim,j)
			light=l1+l2*0.5-r1-r2*0.5
			lightcapped=max(min(light,lrange),-lrange)
			mapped=remap(lightcapped,-lrange,lrange,0,1)
			
			lset(i,j,mapped)
		end
	end
end

function genclouds()
	for i=0,20 do
		local x=rnd(256)
		local y=rnd(cheight)
		local r=rnd(cradrng)+cradmin
		local s=rnd(cmaxspd*2)-cmaxspd
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

colours= {
	--water
	{1,12,12},
	--sand
	{10,9,4},
	--grass
	{11,3,1},
	--stone
	{6,13,1},
	--snow
	{7,6,13}
}

function drawterrain(vobjs)
	local objstodraw={}
	wateronscreen=false
	local terrain=terrain
	--precalc angle params
	local sinr=sin(rot.h)
	local cosr=cos(rot.h)
	local fov=fov
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
		lastdraw[1][i]=1
	end
	--distance of samples from player
	local dz=drawstep
	local z=drawstart
	--loop until z=drawdist
	while z<drawdist do
	--add objects to be drawn
		for k,v in pairs(vobjs) do
			if v.y<z and v.y>z-dz then
				local height=getheight(v.wx,v.wy)		
				v.ssy=(pos.z-height)/v.y*hscale+rot.v
				v.size=1000/v.y
				v.clip=ybuff[flr(v.ssx/3)]
				objstodraw[#objstodraw+1]=v
			end
		end
	 --screen left in world space
		local plx=-cosr*z*fov-sinr*z+pos.x
		local ply=sinr*z*fov-cosr*z+pos.y
		--screen right in world space
		local prx=cosr*z*fov-sinr*z+pos.x
		local pry=-sinr*z*fov-cosr*z+pos.y
		--fade terrain into sky
		local aperspshade=0
		if z>aperspstart then
			aperspval=remap(z>>4,aperspstart>>4,drawdist>>4,1,16)
			aperspshade=shades[flr(aperspval)]
		end
		--iterate across screen
		local dx=(prx-plx)/numcols
		local dy=(pry-ply)/numcols
		for i=0,numcols do
			--get height in w&s space
			local height=getheight(plx,ply)
			local ssheight=(pos.z-height)/z*hscale+rot.v
			--check if we need to draw
			if ssheight<ybuff[i] then
				--ground colour
				local ttype=ttypefromheight(height)--psample(colour,plx,ply)
				local col=colours[ttype][2]
				--only draw if not water
				if height<waterheight then
					wateronscreen=true
					sswaterheight=(pos.z-waterheight)/z*hscale+rot.v
					ybuff[i]=sswaterheight
				else
					local sscol=i*colwidth
					--work out the fill pattern
					if z<lightend then
						local lsample=lget(plx,ply,true)
						col=setfill(ttype,lsample)
					elseif z<aperspstart then
						fillp(0)
					else
						col=col|12*16
						fillp(aperspshade&0xffff)
					end
					if z-1*dz>lastdraw[0][i] then
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i]-1,col)
						fillp(0)
						rectfill(sscol,ybuff[i],sscol+colwidth-1,ybuff[i],colours[lastdraw[1][i]][3])
					else
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i],col)
					end
					ybuff[i]=ssheight
				end
				lastdraw[0][i]=z
				lastdraw[1][i]=ttype
			end
			plx+=dx
			ply+=dy
		end
		
		if z>aperspstart then
			dz+=drawstepdeltafar
		end
		dz+=drawstepdeltanear
		z+=dz
	end
	fillp(0)
	for i=0,numcols do
		local sscol=i*colwidth
		local h=ybuff[i]
		if (h>rot.v) then 
			rectfill(sscol,rot.v,sscol+colwidth-1,h,12)
		end
		rectfill(sscol,h,sscol+colwidth-1,h,colours[lastdraw[1][i]][3])
	end
	
	return objstodraw
end

function ttypefromheight(h)
	--if true then return h*16 end
	if h<waterheight then return 1 end
	if h<1.5 then return 2 end
	if h<4 then return 3 end
	if h<6 then return 4 end
	return 5
end

function setfill(col,bright)
	--bright=(time()/10)&0x.ffff
	if bright<0.5 then
		bright=bright<<5
		fillp(shades[flr(bright)])
		col=colours[col][1]+colours[col][2]*16
	else
		bright=(bright-0.5)<<5
		fillp(shades[flr(bright)])
		col=colours[col][2]+colours[col][3]*16
	end
	return col
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
	if not wateronscreen then return end
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
	if not wateronscreen then return end
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

function drawmap(popen,lpopen)
	if popen<0 then
		raisemap(popen+1)
	else
		openmap(popen,lpopen)
	end
end

function raisemap(popen)
	fillp(shades[9])
	local pos=192-popen*128
	local h=78
	rectfill(62,pos-h/2,66,pos+h/2,6+9*16)
	drawroll(64,pos,h,false)
	drawroll(64,pos,h,true)
end

function openmap(popen,lpopen)
	local size=min(wsize,100)
	local border=(128-size)/2
	local ⬅️⬅️=border+(1-popen)*size/2
	local ⬅️➡️=border+(1-lpopen)*size/2
	local ➡️⬅️=128-border-(1-lpopen)*size/2
	local ➡️➡️=128-border-(1-popen)*size/2
	local extwdth=25
	local ext⬅️=extwdth
	local ext➡️=128-extwdth
	
	if mapopening then
		--map background
		fillp(shades[9])
		rectfill(⬅️⬅️-2,ext⬅️,⬅️➡️,ext➡️,6+9*16)
		rectfill(➡️⬅️+1,ext⬅️,➡️➡️+3,ext➡️,6+9*16)
		
		--actual map
		fillp(0)
		for i=0,size do
			for j=0,size do
				local ibord=i+border
				if ibord>=⬅️⬅️-3 and ibord<=⬅️➡️ then
					mappixelset(i,j,ibord,border)
				elseif ibord>=➡️⬅️ and ibord<=➡️➡️+3 then
					mappixelset(i,j,ibord,border)
				end
			end
		end
	else
		fillp(shades[9])
		rectfill(⬅️⬅️-2,ext⬅️,➡️➡️+3,ext➡️,6+9*16)
	end
	
	--map edges
	cpybckgrnd(-2,ext⬅️-4,⬅️⬅️,➡️➡️-⬅️⬅️+4)
	cpybckgrnd(-2,ext⬅️-3,⬅️⬅️,➡️➡️-⬅️⬅️+4)
	cpybckgrnd(2,ext➡️+4,⬅️⬅️,➡️➡️-⬅️⬅️+4)
	cpybckgrnd(2,ext➡️+3,⬅️⬅️,➡️➡️-⬅️⬅️+4)
	clip(⬅️⬅️+1,0,➡️➡️-⬅️⬅️+1,128)
	local sprnum=0
	for i=0,128,8 do
			sprnum=(sprnum+1)%2
			sspr(8,sprnum*4,8,4,i+1,ext⬅️-4)
			sspr(8,sprnum*4,8,4,i+1,ext➡️+1,8,4,false,true)
	end
	clip(0)
	
	--rolls
	drawroll(⬅️⬅️-2,64,78,false)
	drawroll(➡️➡️+3,64,78,true)
	
	--player position+rotation
	local l=1000
	local px=(pos.x/tsize)+border
	local py=(pos.y/tsize)+border
	local lx=((pos.x-l*sin(rot.h))/tsize)+border
	local ly=((pos.y-l*cos(rot.h))/tsize)+border
	line(px,py,lx,ly,8)
	pset(px,py,0)
end

function cpybckgrnd(shift,srcvert,strt,lngth)
	local src=0x6000+(srcvert)*64+strt/2
	local dest=0x6000+(srcvert+shift)*64+strt/2
	local length=(lngth)/2
	memcpy(src,dest,length)
end

function drawroll(posx,posy,h,flp)
	if flp then posx+=12 end
	local ⬆️=posy-(h/2)
	local ⬇️=posy+(h/2)
	local col = 6+9*16
	fillp(shades[9])
	rectfill(posx-11,⬆️+3,posx-4,⬇️-3,col)
	local col = 4+9*16
	rectfill(posx-3,⬆️+3,posx-1,⬇️-3,col)
	fillp(0)
	local h⬆️=⬆️+h/5
	local h⬇️=⬇️-h/5
	line(posx-12,⬆️+4,posx-12,h⬆️,4)
	line(posx-11,h⬆️,posx-11,h⬇️,4)
	line(posx-12,h⬇️,posx-12,⬇️-4,4)
	line(posx,⬆️+4,posx,h⬆️,5)
 line(posx-1,h⬆️,posx-1,h⬇️,5)
	line(posx,h⬇️,posx,⬇️-4,5)
	if flp then
		sspr(32,0,16,8,posx-13,⬆️-4,16,8,true,false)
		sspr(32,0,16,8,posx-13,⬇️-3,16,8,true,true)
	else
		sspr(16,0,16,8,posx-14,⬆️-4)
		sspr(16,0,16,8,posx-14,⬇️-3,16,8,false,true)
	end
end

function mappixelset(i,j,ibord,border)
	local ttype=ttypefromheight(arrgetas(world,i,j)*whscale)
	local ttypeb=ttypefromheight(arrgetas(world,min(i+1,wsize),j)*whscale)
	local ttypec=ttypefromheight(arrgetas(world,i,min(j+1,wsize))*whscale)
	if ttype!=ttypeb or ttype!=ttypec then
		pset(ibord,j+border,4)
	else
		fillp(shades[9]|0b.1)
		local col=colours[ttype][2]
		pset(ibord,j+border,col)
		fillp(0)
	end
end

-->8
--update
function input()
	if not controlsenabled then return end
	if currentstate==0 then
		normalupdate()
	elseif currentstate==1 then
		mapupdate()
	end
end

function normalupdate()
	local startpos = pos
	local moved=0
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
		--if btn(2) then fov+=0.1 end
		--if btn(3) then fov-=0.1 end
 elseif btn(5) then
 	if btn(2) then
 		mapopening=true
 	 mopntime=-1
 	 controlsenabled=false
 		currentstate=1
 	end
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
	theight=max(waterheight,getheight(pos.x,pos.y))
	pos.z=theight+playerheight
	--walking sounds
	if moved==1 then
		--wlksound()
	end
	
	local oldmpos=mapposfrompos(startpos)
	local newmpos=mapposfrompos(pos)
	
	printh("oldmpos=")
	printh(oldmpos.x)
	
	printh("newmpos=")
	printh(newmpos.x)
end

function mapposfrompos(pos)
	local x=flr(pos.x/tsize)%wsize
	local y=flr(pos.y/tsize)%wsize
	local mappos={x=x,y=y}
	return mappos
end

function mapupdate()
	if btn(5) then
 	if btn(2) then
 		mapopening=false
 		controlsenabled=false
 	end
	end
end
-->8
--utility
function remap(v,l1,h1,l2,h2)
	return (v-l1)*(h2-l2)/(h1-l1)+l2
end

function	vector_dot(ax,ay,az,bx,by,bz)
	return ax*bx+ay*by+az*bz
end

function	getplayermpos()
	local mpos={}
	mpos.x=flr(pos.x/tsize)
	mpos.y=flr(pos.y/tsize)
	return mpos
end

function trnsfmpoint(px,py,r,vx,vy)
	local newvert={}
	local shiftx=vx-px
	local shifty=vy-py
	local sinr=sin(r)
	local cosr=cos(r)
	newvert.x=shiftx*cosr+shifty*sinr
	newvert.y=shiftx*sinr-shifty*cosr
	return newvert
end

function drawlogs()
	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("memory=",0,12,7)
	print(stat(0),28,12,7)
	
	print("x=",0,18,7)
	print(pos.x*tscale,8,18,7)
	
	print("y=",0,24,7)
	print(pos.y*tscale,8,24,7)
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
-->8
--objects
--obj types: 
	--1=static
	--2=npc
	
staticdata={
--sprite,w,h,l1,d1,l2,d2,vd1,vd2
	{48,2,4,11,3,4,5,1,1}, --pinetree
	{56,2,2,13,5,7,6,1,13}, --rock
}

npcdata={
--sprite,w,h
	{64,1,1}, --orc
	{72,1,1}, --goblin
}

function genobjs()
	local num=0
	local objs={}
	for i=-1,1 do
		objs[i]={}
		for j=-1,1 do
			objs[i][j]={}
			spawnobjs(objs,2,1,1,i,j)
			spawnobjs(objs,1,1,2,i,j)
			spawnobjs(objs,3,2,1,i,j)
			spawnobjs(objs,3,2,2,i,j)
		end
	end
	return objs
end

function spawnobjs (objs,num,typ,ver,i,j)
	for k=0,num do
		local newobj={}
		newobj.x=rnd(tsize)
		newobj.y=rnd(tsize)
		newobj.type=typ
		newobj.version=ver
		objs[i][j][#objs[i][j]+1]=newobj
		num+=1
	end
	return objs
end

function getvisobjs()
	local vobjs={}
	local pmposx=flr((pos.x/tsize)%wsize)
	local pmposy=flr((pos.y/tsize)%wsize)
	for i=-1,1 do
		local mposx=((pmposx+i)%wsize)*tsize
		for j=-1,1 do
			local mposy=((pmposy+j)%wsize)*tsize
			for k,v in pairs(objs[i][j]) do
				wx=v.x+mposx
				wy=v.y+mposy
				local newobj=trnsfmpoint(pos.x,pos.y,-rot.h,wx,wy)
				if newobj.y>0 and newobj.y<objdrawdist then
					newobj.ssx=64+newobj.x/newobj.y*80
					if newobj.ssx>0 and newobj.ssx<128 then
						newobj.wx=wx
						newobj.wy=wy
						newobj.type=v.type
						newobj.version=v.version
						vobjs[#vobjs+1]=newobj
					end
				end
			end
		end
	end
	return vobjs
end

function drawobjs(vobjs)
	local prot=(rot.h-0.25)%1
	--fillp(shades[17]|0b.011)
	local length=#vobjs
	for i=0,length-1 do
		obj=vobjs[length-i]
		if obj.type==1 then
			drawstatic(prot,obj)
		else
			drawsprite(prot,obj)
		end
	end
	fillp(0)
end

function drawsprite(prot,obj)
		clip(0,0,128,obj.clip)
		local data=npcdata[obj.version]
		local w=obj.size*data[2]
		local h=obj.size*data[3]
		setlpalblack(data)
		palt(0,false)
		palt(1,true)
		sspr(data[1],0,8,8,obj.ssx-w/2-1,obj.ssy-h,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2+1,obj.ssy-h,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h-1,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h+1,w,h)
		pal()
		palt(0,false)
		palt(1,true)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h,w,h)
		clip(0)
		pal()
end

function drawstatic(prot,obj)
		clip(0,0,128,obj.clip)
		local data=staticdata[obj.version]
		local w=obj.size*data[2]
		local h=obj.size*data[3]
		setlpaloutline(data)
		sspr(data[1],0,8,8,obj.ssx-w/2-1,obj.ssy-h,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2+1,obj.ssy-h,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h-1,w,h)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h+1,w,h)
		setpal(prot+(obj.ssx-64)/512,data)
		sspr(data[1],0,8,8,obj.ssx-w/2,obj.ssy-h,w,h)
		clip(0)
		pal()
end

function setpal(lightrot,objdata)
	for i=1,8 do
		if lightrot<0.5 then
			if i<lightrot*16 then
				pal(i,objdata[4])
				pal(i+8,objdata[6])
			else
				pal(i,objdata[5])
				pal(i+8,objdata[7])
			end
		else
			if i>(lightrot-0.5)*16 then
				pal(i,objdata[4])
				pal(i+8,objdata[6])
			else
				pal(i,objdata[5])
				pal(i+8,objdata[7])
			end
		end
	end
end

function setlpaloutline(objdata)
	for i=1,8 do
		pal(i,objdata[8])
		pal(i+8,objdata[9])
	end
end

function setlpalblack(objdata)
	for i=1,15 do
		pal(i,0)
	end
end

function drawortho(vobjs)
	--cls()
	local llngth=-5
	local lendx=64+sin(rot.h)*llngth
	local lendy=64+cos(rot.h)*llngth
	line(64,64,lendx,lendy,8)
	pset(64,64,8)
	local length=#vobjs
	for i=0,length-1 do
		local v=vobjs[length-i]
		pixelx=(v.wx-pos.x)/8+64
		pixely=(v.wy-pos.y)/8+64
		rect(pixelx-1,pixely-1,pixelx+1,pixely+1,0)
		pset(pixelx,pixely,(v.x/128)*16)
	end
	
	local pmposx=(pos.x/tsize)%wsize
	local pmposy=(pos.y/tsize)%wsize
			
	local xflr=pos.x-flr(pmposx)*tsize
	local xcel=pos.x-ceil(pmposx)*tsize
	local yflr=pos.y-flr(pmposy)*tsize
	local ycel=pos.y-ceil(pmposy)*tsize
	
	local ⬆️⬅️={}
	⬆️⬅️.x=(tsize-pos.x)/8+64
	⬆️⬅️.y=(tsize-pos.y)/8+64
	local ⬇️➡️={}
	⬇️➡️.x=-pos.x/8+64
	⬇️➡️.y=-pos.y/8+64
	rect(⬆️⬅️.x,⬆️⬅️.y,⬇️➡️.x,⬇️➡️.y,0)
end


__gfx__
00000000400444040004444444440444000444444444044400027000001180001111116111111111000000600000000088000000007777000000000000000000
0000000064046949045549696969496904469696696949690002700001127800133331611111111103333060000000000dddd000007070000000000000000000
0070070096469696459495555554449649696444444555960023670001236780330301411b1b11113303004000000000dd0d0000007777000000000000000000
0007700069696969494959494696964956965696969949590023670001336780133737411bbbb11103373740000444400d373706000700000000000000000000
0007700044440044449595555569696555649544455494940134568012336680154451411b0b0161666450400554040005dd5060007777000000000000000000
0070070069694469064469699596945505554649969645540134568022345678144441311444461166644030555447470dddd300070700700000000000000000
000000009696969604694446645549450594555644455694124455782344566735555141b5555b11666550400555550035555000000770000000000000000000
0000000069696969049696944494949505494995996969640009f000234455671511514115115111050050400500050005005000007070000000000000000000
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

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000100020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000102020002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000700001761718627156170560700600006000860007600006100f6000d600076000e6000c6000b6000a60009600076000d6000c6000b6000a6000a6000c6000b6000c6000c6000e6000c6000a6000760007600
900700001a6101c620146201361000000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000f63709617056070260702600006000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900700001c620156300f6200e62012620146100e6100d610006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000b0501e35022350273502d350313503235032350313502f3502d3502b350283502435021350213502035020350120501105011050130501505000000180501a0501d0501f05024050270502a0502b050
__music__
00 40424344

