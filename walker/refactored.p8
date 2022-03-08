pico-8 cartridge // http://www.pico-8.com
version 32
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
	objdrawdist=256
	fov=0.7
	aperspstart=200
	lightend=190
	drawstart=5
	drawstep=1
	drawstepdeltanear=0.8
	drawstepdeltafar=50
	colwidth=3
	playerheight=0.15
	--controls
	mspeed=1
	lspeed={h=0.01,v=2}
	showingmap=false
--data
	world={}
	terrain={}
	lighting={}
	objs={}
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
	--pos={x=120,y=120,z=1}
	rot=2

function _init()
	srand(1)
	world=genworld(wsize,wnoiscale)
	terrain=gennoise(tsize,tnoiscale)
	genlighting()
	objs=genobjs()
	initbuilding()
	--dummytdata()
end
function _update()
	input()
	updatenpcs()
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
	drawwater()
	drawsky()
	drawclouds(rot)
	local vobjs=getvisobjs()
	vobjs=drawterrain(vobjs)
	drawobjs(vobjs)
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
	local byte=world[ax][ay]
	local h=(byte>>16)&0x.ff
	local h➡️=(byte>>8)&0x.ff
	local h⬇️=(byte)&0x.ff
	local h➡️⬇️=(byte<<8)&0x.ff
	if lx+ly<1 then
		local dx=h➡️-h
		local dy=h⬇️-h
		return h+lx*dx+ly*dy
	else
		local dx=h⬇️-h➡️⬇️
		local dy=h➡️-h➡️⬇️
		return h➡️⬇️+(1-lx)*dx+(1-ly)*dy
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

function genworld(wsize,wnoiscale)
	local hdata=gennoise(wsize,wnoiscale)
	local world={}
	for i=0,wsize do
		world[i]={}
		for j=0,wsize do
			local newbit=0
			local i1=(i+1)%wsize
			local j1=(j+1)%wsize
			local h=arrgetas(hdata,i,j)
			local h➡️=arrgetas(hdata,i1,j)
			local h⬇️=arrgetas(hdata,i,j1)
			local h➡️⬇️=arrgetas(hdata,i1,j1)
			newbit=newbit|h<<16
			newbit=newbit|h➡️<<8
			newbit=newbit|h⬇️
			newbit=newbit|h➡️⬇️>>8
			world[i][j]=newbit
		end
	end
	return world
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
	local sinr=sin(rot)
	local cosr=cos(rot)
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
			if v.psy<z and v.psy>z-dz then
				local height=getheight(v.wx,v.wy)		
				v.ssy=(pos.z-height)/v.psy*hscale+64
				v.clip=ybuff[flr(v.ssx/3)]
				v.size=1000/v.psy
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
			local ssheight=(pos.z-height)/z*hscale+64
			--check if we need to draw
			if ssheight<ybuff[i] then
				--ground colour
				local ttype=ttypefromheight(height)--psample(colour,plx,ply)
				local col=colours[ttype][2]
				--only draw if not water
				if height<waterheight then
					wateronscreen=true
					sswaterheight=(pos.z-waterheight)/z*hscale+64
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
		if (h>64) then 
			rectfill(sscol,64,sscol+colwidth-1,h,12)
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
	rectfill(0,0,127,64,12)
	local bot=70
	local size=10
	local num=6
	for i=0,num-1 do
		bot-=size
		fillp(bnot(shades[i])|0b.1)
		rectfill(0,bot-size,127,bot,13)
	end
	fillp(bnot(shades[num])|0b.1)
	rectfill(0,0,127,bot,13)
	fillp()
end

function drawwater()
	if not wateronscreen then return end
	local top=80
	local size=6
	local num=6
	for i=0,num-1 do
		top+=size
		fillp(shades[17-i]|0b.1)
		rectfill(0,top,127,top+size,12)
	end
	fillp(shades[17-num]|0b.1)
	rectfill(0,top,127,127,12)
	fillp()
end

skx=0

function drawclouds(world_ang)
	local camx,camy=
	sin(world_ang),cos(world_ang)
   
 local stx,sty=
	-camx+cos(world_ang),
	-camy+(-sin(world_ang))
 poke(0x5f38,4)
 poke(0x5f39,4)
 poke(0x5f3a,sky_x1)
  
 for y=0,60 do
		local curdist=128/(2*y-128)
		local d16=curdist/64
		local j=y%2*.03
		tline(0,y,127,y,
	 j-skx+28+stx*curdist*1.2,
	 j+28+sty*curdist*1.2,
	 d16*camx,d16*camy)
 end
 skx+=0.0075
end

function flipscreen ()
	if not wateronscreen then return end
		wavspd=0.5
	wavdistx=6
	wavdisty=8
	--values are the screen in memory
 local scbtm=0x6000
 local sctop=0x7fff
 local scsize=sctop-scbtm
 local flpline=64*64
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
	local lx=((pos.x-l*sin(rot))/tsize)+border
	local ly=((pos.y-l*cos(rot))/tsize)+border
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
	local byte=world[i][j]
	local h=(byte>>16)&0x.ff
	local h➡️=(byte>>8)&0x.ff
	local h⬇️=(byte)&0x.ff
	local ttype=ttypefromheight(h*whscale)
	local ttypeb=ttypefromheight(h➡️*whscale)
	local ttypec=ttypefromheight(h⬇️*whscale)
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
	local startx = pos.x
	local starty = pos.y
	local moved=0
 if btn(4) then
  --strafe
		if btn(0) then
		 pos.x-=sin(rot-0.25)*mspeed
		 pos.y-=cos(rot-0.25)*mspeed
	 	moved=1
	 end
		if btn(1) then
		 pos.x+=sin(rot-0.25)*mspeed
		 pos.y+=cos(rot-0.25)*mspeed
			moved=1
		end
	elseif btn(5) then
 	if btn(2) then
 		mapopening=true
 	 mopntime=-1
 	 controlsenabled=false
 		currentstate=1
 	end
	else
		--rotate view
		if btn(0) then rot-=lspeed.h end
		if btn(1) then rot+=lspeed.h end
		--walk forward&backward
		if btn(2) then
		 pos.x-=sin(rot)*mspeed
		 pos.y-=cos(rot)*mspeed
		 moved=1
	 end
		if btn(3) then
		 pos.x+=sin(rot)*mspeed
		 pos.y+=cos(rot)*mspeed
		 moved=1
		end
	end
	theight=max(waterheight,getheight(pos.x,pos.y))
	pos.z=theight+playerheight
	--walking sounds
	if moved==1 then
		--wlksound()
	end
	
	checkmposchange(startx,starty,pos.x,pos.y)
end

function checkmposchange(startx,starty,posx,posy)
	local oldmpos=mapposfrompos(startx,starty)
	local newmpos=mapposfrompos(posx,posy)
	if oldmpos.x!=newmpos.x then
		if oldmpos.x>newmpos.x then
			updateobjs(2)
		else
			updateobjs(3)
		end
	end
	if oldmpos.y!=newmpos.y then
		if oldmpos.y>newmpos.y then
			updateobjs(0)
		else
			updateobjs(1)
		end
	end
end

function mapposfrompos(posx,posy)
	local x=flr(posx/tsize)%wsize
	local y=flr(posy/tsize)%wsize
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

function trnsfmpoint(vx,vy)
	local newvert={}
	local shiftx=vx-pos.x
	local shifty=vy-pos.y
	local sinr=sin(-rot)
	local cosr=cos(-rot)
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
--[[
 msx/msx=map space position
 wsx/wsy=world space position
 psx/psy=player space position
 ssx/ssy=screen space position
	size=screen space size
	type=the object's category
	 1=static
	 2=npc
	version=what obj within the category
]]--

staticdata={
--sprite,w,h,l1,d1,l2,d2,vd1,vd2
	{48,3,6,11,3,4,5,1,1}, --pinetree
	{56,2,2,13,5,7,6,1,13}, --rock
}

function genobjs()
	npcdata[1].upd=aikeepdistance
	npcdata[2].upd=aikeepdistance
	npcdata[3].upd=aiscared
	local num=0
	local objs={}
	for i=-1,1 do
		objs[i]={}
		for j=-1,1 do
			objs[i][j]=genobjsinmpos()
		end
	end
	return objs
end

function genobjsinmpos()
	local objs={}
	objs=spawnobjs(objs,3,1)
	objs=spawnobjs(objs,1,2)
	objs=spawnnpcs(objs,2,1)
	objs=spawnnpcs(objs,2,2)
	objs=spawnnpcs(objs,2,3)
	return objs
end

function spawnobjs (objs,num,ver)
	for k=1,num do
		local newobj={}
		newobj.msx=rnd(tsize)
		newobj.msy=rnd(tsize)
		newobj.type=1
		newobj.ver=ver
		objs[#objs+1]=newobj
	end
	return objs
end

function updateobjs(dir)
--dir 0=⬆️, 1=⬇️, 2=⬅️, 3=➡️
	if dir==0 then
		for i=-1,1 do
			objs[i][1]=objs[i][0]
			objs[i][0]=objs[i][-1]
			objs[i][-1]=genobjsinmpos()
		end
	elseif dir==1 then
		for i=-1,1 do
			objs[i][-1]=objs[i][0]
			objs[i][0]=objs[i][1]
			objs[i][1]=genobjsinmpos()
		end
	elseif dir==2 then
		for i=-1,1 do
			objs[1][i]=objs[0][i]
			objs[0][i]=objs[-1][i]
			objs[-1][i]=genobjsinmpos()
		end
	elseif dir==3 then
		for i=-1,1 do
			objs[-1][i]=objs[0][i]
			objs[0][i]=objs[1][i]
			objs[1][i]=genobjsinmpos()
		end
	end
end

function getvisobjs()
	local vobjs={}
	for i=-1,1 do
		for j=-1,1 do
			for k,v in pairs(objs[i][j]) do
				local newcoords=trnsfmpoint(v.wx,v.wy)
				if newcoords.y>0 and newcoords.y<objdrawdist then
					v.psx=newcoords.x
					v.psy=newcoords.y
					v.ssx=64+v.psx/v.psy*80
					if v.ssx>0 and v.ssx<128 then
						vobjs[#vobjs+1]=v
					end
				end
			end
		end
	end
	return vobjs
end

function drawobjs(vobjs)
	local prot=(rot-0.25)%1
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
		local data=npcdata[obj.ver]
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
		local data=staticdata[obj.ver]
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

function draworthops(vobjs)
	--cls()
	local llngth=5
	line(64,64,64,64-llngth,8)
	pset(64,64,1)
	
	local length=#vobjs
	for i=0,length-1 do
		local v=vobjs[length-i]
		v.pixelx=(v.psx)/tsize*32+64
		v.pixely=(-v.psy)/tsize*32+64
		rect(v.pixelx-1,v.pixely-1,v.pixelx+1,v.pixely+1,0)
		pset(v.pixelx,v.pixely,v.type*3+v.ver)
	end
end

function draworthows(vobjs)
	--cls()
	local llngth=-5
	local lendx=64+sin(rot)*llngth
	local lendy=64+cos(rot)*llngth
	line(64,64,lendx,lendy,8)
	pset(64,64,8)
	local length=#vobjs
	for i=0,length-1 do
		local v=vobjs[length-i]
		pixelx=(v.wx-pos.x)/tsize*32+64
		pixely=(v.wy-pos.y)/tsize*32+64
		rect(pixelx-1,pixely-1,pixelx+1,pixely+1,0)
		pset(pixelx,pixely,v.type*3+v.ver)
	end
	
	local pmposx=(pos.x/tsize)%wsize
	local pmposy=(pos.y/tsize)%wsize
			
	local xflr=pos.x-flr(pmposx)*tsize
	local xcel=pos.x-ceil(pmposx)*tsize
	local yflr=pos.y-flr(pmposy)*tsize
	local ycel=pos.y-ceil(pmposy)*tsize
	
	local ⬆️⬅️={}
	⬆️⬅️.x=(tsize-pos.x)/tsize*32+64
	⬆️⬅️.y=(tsize-pos.y)/tsize*32+64
	local ⬇️➡️={}
	⬇️➡️.x=-pos.x/tsize*32+64
	⬇️➡️.y=-pos.y/tsize*32+64
	rect(⬆️⬅️.x,⬆️⬅️.y,⬇️➡️.x,⬇️➡️.y,0)
end


-->8
--npcs
--[[
	dx/dy=current movement vector
	state=current state
		1=neutral
		2=running
]]--

npcdata={
--sprite,w,h,maxspd
	{64,1,1,1}, --orc
	{72,1,1,1}, --goblin
	{88,1,1,2}, --boar
}

function spawnnpcs (objs,num,ver)
	for k=1,num do
		local newobj={}
		newobj.msx=rnd(tsize)
		newobj.msy=rnd(tsize)
		newobj.type=2
		newobj.ver=ver
		newobj.dx=0
		newobj.dy=0
		objs[#objs+1]=newobj
	end
	return objs
end

function updatenpcs()
	local pposx=pos.x
	local pposy=pos.y
	local pmposx=flr((pposx/tsize))
	local pmposy=flr((pposy/tsize))
	for i=-1,1 do
		local mposx=((pmposx+i))*tsize
		for j=-1,1 do
			local mposy=((pmposy+j))*tsize
			for k,v in pairs(objs[i][j]) do
				v.wx=v.msx+mposx
				v.wy=v.msy+mposy
				if v.type==2 then
					npcdata[v.ver].upd(v)
				end
			end
		end
	end
end

function wander(v)
	local mxspd=0.1*npcdata[v.ver][4]
	local xrnd=rnd(0.2)-0.1
	v.dx=min(v.dx+xrnd,mxspd)
	local yrnd=rnd(0.2)-0.1
	v.dy=min(v.dy+yrnd,mxspd)
end

function move(v)
	v.msx-=v.dx
	v.msy-=v.dy
end

function aiscared(v)
	wander(v)
	local vx=pos.x-v.wx
	local vy=pos.y-v.wy
	v.dist=sqrt(vx*0x.0001*vx+vy*0x.0001*vy)*0x100
	if v.dist<50 then
		v.dx=vx/v.dist*npcdata[v.ver][4]
		v.dy=vy/v.dist*npcdata[v.ver][4]
	end
	move(v)
end

function aikeepdistance(v)
	wander(v)
end
-->8
--buildings
verts={
	{x=0,y=0},
	{x=0,y=100},
	{x=100,y=100},
	{x=100,y=0}
}

walls={
	{1,2},
	{2,3},
	{3,4},
	{4,1},
}

building={}

function initbuilding()
	building.x=10
	building.y=10
end

function getclippedv(v,dx,dy,clpdst,height)
	local newv={}
	newv.wx=v.wx
	newv.wy=v.wy
	newv.type=2
	newv.ver=2
	newv.psx=v.psx+dx*(clpdst-v.psy)/dy
	newv.psy=clpdst
	newv.size=1/newv.psy
	newv.ssx=64+newv.psx/newv.psy*80
	newv.ssy=(pos.z-height)/newv.psy*hscale+64
	return newv
end

function drawwall(v1,v2)
	for ssx=max(0,v1.ssx),min(128,v2.ssx) do
		local percent=(ssx-v1.ssx)/(v2.ssx-v1.ssx)
		local texpos=104+((percent*16)%8)
	 local x=lerp(percent,v1.wx,v2.wx)	 	
	 local y=lerp(percent,v1.wy,v2.wy)
		local bot=getheight(x,y)
		local psy=lerp(percent,v1.psy,v2.psy)
		local ssyb=(pos.z-bot)/psy*hscale+64
		local ssyt=lerp(percent,v1.ssy,v2.ssy)
		local size=2000*lerp(percent,v1.size,v2.size)
		--clip(0,0,128,ssyb)
		--line(ssx,ssyt,ssx,ssyb)
		sspr(texpos,0,1,8,ssx,ssyt,1,size)
		clip()
	end
	--wall top
	line(v1.ssx,v1.ssy,v2.ssx,v2.ssy,11)
	--wall ends
	line(v1.ssx,v1.ssy,v1.ssx,v1.ssy+v1.size,8)
	line(v2.ssx,v2.ssy,v2.ssx,v2.ssy+v2.size,8)
	local v1px=(v1.psx)/tsize*32+64
	local v1py=(-v1.psy)/tsize*32+64
	
	local v2px=(v2.psx)/tsize*32+64
	local v2py=(-v2.psy)/tsize*32+64
	
	line(v1px,v1py,v2px,v2py,9)
end	
	
function lerp(v,l,h)
	local val=(v*(h-l)+l)
	if val<0 then
		--stop()
	end
	return val
end
__gfx__
00000000400444040004444444440444000444444444044400027000001180001111116111111111000000601111111188000000445565550123456700000000
0000000064046949045549696969496904469696696949690002700001127800133331611111111103333060111111110dddd000445565550123456700000000
0070070096469696459495555554449649696444444555960023670001236780330301411b1b11113303004011111111dd0d0000446666660123456700000000
0007700069696969494959494696964956965696969949590023670001336780133737411bbbb11103373740111444410d373706446555650123456700000000
0007700044440044449595555569696555649544455494940134568012336680154451411b0b0161666450401554040105dd5060446555650123456700000000
0070070069694469064469699596945505554649969645540134568022345678144441311444461166644030555447470dddd300446666660123456700000000
000000009696969604694446645549450594555644455694124455782344566735555141b5555b11666550401555551135555000445565550123456700000000
0000000069696969049696944494949505494995996969640009f000234455671511514115115111050050401511151105005000445565550123456700000000
00000000000000000000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000007000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770007070770777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070070777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000077007777000777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000070700000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000007000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000077777777770000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000007000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070700000000007000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777077707000000000000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777070700007700777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777070007700777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07077777777070000077777007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707007777770007777770007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700077777777000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
1011121300101112130010111210111213303110111213001011121310111210111213001011101112131011121011101112132020212223202120212223000000000010111213111213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021222300202122101120212220101112404120212223002021222320212220212223002021202122232021101112132122233030313233303110111213001011121320212223212210111213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3010111210303132202130313230202122101130313210113031323310111213313210113031301011123031202122233132334040414210111213212223102021101130313233313220212223000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4020212220401011121340414240303132202140414220101011121310111213414220214041402021224041303132334142431010111220212223313233123031202140411011121330313233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0030313230312021222320401011121342303132330030201011121320212223000030314040413010111213404142431112132020212230313233414243224010111213102021222340414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010111213413031323330312021222300404142430040302021222330313233130040414243101120212223101112132122233030313240414243333031321020212223203031323311121300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020212223004041424340413031323300202122230000403031323340414243230000202122202130313233202122233132334040414243404142434041422030313210114041424321222300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0030313233000040414243004041424300303132330000004041424332303132330000303132303140414243303132334142430030313233000000303132333040414220212223433031323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0040414243000000000000000000000000404142430000000000404142404142430000404142404142430000404142430000000040414243000000404142434041424330313233004041424300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000303132330000000000000000000000000000000000000040414243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404142430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000700001761718627156170560700600006000860007600006100f6000d600076000e6000c6000b6000a60009600076000d6000c6000b6000a6000a6000c6000b6000c6000c6000e6000c6000a6000760007600
900700001a6101c620146201361000000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000f63709617056070260702600006000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
900700001c620156300f6200e62012620146100e6100d610006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000b0501e35022350273502d350313503235032350313502f3502d3502b350283502435021350213502035020350120501105011050130501505000000180501a0501d0501f05024050270502a0502b050
__music__
00 40424344

