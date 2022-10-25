pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--global
objs={}
parts={}
todel={}
mapdata={}
damagearea={}

--state
menucooldown=0
crafting=false

multiplayer=false
--[[
spell shapes:
	lob,bullet,spray,jump,sprint
spell types:
	fire,water,earth,poison
]]--

function _init()
	initstypes()
	initsshapes()
	initmapdata()
	initplayer(p,0)
	if multiplayer then
		initplayer(p2,1)
	end
end

function _update()
	menucooldown=max(menucooldown-1,0)
	if crafting then
		craftingupdate()
	else
		damagearea={}
		for k,v in pairs(parts) do
			v.update(v)
		end
		for k,v in pairs(objs) do
			v.update(v)
		end
		for k,v in pairs(todel) do
			del(objs,v)
			del(parts,v)
		end
		todel={}
	end
end

function _draw()
	cls()
	if crafting then
		craftingdraw()
	else
		local cam=getcampos(p,0)
		local sorted=sortobjs(cam)
		drawiso(cam,sorted)
		camera()
		drawmanabar(p,119,24)
		if multiplayer then
			line(0,64,128,64,5)
			clip(0,65,128,65)
			cam=getcampos(p2,-64)
			sorted=sortobjs(cam)
			drawiso(cam,sorted)
			camera()
			drawmanabar(p2,119,89)
			clip()
		end
	end
	--drawlogs()
end

function remaprnd(range)
	return rnd(range)-range/2
end

function normalise(x,y)
	local l=sqrt(x*x+y*y)
	return x/l,y/l
end

function drawlogs()
	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("memory=",0,12,7)
	print(stat(0),28,12,7)
end

function nill()

end

-->8
--player
p={}
p2={}

friction=0.8
stph=1
maxmana=5
manaregen=0.06

function initplayer(p,n)
	p.x=40
	p.y=25
	p.h=0
	p.w=0.1
	p.dx=0
	p.dy=0
	p.acc=0.04
	p.dh=0
	p.dirx=1
	p.diry=1
	p.mana=5
	p.hp=10
	p.maxhp=10
	p.update=updateplayer
	p.draw=drawperson
	p.playernum=n
	p.aiming=0
	p.enabled=true
	p.moving=true
	p.slot1={}
	p.slot2={}
	p.slot1.stype=stype[2]
	p.slot1.sshape=sshape[2]
	p.slot2.stype=stype[3]
	p.slot2.sshape=sshape[4]
	p.col={9,10,13,4,15}
	
	add(objs,p)
end

function updateplayer(obj)
	obj.mana=min(obj.mana+manaregen,maxmana)
	if not obj.enabled then
	printh("player disabled"..time())
	 return end
	local inpt=getinput(obj.playernum)
	obj.inpt=inpt
	if inpt.i1 and inpt.i2 then
		obj.aiming=0
		p.enabled=true
		p.moving=true
		initcrafting(obj)
		menucooldown=10
		return
	end
	if inpt.x !=0 or inpt.y !=0 then
	 obj.dirx=inpt.x
	 obj.diry=inpt.y
	end

	local spell={}	
	if obj.aiming==0 then
		if inpt.i1 then
			--weapon 1 pressed
			obj.aiming=1
			spell.sh=obj.slot1.sshape.press
			spell.slot=obj.slot1
		elseif inpt.i2 then
			--weapon 2 pressed
			obj.aiming=2
			spell.sh=obj.slot2.sshape.press
			spell.slot=obj.slot2
		end
	elseif obj.aiming==1 then
		if inpt.i1 then
			--weapon 1 held
			spell.sh=obj.slot1.sshape.hold
			spell.slot=obj.slot1
		else
			--weapon 1 released
			obj.aiming=0
			spell.sh=obj.slot1.sshape.release
			spell.slot=obj.slot1
		end
	elseif obj.aiming==2 then
		if inpt.i2 then
			--weapon 2 held
			spell.sh=obj.slot2.sshape.hold
			spell.slot=obj.slot2
		else
			--weapon 2 released
			obj.aiming=0
			spell.sh=obj.slot2.sshape.release
			spell.slot=obj.slot2
		end
	end
	if	spell.sh then
		spell.sh(obj,spell.slot)
	end

	
	if obj.moving then
		movement(obj,inpt)
	else
		obj.dx=0
		obj.dy=0
	end
end

function movement(obj,inpt)
	local tile=mget(obj.x%128,obj.y%64)
	if tile==11 then
		obj.dx+=inpt.x*obj.acc*0.2
		obj.dy+=inpt.y*acc*0.2
	elseif tile==6 then
		obj.dx+=inpt.x*obj.acc
		obj.dy+=inpt.y*obj.acc
		obj.dx*=friction*0.8
		obj.dy*=friction*0.8
		obj.inwater=true
	else
		obj.dx+=inpt.x*obj.acc
		obj.dy+=inpt.y*obj.acc
		obj.dx*=friction
		obj.dy*=friction
	end
	
	vcollidebox(obj)
	hcollidebox(obj)
	obj.x+=obj.dx
	obj.y+=obj.dy
end

function getinput(n)
	local inpt={}
	inpt.x=0
	inpt.y=0
	if menucooldown>0 then
		return inpt
	end
	if btn(0,n) then inpt.x-=1 inpt.y+=1 end
	if btn(1,n) then inpt.x+=1 inpt.y-=1 end
	if btn(2,n) then inpt.y-=1 inpt.x-=1 end
	if btn(3,n) then inpt.y+=1 inpt.x+=1	end
	
	inpt.i1=btn(4,n)
	inpt.i2=btn(5,n)
	
	if abs(inpt.y)==0 then
		inpt.x*=cos(0.125)
	elseif abs(inpt.x)==0 then
		inpt.y*=cos(0.125)
	end
	return inpt
end

-->8
--drawing
fill={
  0b1111111111111111,
  0b0111111111111111,
  0b0111111111011111,
  0b0101111111011111,
  0b0101111101011111,
  0b0101101101011111,
  0b0101101101011110,
  0b0101101001011110,
  0b0101101001011010,
  0b0001101001011010,
  0b0001101001001010,
  0b0000101001001010,
  0b0000101000001010,
  0b0000001000001010,
  0b0000001000001000,
  0b0000000000000000
}

function getcampos(p,offset)
	local cam={}
	cam.cartx=p.x
	cam.carty=p.y
	cam.x,cam.y=carttoiso(flr(cam.cartx)*8,flr(cam.carty)*8)
	local ofsx,ofsy=carttoiso((cam.cartx%1)*8,(cam.carty%1)*8)
	if multiplayer then
		cam.y+=32
		cam.toffsetx=cam.cartx-7
		cam.toffsety=cam.carty
	else
		cam.toffsetx=cam.cartx-11
		cam.toffsety=cam.carty-4
	end
	camera(ofsx,ofsy+offset)
	return cam
end

function sortobjs(cam)
	local sorted={}
	for j=-2,35 do
		sorted[j]={}
	end
	for k,v in pairs(parts) do
		sortobj(sorted,v,cam)
	end
	for k,v in pairs(objs) do
		sortobj(sorted,v,cam)
	end
	return sorted
end

function sortobj(sorted,v,cam)
	local x,y=carttoiso(v.x*8,v.y*8)
	v.ssx=64+x-cam.x
	v.ssy=64+y-cam.y
	
	local py=(flr(v.x)*8+flr(v.y)*8)/2
	local row=flr((py+64-cam.y)/4)-1
	add(sorted[row],v)
end

function drawiso(cam,sorted)
	local l=35
	if (multiplayer) l=19
	--0-32 onscreen,+edges
	for j=-2,l do
		--0-8 onscreen, +edges
		for i=-1,8 do
			drawmapsqr(i,j,cam)
		end
		for k,v in pairs(sorted[j]) do
			v.draw(v)
		end
	end
end

function drawmapsqr(i,j,cam)
	local shft=(j%2)/2
	local cx=flr(j/2+i-shft+cam.toffsetx)
	local cy=flr(j/2-i+shft+cam.toffsety)
	cx=cx%128
	cy=cy%64
	local sprite=mapmapping[mget(cx,cy)]
	local x=(i-(j%2)/2)*16
	local y=j*4
	local h=getmaph(cx,cy)/2
	if h==0 then
		spr(sprite,x+1,y+4,2,1)
	else
		local sprh=(fget(sprite)&0xf)/2
		local i=(h%sprh)
		while i<=h do
			local scrh=-8*i
			spr(sprite,x+1,y+4+scrh,2,1+sprh)
			i+=max(0.1,sprh)
		end
	end
	fillp()
end

function carttoiso(x,y)
	local isox=x-y
	local isoy=(x+y)/2
	return isox,isoy
end

function isotocart(x,y)
	local cartx=(2*y+x)/2
	local carty=(2*y-x)/2
	return cartx,carty
end

function drawperson(obj)
	palt(0,false)
	palt(1,true)
	pal(3,obj.col[1])
	pal(11,obj.col[2])
	pal(5,obj.col[3])
	pal(4,obj.col[4])
	pal(15,obj.col[5])
	local mod=time()*2%2
	local flp=false
	local idx=obj.dy-obj.dx
	local idy=-obj.dx-obj.dy
	--if moving up//down
	if (abs(idx)<abs(idy*0.5)) mod+=4
	--if moving up
	if (idy>0)	mod+=2
	--if moving left
	if (idx>0) flp=true
	local h=getmaph(obj.x,obj.y)
	local l=obj.ssx-3
	local t=obj.ssy-h*4-3
	ovalfill(l,t,l+5,t+3,1)
	obj.ssy=obj.ssy-obj.h*4
	if obj.inwater then
		obj.ssy+=1
		--manual camera offset
		clip(0,0,128,obj.ssy-2-peek2(0x5f2a))
	end
	spr(80+mod,obj.ssx-4,obj.ssy-8,1,1,flp,false)
	pal()
	local isvert=flr(mod/4)==1
	local isforw=idy>0
	drawhand(obj,isforw,isvert,1)
	drawhand(obj,isforw,isvert,-1)
	clip()
	line(obj.ssx-4,obj.ssy-11,obj.ssx+3,obj.ssy-11,2)
	line(obj.ssx-4,obj.ssy-11,obj.ssx-4+(obj.hp/obj.maxhp)*8,obj.ssy-11,8)
	obj.inwater=false
end

function drawhand(obj,isforw,isvert,hand)
	local m=1
	if (isforw) m=-1
	local vmod=0
	if (isvert) vmod=1
	local hx1=obj.ssx+(3+vmod)*m*hand-max(m*hand,0)
	local hy1=obj.ssy-3
	circ(hx1,hy1,1.5,0)
	pset(hx1,hy1,obj.col[5])
end

function drawproj(obj)
	local pd=obj.type
	local col=pd.col[1]
	local s=pd.ssize
	fillp(fill[pd.fill[1]]|0b.111)
	circfill(obj.ssx,obj.ssy-obj.h*4,s,col)
	fillp()
end

function drawdot(v)
	local pd=v.partdata
	local age=1-max(v.age/pd.age,0.01)
	local s=pd.ssize+pd.dsize*age
	local col=pd.col[flr(age*#pd.col)+1]
	fillp(fill[pd.fill[flr(age*#pd.fill)+1]]|0b.111)
	circfill(v.ssx,v.ssy-v.h*4,s,col)
	fillp()
end

function drawtarget(obj)
	spr(49,obj.ssx-4,obj.ssy-4-obj.h*4)
end

function drawmanabar(p,x,y)
	local h=20
	local percent=p.mana/maxmana
	rectfill(x+1,y-percent*h,x+5,y-2,1)
	for i=1,maxmana do
		if p.mana>=i then
			sspr(0,24,7,4,x,y-4*i)
		else
			sspr(0,28,7,4,x,y-4*i)
		end
	end
	sspr(0,27,5,1,x+1,y)
	sspr(0,27,7,1,x,y-h-1)
	sspr(2,27,5,1,x+1,y-h-2)
end

-->8
--enemies

function initenemy(x,y)
	local e={}
	e.x=x
	e.y=y
	e.h=getmaph(x,y)
	e.w=0.1
	e.dx=0
	e.dy=0
	e.acc=0.02
	e.dh=0
	e.hp=40
	e.maxhp=40
	e.curraction=echasing
	e.update=updateenemy
	e.draw=drawperson
	e.col={4,5,5,11,11}
	add(objs,e)
end

function updateenemy(obj)
	obj.hp-=getdamage(obj.x,obj.y)
	if obj.hp<=0 then
		obj.update=edead
		obj.draw=edeaddraw
		obj.bodytimer=time()+5
	end
	obj.curraction(obj)
end

function echasing(obj)
	local inpt={}
	inpt.x=(p.x-obj.x)
	inpt.y=(p.y-obj.y)
	inpt.x,inpt.y=normalise(inpt.x,inpt.y)
	inpt.x+=rnd(4)-2
	inpt.y+=rnd(4)-2
	movement(obj,inpt)
end

function edead(obj)
	if time()>obj.bodytimer then
		add(todel,obj)
	end
end

function edeaddraw(obj)
	palt(0,false)
	palt(1,true)
	pal(3,obj.col[1])
	pal(11,obj.col[2])
	pal(5,obj.col[3])
	pal(4,obj.col[4])
	pal(15,obj.col[5])
	local h=getmaph(obj.x,obj.y)
	local l=obj.ssx-3
	local t=obj.ssy-h*4-3
	ovalfill(l,t,l+5,t+3,1)
	fillp()
	
	spr(88,obj.ssx-4,obj.ssy-8-obj.h*4,1,1,flp,false)
	pal()
end
-->8
--types
function initstypes()
stype={
	{
		name="fire",
		i=1,
		cost=0,
		iconcol={10,9},
		col={10,10,9,8,2,5},
		fill={16,16,16,14,12,11},
		ssize=1.3,
		dsize=3,
		age=30,
		airres=0.7,
		grav=0.06,
		density=1,
		aliveappl=0.002,
		deadappl=0,
		tileupdate=fireupdate,
	},
	{
		name="earth",
		i=2,
		cost=0,
		iconcol={4,5},
		col={4},
		fill={16},
		ssize=2,
		dsize=0,
		age=30,
		airres=0.8,
		grav=-0.2,
		density=1,
		aliveappl=0,
		deadappl=0.5,
		tileupdate=earthupdate,
	},
	{
		name="water",
		i=3,
		cost=0,
		iconcol={12,1},
		col={12,12,1,12,1},
		fill={16,16,12,8,4},
		ssize=1.5,
		dsize=2,
		age=60,
		airres=0.8,
		grav=-0.2,
		density=1,
		aliveappl=0.02,
		deadappl=0.2,
		tileupdate=waterupdate,
	},
	{
		name="poison",
		i=4,
		cost=0,
		iconcol={14,2},
		col={14,2,14,2},
		fill={12,12,11,10,9,8,7,6},
		ssize=3,
		dsize=10,
		age=120,
		airres=0.8,
		grav=-0.01,
		density=0.3,
		aliveappl=0.01,
		deadappl=0,
		tileupdate=poisonupdate,
	},
	{
		name="ice",
		i=5,
		cost=0,
		iconcol={7,6},
		col={7,6,7,6,7,6,7,6,7,6,7,6},
		fill={6,7,8,9,10,12,15,15,15},
		ssize=1,
		dsize=1,
		age=40,
		airres=0.7,
		grav=-0.5,
		density=1,
		aliveappl=0.02,
		deadappl=0.2,
		tileupdate=iceupdate,
	}
}
end

function updatedot(v)
	local pd=v.partdata
	v.x+=v.dx
	v.y+=v.dy
	v.dx*=pd.airres
	v.dy*=pd.airres
	vcollidepoi(v)
	v.dh*=pd.airres
	v.dh+=pd.grav
	hcollidepoi(v)
	v.age-=1
	
	local fx=flr(v.x)%128
	local fy=flr(v.y)%64
	if pd.aliveappl>0 then
	 local vol=addtypstat(fx,fy,pd.i,pd.aliveappl)
		pd.tileupdate(fx,fy,vol)
	end
	if	v.age<=0 then
		if pd.deadappl>0 then
		 local vol=addtypstat(fx,fy,pd.i,pd.deadappl)
			pd.tileupdate(fx,fy,vol)
		end
		add(todel,v)
	else
	local x=flr(v.x)
	local y=flr(v.y)
	end
end

function	fireupdate(x,y,vol)
	adddamage(x,y)

	local tile=mget(x,y)
	if tile==11 then
		if vol==1 then
			msetandvol(x,y,6)
		end
	elseif tile==3 or tile==1 then
		if tile==3 and vol==1 then
			msetandvol(x,y,10)
		elseif tile==1 and vol==1 then
			msetandvol(x,y,12)
		else
			local sqr=mapdata[mpostoi(x,y)]
			if (not sqr.nextp) sqr.nextp=0
			if time()>sqr.nextp then
				local spawner={}
				spawner.x=x+0.5
				spawner.y=y+0.5
				spawner.h=0
				makepart(spawner,nil,0.3,stype[1])
				sqr.nextp=time()+0.1
			end
		end
	end
end

function earthupdate(x,y,vol)
	if (flr(rnd(10)%10)==0) initenemy(x,y)
	if vol==1 then
		if getmaph(x,y)==0 then
		 msetandvol(x,y,5)
		end
		if mget(x,y)==5 then
			mapdata[mpostoi(x,y)].h+=0.2
		end
	end
end

function	waterupdate(x,y,vol)
	if vol==1 then
		if getmaph(x,y)==0 then
		 msetandvol(x,y,6)
		else
			local sqr=mapdata[mpostoi(x,y)]
			sqr.h=max(sqr.h-0.2,0)
			sqr.vol=0
		end
	end
end

function	poisonupdate(x,y,vol)
	adddamage(x,y)
end

function	iceupdate(x,y,vol)
	adddamage(x,y)
	local tile=mget(x,y)
	if tile==6 then
		if vol==1 then
			msetandvol(x,y,11)
		end
	end
end
-->8
--shapes
function initsshapes()
sshape={
	{
		name="bullet",
		i=1,
		cost=2,
		spri=65,
		press=bullet,
	},
	{
		name="lob",
		i=2,
		cost=3,
		spri=66,
		press=initlob,
		release=lob,
	},
	{
		name="spray",
		i=3,
		cost=0.2,
		spri=64,
		press=initspray,
		hold=spray,
	},
	{
		name="jump",
		i=4,
		cost=4,
		spri=67,
		press=initlob,
		release=jump,
	},
	{
		name="sprint",
		i=5,
		cost=3,
		spri=68,
		press=sprint,
	},
	{
		name="fulminate",
		i=6,
		cost=3,
		spri=69,
		press=fulminate,
	},
	{
		name="ricochet",
		i=7,
		cost=2,
		spri=70,
		press=bounceproj,
	}
}
end

aimpart={
		name="aim",
		i=0,
		col={7},
		fill={16},
		ssize=0.5,
		dsize=0,
		age=1,
		airres=0,
		grav=0,
		density=1,
		aliveappl=0,
		deadappl=0,
}		

function getmanacost(stype,sshape)
 return stype.cost+sshape.cost
end

function paymanacost(p,slot)
	local cost=getmanacost(slot.stype,slot.sshape)
	if p.mana>cost then
		p.mana-=cost
		return false
	end
	p.aiming=0
	return true
end

function sprint(p,slot)
	if(paymanacost(p,slot))return
	p.enabled=false
	local dx=p.dirx*0.3+rnd(0.05)-0.025
	local dy=p.diry*0.3+rnd(0.05)-0.025
	proj=buildproj(p,slot.stype,dx,dy,0,0)
	proj.age=20
	proj.update=mvmtupdteproj
	proj.p=p
	add(objs,proj)
end

function bullet(p,slot)
	if(paymanacost(p,slot))return
	local dx=p.dirx*0.3+rnd(0.05)-0.025
	local dy=p.diry*0.3+rnd(0.05)-0.025
	proj=buildproj(p,slot.stype,dx,dy,0,0)
	add(objs,proj)
end


function bounceproj(p,slot)
	if(paymanacost(p,slot))return
	local dx=p.dirx*0.3+rnd(0.05)-0.025
	local dy=p.diry*0.3+rnd(0.05)-0.025
	proj=buildproj(p,slot.stype,dx,dy,0,0)
	proj.update=updtebounceproj
	add(objs,proj)
end

function initlob(p,slot)
	if(paymanacost(p,slot))return
	p.moving=false
	local target={}
	target.localx=0
	target.localy=0
	target.update=updatetarget
	target.draw=drawtarget
	target.p=p
	slot.target=target
	add(objs,target)
end

function updatetarget(obj)
	if crafting then
		add(todel,obj)
		return
	end
	local p=obj.p
	obj.localx+=p.inpt.x*0.015
	obj.localy+=p.inpt.y*0.015
	local maxrng=0.3
	obj.localx=min(max(obj.localx,-maxrng),maxrng)
	obj.localy=min(max(obj.localy,-maxrng),maxrng)
	local dx=obj.localx
	local dy=obj.localy
	local proj=buildproj(p,aimpart,dx,dy,1,-0.1)
	local hit=false
	while not hit do
		proj.x+=proj.dx
		proj.y+=proj.dy
		proj.h+=proj.dh
		proj.dh+=proj.grav
		makepart(proj,nil,0,aimpart)
		if solidfly(proj.x,proj.y,proj.h) then
			hit=true
		end
	end
	obj.x=proj.x
	obj.y=proj.y
	obj.h=getmaph(obj.x,obj.y)
end

function lob(p,slot)
	p.moving=true
	local dx=slot.target.localx
	local dy=slot.target.localy
	local proj=buildproj(p,slot.stype,dx,dy,1,-0.1)
	add(objs,proj)
	add(todel,slot.target)
	slot.target=nil
end

function jump(p,slot)
	p.moving=true
	p.enabled=false
	local dx=slot.target.localx
	local dy=slot.target.localy
	local proj=buildproj(p,slot.stype,dx,dy,1,-0.1)
	proj.update=mvmtupdteproj
	proj.p=p
	add(objs,proj)
	add(todel,slot.target)
	slot.target=nil
end

function initspray(p,slot)
	slot.nextpart=0
end

function spray(p,slot)
	if(paymanacost(p,slot))return
	local stype=slot.stype
	if slot.nextpart<=0 then
		slot.nextpart=1/stype.density
		for i=0,3 do
			local dir={}
			dir.x=p.dirx*0.5
			dir.y=p.diry*0.5
			dir.h=0
			makepart(p,dir,0.4,stype)
		end
	else
		slot.nextpart-=1
	end
end

function buildproj(p,stype,dx,dy,dh,grav)
	local proj={}
	proj.type=stype
	proj.x=p.x
	proj.y=p.y
	proj.h=p.h+1
	proj.dx=dx
	proj.dy=dy
	proj.dh=dh
	proj.grav=grav
	proj.update=updteproj
	proj.draw=drawproj
	proj.age=60
	proj.nextpart=0
	return proj
end

function mvmtupdteproj(obj)
	local p=obj.p
	local collide=updteproj(obj)
	p.x=obj.x
	p.y=obj.y
	p.h=obj.h
	if collide then
		p.dx=obj.dx
		p.dy=obj.dy
		p.enabled=true
		local h=getmaph(p.x,p.y)
		p.h=max(p.h,h)
	end
end

function fulminate(p,slot)
	if(paymanacost(p,slot))return
	local stype=slot.stype
	for i=0,100*stype.density do
		makepart(p,nil,2.5,stype)
	end
end

function updtebounceproj(obj)
	if solidfly(obj.x+obj.dx,obj.y,obj.h) then
		obj.dx=-obj.dx
	end
	if solidfly(obj.x,obj.y+obj.dy,obj.h) then
		obj.dy=-obj.dy
	end
	updteproj(obj)
end

function updteproj(obj)
	obj.x+=obj.dx
	obj.y+=obj.dy
	obj.h+=obj.dh
	obj.dh+=obj.grav
	obj.age-=1
	local stype=obj.type
	if obj.nextpart<=0 then
		obj.nextpart=1/stype.density
		makepart(obj,nil,0.3,stype)
	else
		obj.nextpart-=1
	end
	if solidfly(obj.x,obj.y,obj.h)
	or obj.age<=0 then
		for i=0,80*stype.density do
			makepart(obj,nil,1.5,stype)
		end
		add(todel,obj)
		return true
	end
	return false
end

function makepart(obj,dir,force,partdata)
		local n={}
		--properties
		n.x=obj.x
		n.y=obj.y
		n.h=obj.h
		n.dx=remaprnd(force)
		n.dy=remaprnd(force)
		n.dh=rnd(force)
		if dir then
			n.dx+=dir.x
			n.dy+=dir.y
			n.dh+=dir.h
		end
		n.age=partdata.age-rnd(partdata.age*0.3)
		n.partdata=partdata
		--functions
		n.update=updatedot
		n.draw=drawdot
		--add to objs
		add(parts,n)
end
-->8
--physics
--horizontal map collision of a box
function hcollidebox(p)
	local collided=false
	if solidarea(p.x+p.dx,p.y,p.w,p.h) then
		p.dx=0
		collided=true
	end
	if solidarea(p.x,p.y+p.dy,p.w,p.h) then
		p.dy=0
		collided=true
	end
	return collided
end

--horizontal map collision of a point
function hcollidepoi(p)
	local collided=false
	if solidfly(p.x+p.dx,p.y,p.h) then
		p.dx=0
		collided=true
	end
	if solidfly(p.x,p.y+p.dy,p.h) then
		p.dy=0
		collided=true
	end
	return collided
end

--vertical collision of a box
function vcollidebox(obj)
	local collided=false
	obj.dh-=0.1
	local x=obj.x
	local y=obj.y
	local w=obj.w
	local sqrh=max(
		max(
			getmaph(x+w,y+w),
			getmaph(x+w,y-w)),
		max(
			getmaph(x-w,y+w),
			getmaph(x-w,y-w))
		)
	if obj.h+obj.dh<sqrh then
		obj.dh=0
		collided=true
		if obj.h+stph>=sqrh then
			obj.h=min(sqrh,obj.h+0.5)
		end
	else
		obj.h=obj.h+obj.dh
	end
	return collided
end

--vertical collision of point
function vcollidepoi(obj)
	local h=getmaph(obj.x,obj.y)
	obj.h=max(obj.h+obj.dh,h)
end

function solidarea(x,y,w,h)
	return 
		solid(x-w,y-w,h) or
		solid(x+w,y-w,h) or
		solid(x-w,y+w,h) or
		solid(x+w,y+w,h)
end

function solid(x,y,h)
	local tileh=getmaph(x,y)
	return tileh>h+stph
end

function solidfly(x,y,h)
	local tileh=getmaph(x,y)
	return tileh>h
end
-->8
--map
mapmapping={38,36,26,24,44,22,36,36,36,34,16,40}
mapmapping[0]=24

function initmapdata()
	for i=0,128*64 do
		mapdata[i]={}
		mapdata[i].h=0
	end
end

function mpostoi(x,y)
	return x+y*128
end

function getmaph(x,y)
	local h=fget(mget(x%128,y%64))
	h+=mapdata[mpostoi(flr(x%128),flr(y%64))].h
	return h
end

function addtypstat(x,y,i,val)
	local sqr=mapdata[mpostoi(x,y)]
	if i!=sqr.type then
		sqr.vol=0
		sqr.type=i
	end
	sqr.vol=min(sqr.vol+val,1)
	return sqr.vol
end

function msetandvol(x,y,val)
	mset(x,y,val)
	mapdata[mpostoi(x,y)].vol=0
end

function adddamage(x,y)
	local i=mpostoi(x,y)
	if not damagearea[i] then
		damagearea[i]=0
	end
	damagearea[i]+=1
end

function getdamage(x,y)
	x=flr(x)
	y=flr(y)
	local i=mpostoi(x,y)
	if damagearea[i] then
		return damagearea[i]
	end
	return 0
end

-->8
--crafting
crftdata={}

function initcrafting(p)
	crafting=true
	crftdata.p=p
	crftdata.sselected=p.slot1
	crftdata.rowselect=0
	crftdata.movcool=0
end

function craftingupdate()
	crftdata.movcool=max(crftdata.movcool-1,0)
	if menucooldown>0 then
		return
	end
	local pnum=crftdata.p.playernum
	if btn(4,pnum) and btn(5,pnum) then
		menucooldown=10
		crafting=false
	end
	if crftdata.movcool>0 then return end
	
	if btn(4,pnum) then
		crftdata.sselected=p.slot1
		crftdata.movcool=5
	elseif btn(5,pnum) then
		crftdata.sselected=p.slot2
		crftdata.movcool=5
	end
	
 local scrollx=0
 local scrolly=0
 if btn(0,pnum) then scrollx-=1 end
 if btn(1,pnum) then scrollx+=1 end
 if btn(2,pnum) then scrolly+=1 end
 if btn(3,pnum) then scrolly-=1 end
 if scrolly!=0 then
		crftdata.rowselect=(crftdata.rowselect+scrolly)%2
 	crftdata.movcool=5
 end
 if scrollx!=0 then
 	crftdata.movcool=5
 	if crftdata.rowselect==0 then
	 	local curr=crftdata.sselected.stype.i
	 	local l=#stype
 		crftdata.sselected.stype=stype[(curr+scrollx-1)%l+1]
 	elseif crftdata.rowselect==1 then
	 	local curr=crftdata.sselected.sshape.i
	 	local l=#sshape
 		crftdata.sselected.sshape=sshape[(curr+scrollx-1)%l+1]
 	elseif crftdata.rowselect==2 then
 	
 	end
 	crftdata.sselected.type=crftdata.seltype
 	crftdata.sselected.shape=crftdata.selshape
 end
end

function craftingdraw()
	print("spell crafting",35,1,13)
	
	drawbigspells()	
	drawsection("type:"..crftdata.sselected.stype.name,7,0,stype)
	drawsection("shape:"..crftdata.sselected.sshape.name,49,1,sshape)
	drawsection("modifier:",91,2,nil)
end

function drawbigspells()	
	local p=crftdata.p
	drawspell(2,37,p.slot1.sshape,p.slot1.stype,true)
	drawspell(2,91,p.slot2.sshape,p.slot2.stype,true)

	if crftdata.sselected==p.slot1 then
		dotrect(1,36,20,56,7)
	else
		dotrect(1,90,20,110,7)
	end
end

function drawsection(title,y,i,list)
	rect(23,y,127,y+42,5)
	print(title,25,y+2,13)
	local j=0
	for k,v in pairs(list) do
		lx=25+j*11
		ly=y+9
		if i==0 then
			drawspell(lx,ly,crftdata.sselected.sshape,v,false)
		elseif i==1 then
			drawspell(lx,ly,v,crftdata.sselected.stype,false)
		end
		if v==crftdata.sselected.stype or v==crftdata.sselected.sshape then
			if	crftdata.rowselect==i then
				dotrect(lx-1,ly-1,lx+10,ly+10,8)
			else
				dotrect(lx-1,ly-1,lx+10,ly+10,7)
			end
		end
		j+=1
	end
end

function drawspell(x,y,sshape,stype,big)
	palt(0,false)
	pal(7,stype.iconcol[1])
	pal(6,stype.iconcol[2])
	if big then
		rect(x,y,x+17,y+17,0)
		sx,sy=(sshape.spri%16)*8,(sshape.spri\16)*8
		sspr(sx,sy,8,8,x+1,y+1,16,16)
		for i=1,getmanacost(stype,sshape) do
			circfill(x+4*i-3,y+23,1.5,12)
		end
	else
		rect(x,y,x+9,y+9,0)
		spr(sshape.spri,x+1,y+1)
	end
	pal()
end

function dotrect(x1,y1,x2,y2,col)
	if flr(time()*2%2)==0 then
		fillp(fill[9])
	else
		fillp(~fill[9])
	end
	rect(x1,y1,x2,y2,col)
	fillp()
end
__gfx__
00000000000880006555655500033000333333334444444411111111d555d555755575556ddd6ddd00000000cccc7ccc00000000000000000000000000000000
00000000008888006555655500033000333333334444444411111111d555d555755575556ddd6ddd05000550cc7ccc7c00055000000000000000000000000000
00700700088888806666666600333300333333334444444411111111dddddddd777777776666666600505000cccccccc00500500000000000000000000000000
0007700088888888556555650033330033333333444444441111111155d555d555755575dd6ddd6d00050000c7c7cc7c05000050000000000000000000000000
0007700088888888556555650333333033333333444444441111111155d555d555755575dd6ddd6d55055000cccccccc50000005000000000000000000000000
007007000ffffff06666666603333330333333334444444411111111dddddddd7777777766666666005550507ccc7ccc05000050000000000000000000000000
000000000ff44ff06555655533333333333333334444444411111111d555d555755575556ddd6ddd00055500cccccc7c05000050000000000000000000000000
000000000ff44ff06555655500044000333333334444444411111111d555d555755575556ddd6ddd00055000ccc7cccc05000050000000000000000000000000
0000000cc000000000000000000000000000000000000000000000011000000000000003300000000000001b1000000000000000000000000000000000000000
00000cc66cc0000000000000000000000000000000000000000001111110000000b003b33330000000000133b100000000000000000000000000000000000000
000cc66cc6c6c00000000000000000000000000000000000000111cc1111c0000003333333333000000013333b10000000000000000000000000000000000000
0ccc66cc6c6c6cc000000000000000000000000000000000011cc111cc111110033353533b3333b0000013bb3b10000000000000000000000000000000000000
06c6cc66cc6cc6c00000000000000000000000000000000001c11c11111111100333333333b35330000133333bb1000000000000000000000000000000000000
000cc6ccc6c6c000000000000000000000000000000000000001111ccc1c10000003b3333333300000001133b310000000000000000000000000000000000000
00000c6c6cc0000000000000000000000000000000000000000001111110000000000333333000000001331333b1000000000000000000000000000000000000
00000006600000000000000000000000000000000000000000000001100000000000000330000000001333333b3b100000000000000000000000000000000000
00000000000000000000001041000000000000066000000000001100000000000000000000000000000113313333b10000000005500000000000000000000000
000000000000000000000141510000000000066d666000000001851100000000000011000000000000133133333b3b1000000594495000000000000000000000
00000000000000000000001510000000000666666666600000018585110000000001450110000000013333333bb3110000054449444450000000000000000000
0000000000000000000111544100000006666d66666d6660001858858511000000151115510000000013333bb33bb10005494444449444500000000000000000
0000000000000000001555141000000066666666d6666d66001858588585100000141001510000000133333333333b1004444944944944900000000000000000
00000000000000000001141511000000d66d66666666666d018588585885810001510015411100001333b333333333b101944444444449400000000000000000
000000000000000000100115141000005d16666d6d6666d5018585885858881001510015144501000133333333333b1001515494449454400000000000000000
000000000000000001510015411000005515d666666dd65518588585885888811510001501411510031133b3bb3333b101151514954545400000000000000000
4dcc7ca000000000015110141141000015155d1666d5d6561858588585888888155110151141015113333333333333b101515151545454400000000000000000
9dcccc90000000000015411545100000d1155515d65556661188585885888841141445555541004101113133333b111001151515454545400000000000000000
955ddd9070000007000155141155500055d11515d6566dd615f188585888ff41141514455154504100031353b311300001515151545454400000000000000000
4499aaa00770077005551144155554505551d1155666d5d615dfd18858ff4f411451455414455f41033315554133333001551515454545400000000000000000
400070a0000770000454514454545550055155d16dd655d005fdfdf18ff44f4015f5451545514f51033335444333b33001515151545454400000000000000000
9000009007700770000455545555500000015551d5d65000000fdfd54ff44000000f555541545000000333543333300000051515454540000000000000000000
90000090700000070000045554500000000005515550000000000df54ff0000000000df54ff00000000003333330000000000151545000000000000000000000
4499aaa0000000000000000550000000000000015000000000000005400000000000000550000000000000033000000000000005500000000000000000000000
00000077000000000000000000000000000000000000000000777000000000000000000000000000000000000000000011100111111111111110111111111111
00007766000000000006700000000000000000000000000000700000000000000000000000000000000000000000000011044011111001111104011111101111
007766660000000000700600000600000000000000077000007070000000000000000000000000000000000000000000104ff011110440111044f01111040111
76666666000660700600007000000607000000700776677000000600000000000000000000000000000000000000000010bf3011104ff0111053f0111054f011
76666666660007770700006006000007606060777660066700000070000000000000000000000000000000000000000010535f0110bf3f010f35b0110f35b011
0077666600060070600000070000077700000070077667700000060000000000000000000000000000000000000000001035301110535011103b3011103b3011
0000776600000000700000066000000000000000000770000070700000000000000000000000000000000000000000000f3330110f35301110333f0110333f01
00000077000000000000000000000000000000000000000000060000000000000000000000000000000000000000000010300011103000111100301111003011
11100111111111111110111111111111111001111111111111100111111111111111111100000000000000000000000011100111111111111110011111111111
11044011111001111104011111101111110440111110011111044011111001111111111100000000000000000000000010044001111001111004400111100111
104ff011110440111044f01111040111103ff301110440111034430111044011111111110000000000000000000000000b3ff3b0100440010b3443b010044001
103f3011104ff0111053f0111054f01110533501103ff301105335011034430110000011000000000000000000000000035335300b3ff3b0035335300b3443b0
10535011103f301110353011103530111055550110533501103bb30110533501030335010000000000000000000000000f5555f0035335300f3bb3f003533530
1035301110535011103b3011103b3011103333011055550110333301103bb30110335340000000000000000000000000103333010f5555f0103333010f3bb3f0
103330111035301110333011103330111030030110300301103003011030030118083f4000000000000000000000000010300301103003011030030110300301
10300011103001111100301111003011100110011001100110011001100110018188008100000000000000000000000010011001100110011001100110011001
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
40404040404040404040404040404040304040403040404040404040404030404040404040404040404040404040404040404040404040604040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404030404040403040404040404040404040404040404040404040404040304040404040403040404040304040404060604040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404060404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040304040404040406060404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404040404030404040404040404040404040404040404040606040404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404030404040404040404040404040404040404040404040406060604040404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040406060606040404040404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404040404060606060606060606060606060606040404040404040404040404040404040
40404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404040404060606060404040404040404040404040404040404000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040404040404040404040404060606060604040404040404040404040404040404040404000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000606060600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000060606060606060606060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
6666d6666d66541858588585149555fdfdf18ff44f4555fdfdf18ff41145555155d115155d166666666615155d1666d5d65633b353333333333333b353333333
66666666666d4185885858858194495fdfd54ff44594495fdfd54ff1851149515551d1155515d66d6666d1155515d655566633b333b33333b33333b333b33333
666d6d6666d5418585885858881944445df54ff5444944445df54ff185851144555155d115155d16666d55d11515d6566dd63333333333333333333399aaa333
6666666dd655185885858858888144944455454944444494445545185885851144515551d1155515d6665551d1155666d5d6333353533b3333b33334499aaa33
6d6666d5d65618585885858888889449119554444944944944955418585885851495555155d115155d16655155d16dd655d63333333333b353333334dcc7cab3
666dd65556661188585885888841444185114954444444444594418588585885819449515551d1155515d6615551d5d6566d3333b33333b333b33339dcccc9b3
66d5d6566dd615f188585888ff4144918585114454944495444941858588585888194444555155d115155d166551555666d53333333333333333333955ddd933
d6555666d5d615dfd18858ff4f419518588585114454954944441858858588588885459444515551d1155515d661566dd6553b3333b3333353533b34499aaa33
d6566dd655d665fdfdf18ff44f45541858588585149554444944185858858588885855594495555155d115155d1666d5d65633b353333333333333b4dcc7ca33
5666d5d6566d666fdfd54ff4459441858858588581944954444411885858858885454545459449515551d115566d6665566633b333b33333b33333b9dcccc933
6dd65556666666666df54ff5444941858588585888194444549415f188585888ff55545544494444555155d6666666666dd63333333333333333333955ddd933
d5d656666d66666d66654549444418588585885888814494445415dfd18858ff4545954544444494445156666d66666d6666333353533b3333b33334499aaa33
55d666666666d6666d665444494418585885858888889449119555fdfdf18ff44f55555449449449449566666666d6666d663333333333b353333334dcc7cab3
566d666d66666666666d49544444118858588588884144418511495fdfd54ff445954554444444444594d66d66666666666d3333b33333b333b33339dcccc9b3
66666666666d6d6666d54444549415f188585888ff414491858511445df54f55545554445494449544495d16666d6d6666d53333333333333333333955ddd933
6d66666d6666666dd6554494445415dfd18858ff4f4195185885851144554545454545944454954944445515d666666dd6553b3333b3333353533b34499aaa33
6666d6666d6666d5d6569449449555fdfdf18ff44f45541858588585149555545554555944955444494415155d1666d5d65633b353333333333333b4dcc7ca33
66666666666dd655566644444594495fdfd54ff445944185885858858194455545454544459449544444d115566d6665566633b333b33333b33333b9dcccc933
666d6d6666d5d6566dd64495444944445df54ff54449418585885858881954555455588844494444549455d6666666666dd63333333333333333333955ddd933
6666666dd6555666d5d6954944444494445545494444185885858858888145954555984844444494445456666d66666d6666333353533b3333b33334499aaa33
6d6666d5d6566dd655d5544449449449449554444944185858858588888894595495888889449449449566666666d6666d663333333333b353333334dcc7cab3
666dd655566d666655944954444444444594495444441188585885888841444445948858844444444594d66d66666666666d3333b33333b333b33339dcccc9b3
66d5d65666666666644944445494449544494444549415f188585888ff414495444948885494449544495d16666d6d6666d53333333333333333333955ddd933
d65556666d66666d666444944454954944444494445415dfd18858ff4f419549444444944454954944445515d666666dd6553b3333b3333353533b34499aaa33
d65666666666d6666d6694491195544449449449449555fdfdf18ff44f4554499944944944955444494415155d1666d5d65633b353333333333333b34499a331
566d666d66666666666d444185114954444444444594495fdfd54ff44594499999944444459449544444d115566d6665566633b333b33333b333333331111113
66666666666d6d6666d544918585114454944495444944445df54ff5444944999994449544494444549455d6666666666dd63333333333333333333111cc1111
6d66666d6666666dd655951858858511445495494444449444554549444444999994954944444494445456666d66666d6666333353533b3333b3311cc111cc13
6666d6666d6666d5d6555418585885851495544449449449449554444944944999a5544449449449449566666666d6666d663333333333b3533111c11c111111
66666666666dd6555594418588585885819449544444444445944954444444418aaa4954444444444594d66d66666666666d3333b333333331111111111ccc13
666d6d6666d5d65544494185858858588819444454944495444944445494449185a511445494449544495d16666d6d6666d533333333333111cc1111c1111133
6666666dd6555549444518588585885888814494445495494444449444549518588a85114454954944445515d666666dd6553b3333b3311cc111cc1111111313
6d6666d5d655544455545558588585888888944944955444494494494495541858aaa58514955444494415155d1666d5d65633b3533331c11c11111111111133
666dd65555944954454515885858858888414444459449544444444445944185885a5885819449544444d1155512d655566633b333b33331111ccc1c11111333
66d5d655444944455455555588585888ff4144954449444454944495444941858588585888194444549455d1152226566dd63333333333333111111111cc1133
d655554944444495455515d5d18858ff4f419549444444944454954944441858858588588881449444545551d2125266d5d6333353533b3333b1111cc111c311
16555444494494495555555dfdf18ff44f4554444944944944955444494418585885858888889449449665515222222655d63333333333b3533111c11c111333
81944954444444444595455fdfd54ff4459449544444444445944954444411885858858888414444466d65655552d2d6566d3333b333333331111111111cc111
8819444454944495545554545df54ff5444944445494449544494444549415f188585888ff414496666656555552255666d533333333333111cc1111c1111113
88814494445495454545449444554549444444944454954944444494445415dfd18858f24f4196666d6665656562566dd6553b3333b3311cc112c21111111333
88889449449554545222544944955444494494494495544449449449449555fdfdf182222246666666665556555666d5d65633b3533331c11c222221111b1333
884144444594495542424444459449544444444445944954444444444594495fdfd542f2426d666d66666565656dd255566633b333b333311212c2121133b113
ff414495444944522422249544494444549444954449444454944495444944445df52f2226266666666d6d5556d226226dd63333333333322122212213333b11
4f41954944444492425292494444449444549549444444944454954544444494445542626266666d6666666dd6525262d5d6333353533b3232b2121213bb3b11
1145544449449442222222244944944944955444494494494495555455449449449662222266d6666d6666d5d629992225d33333333332222222222133333bb1
8511495444444444429242544444444445944954444444444595455545444444466d626262666666666dd6555699999253b33333b3333232321212111133b31c
858511445494449524222429999444954449444454944495445554555454449666662622262d6d6666d5d6566d9999923333535333333322aaa21111331333b1
58858511445495494242429999949549444444944454954944454595455496666d6662686866666dd6555666d59999999955353533b3311aaaaacc1333333b3b
58588585149554444922249999955444494494494495544449545559555566666666d288888886d5d6566dd65519999998885553533111caaaaa111113313331
885858858194495444444499999449544444444445944954444545454594d66d66666868886888555666d5b65999b199889888353111111aaaaacc133133333b
8588585888194444549449999949444454944495444944445455545554555d16666d6888888888866dd6555399999b988888888851cc1118aaa8113333333bb1
858588588881449444aaa9999944449444549549444444944555954545455515d6666868d8585866d5d6533399999b1898b83818c111cc1818181313333bb313
58858588888894491aaaaa9999449449449664444944944945565554555415155d1666888888888655d3333199999bb8888888888c1111188888113333333331
58588588884144418aaaaa9994444444466d666444444444456565654544d1155515d658886888b653b333331999b31388188818811cccbc88399933b3333313
88585888ff4144918aaaaaa454944496666666666494449666555655549455d11515d6599988855333333331331333b188888888c11111131a99999333333133
d18858ff4f41951858aaaaa1445496666d66666d666496666d65656566645551d11556999996533353533b1333333b3baaa8c81111111333aaa9999133b3bb13
fdf18ff44f45541858aaaaa5149566666666d6666d666666666655566d88855155d16d99999b1399933333b11331333aaaaa8881111333313a999991331b1133
dfd54ff445944185885aaa858194d66d66666666666d666d66666666686888510551d5999993b999993333133133333aaaaa88bc13b33333113999113133b133
5df54ff5444941858588585888195d16666d6d6666d56666666d6d668888899940515559993339999933313333333bbaaaaa811333333331331333b113333b13
44554549444418588585885888815515d666666dd655666d6666666dd85899999d01533313bb399999b33113333bb33baaa1133353533b1333333b3b13bb3b11
449664444944185858866588888815155d1666d5d656d6666d6666d5888899999905533133333b9993311133333333333baaa333333333b11331333133333bb1
466d666444441188566d66688841d1155515d65556666666666dd6999868999990f049531133b31331111333b33333333aaaaa33b33333133133333b1133b311
66666666649415f6666666666f4155d11515d6566dd66d6666d5d9999988899999094441331333b111cc1133333333331aaaaa133333313333333bb1331333b1
6d66666d666416666d66666d66615551d1155666d5d6666dd655599999d691999014441333333b3b1111c31133b3bb331aaaaa1333b33313333bb31333333b3b
6666d6666d6666666666d6666d66655155d16dd655d666d5d6566999991b19999944944113313333b11113333333333133aaabb1533331333333333113313333
66666666666dd66d66666666666dd6615551d5d6566dd6555666d5999133b999994444133133333b3b1cc1113133333b1133b31333b31333b33333133133333b
666d6d6666d55d16666d6d6666d55d166551555666d5d6566dd655531a3339999994413333333bb3111111131353b311331333b1333331333333313333333bb3
d666666dd6555515d666666dd6555515d661566dd6555666d5d65333aaab3b9993b49513333bb33bb15113331555411333333b3b1353331133b3bb13333bb33b
5d1666d5d65615155d1666d5d65615155d1666d5d6566dd655d333313a333bb1531b1133333333333b1553333544433113313333b13313333333313333333333
5515d6555666d1155515d6555666d1155515d6555666d5b653b333331133b3133133b133b333333333b14953335433133133333b3b13311131331333b3333333
1515d6566dd655d11515d6566dd655d11515d6566dd6555333333331331333b113333b13333333333b1944445333313333333bb3113333331353b13333333333
d1155666d5d65551d1155666d5d65551d1155666d5d6533353533b1333333b3b13bb3b1133b3bb3333b1449444533313333bb33bb1b333331555431133b3bb33
55d16dd655d3355155d16dd655d3355155d16dd655d33333333333b11331333133333bb13333333333b19449441b1133333333333b1333333544133333333331
5551d5b653b333315551d5b653b333315551d5b653b33333b33333133133333b1133b3113133333b111444444133b133b333333333b13333335431113133333b
3551555333333333355155533333333335515553333333333333313333333bb1331333b11353b3113494449513333b13333333333b133333333333331353b311
33b1533353533b3333b1533353533b3333b1533353533b3333b33113333bb31333333b3b155541333334954913bb3b1133b3bb3333b13b3333b3333315554113
53333333333333b353333333333333b353333333333333b3531b11333333333113313333b1444333b31b144133333bb13333333333b133b3531b133335444331
33b33333b33333b333b33333b33333b333b33333b33333333133b133b33333133133333b3b1433333133b1541133b3113133333b111333b33133b13333543313
33333333333333333333333333333333333333333333333113333b133333313333333bb31133333513333b11331333b11353b3113333333313333b1333333133
53533b3333b3333353533b3333b3333353533b3333b3311c13bb3b1133b3bb13333bb33bb1b3354913bb3b1333333b3b155541333333333313bb3b1333b33313
333333b353311333333333b353311333333333b3533111c133333bb133333133333333333b13344133333bb113313333b1444333b333333133333bb153333133
b333333331111113b333333331111113b3333333311111111133b31131331333b333333333b133341133b3133133333b3b1433b333b333331133b31333b31333
c333333111cc1111c333333111cc1111c333333111cc1111331333b11353b133333333333b133331331333b133333bb31133333333333331331333b133333133
1113311cc111cc111113311cc111cc111113311cc111cc1333333b3b1555431133b3bb3333b13b1333333b3b133bb33bb153333353533b1333333b3b13533311
111111c11c111111111111c11c111111111111c11c11111113313333b14413333333333333b133b113313333b13333333b133333333333b113313333b1331333
11111111111ccc1c11111111111ccc1c11111111111ccc133133333b3b1431113133333b111333133133333b3b13333333b13333b33333133133333b3b133111
11cc1111c111111111cc1111c111111111cc1111c111113333333bb3113333331353b3113333313333333bb3113333333b1333333333313333333bb311333333
c111cc111111111cc111cc111111111cc111cc1111111313333bb33bb1b333331555413333333513333bb33bb1b3bb3333b13b3333b33313333bb33bb1b33333
1c111111111b11c11c111111111331c11c111111111b1133333333333b13333335444333b3355133333333333b13333333b133b3531b1133333333333b133333
111cccbc1133b131111cccbc13b33331111cccbc1133b133b333333333b133333354333335941333b333333333b1333b111333b33133b133b333333333b13333
3111111313333b1331111113333333333111111313333b13333333333b1333333333333544494133333333333b13b3113333333313333b13333333333b133333
33b1133313bb3b1333b1133353533b3333b1133313bb3b1133b3bb3333b13b3333b335494444431133b3bb3333b141333333333313bb3b1133b3bb3333b13b33
1333333133333bb153333333333333b35333333133333bb13333333333b133b353355444494413333333333333b14333b333333133333bb13333333333b133b3
81b333331133b31333b33333b33333b333b333331133b3113133333b1113333335944954444441113133333b111433b333b333331133b3113133333b111333b3
88133331331333b1333333333333333333333331331333b11353b3113333333544494444549444931353b3113333333333333331331333b11353b31133333333
88813b1333333b3b13533b3333b3333353533b1333333b3b15554133333335494444449444549333155541333333333353533b1333333b3b1555413333333333
888833b113313333b13333b353333333333333b113313333b1444333b3333444494494494495533335444333b3333333333333b113313333b1444333b3333331
884133133133333b3b1333b333b33333b33333133133333b3b1433b333b333344444444445944953335433b333b33333b33333133133333b3b1433b333b33333
ff41313333333bb311333333333333333333313333333bb31133333333333333349444954449444453333333333333333333313333333bb31133333333333331
4f413313333bb33bb1b3333353533b3333b33313333bb33bb1b3333353533b3333b49549444444944453333353533b3333b33313333bb33bb1b3333353533b13
4f433133333333333b133333333333b353333133333333333b133333333333b3533334444944944944955333333333b353333133333333333b1b1333333333b1
43b31333b333333333b13333b33333b333b31333b333333333b13333b33333b333b333344444444445944953b33333b333b31333b33333333133b133b3333313
33333133333333333b1333333333333333333133333333333b1333333333333333333333349444954449444453333333333331333333333313333b1333333133
5353331133b3bb3333b13b3333b333335353331133b3bb3333b13b3333b3333353533b3333b4954944444494445333335353331133b3bb3313bb3b1333b33313
333313333333333333b133b353333333333313333333333333b133b353333333333333b3533554444944944944933333333313333333333133333bb153333133
b33331113133333b111333b333b33333b33331113133333b111333b333b33333b333333335944954444444b443b33333b33331113133333b1133b31333b31333
333333331353b3113333333333333333333333331353b311333333333333333333333335444944445494449333333333333333331353b311331333b133333133
33b33333155541333333333353533b3333b33333155541333333333353533b3333b33549444444944454933353533b3333b333331555411333333b3b13533311
531b133335444333b3333333333333b35333333335444333b3333333333333b3533334444944944944955333333333b3533333333544433113313333b1331333
3133b133335433b333b33333b33333b333b33333335433b333b33333b33333b333b333344444444445944953b33333b333b33333335433133133333b3b133111
13333b133333333333333333333333333333333333333333333333333333333333333333349444954449444453333333333333333333313333333bb311333333
13bb3b1333b3333353533b3333b3333353533b3333b3333353533b3333b3333353533b3333b49549444444944453333353533b3333b33313333bb33bb1b33333
33333bb153333333333333b353333333333333b353333333333333b353333333333333b3533334444944944944955333333333b353333133333333333b133333
1133b31333b33333b33333b333b33333b33333b333b33333b33333b333b33333b33333b333b333344444444445944953b33333b333b31333b333333333b13333
331333b133333333333333333333333333333333333333333333333333333333333333333333333334944495444944445333333333333133333333333b133333
33333b3b13533b3333b3333353533b3333b3333353533b3333b3333353533b3333b3333353533b3333b4954944444494445333335353331133b3bb3333b13b33
13313333b13333b353333333333333b3531b1333333333b353333333333333b353333333333333b3533554444944944944955333333313333333333333b133b3
3133333b3b1333b333b33333b33333b33133b133b33333b333b33333b33333b333b33333b3333333359449544444444445944953b33331113133333b11133333
33333bb311333333333333333333333313333b133333333333333333333333333333333333333335444944445494449544494444533333331353b31133333335
333bb33bb1b3333353533b3333b3333313bb3b1333b3333353533b3333b3333353533b3333b33549444444944454954944444494445333331555413333333549
333333333b133333333333b35333333133333bb153333333333333b353333333333333b3533554444944944944933444494494494495533335444333b31b1444
b333333333b13333b33333b333b333331133b31333b33333b33333b333b33333b333333335944954444444b443b333344444444445944953335433333133b154
333333333b1333333333333333333331331333b13333333333333333333333333333333544494444549444933333333334944495444944445333333513333b14
33b3bb3333b13b3333b3333353533b1333333b3b13533b3333b3333353533b3333b33549444444944454933353533b3333b49549444444944453354913bb3b14
3333333333b133b353333333333333b113313333b13333b3531b1333333333b3533334444944944944955333333333b353366444494494494495544133333bb1
3133333b111333b333b33333b33333133133333b3b1333b33133b133b33333b333b333344444444445944953b33333b3366d666444444444459449541133b314
1353b31133333333333333333333313333333bb31133333313333b133333333333333333349444954449444453333336666666666494449544494441331333b1
155541333333333353533b3333b33313333bb33bb1b3333313bb3b1333b3333353533b3333b4954944444494445336666d66666d666495494444441333333b3b

__gff__
0002020400000001030402000202000000000000000000000000040402020000020002020200020002000404020202000000020200000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030100000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0404040409020202020202090404040604040404030403040403040403040404040404040404040404040404040404040404040606060606060606060604040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040205050501050505050204040606030404040404040404040404040304040403040404040404040404040404040404040406060606060606060404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404020505050105050105050502040406060404030403030404040304030404030404040404040404040404040404040404040406060606060606040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402050505050505050505050505020404060404040403040304040404040403040404040404040404040404040404040404040406060606060606040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0905050501050105010501050505050904060403030404040404040404030404040404040404040404040404040404040404040406060606060606040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050505050505050505050501050204060404040404030404030404040404030404040404040404040404040304040404040406060606060606040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050209090902050505050505050204060404030304040404040404040404040403040404040304040404040404030304040406060606060604040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050209090902070501050505050204060304040404030404010504030304040404040404040404040404040404040404040406060606060604040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050209090802070505050505050505050505030404040404050504040404030404040404040404040404040404040404040406060606040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050209090902070505050505050204060305050404030404040505040403040403040404040404040404040404040404040404060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0205050209090902050105050505050204060404050304040404030405040404040404040404040404040404040404040404040404060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0905050505050505050505010501050904060303050304040304040505040404040404040404040404040404040404040404040404060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0402050505010501050105050505020404060404050505040404030504040303040404040404030404030404040404040404040404060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404020505050505050505050502040406060403040405050505050504040404040404040404040404040404040404030404040406060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0604040205050105050501050204040606040404040404040504040404030404040404030304040404030404040404040404040406040404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0606040409020202020202090404060604040404030404040505040204040404040304040404040404040404040404040304040606040404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406040404040404040404040404060404040404040404040405040404020404040304040404040404040401050404040404060908020809040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406060606060606060604040406060401040304040404040405050504020304040404040401050404040404050404040404060804040408040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040406040404040606060606040404040404040404040404040504020404040404040404050403040404050404040404060204010402040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040404040404040404030403040505040404030301050404050401050505050401050404060804040408040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040404040404040404040404040404040404030404040404040305050504040404050404050404050404040404050404060908020809040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404030404030403040403040404040404040404040404040404040504040505050501050505050505050505050504060606060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040404040304030404040304040404040505050504010505050404040401050404010505050505060404040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040404040404030404040404040404040404040404040404040404040404040404040404050501040404050404040404040405060604040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404030404040404040403040304040403040403040404030404040404010505050401050404040404040405050604040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0403040404040404040404040404040304040404040404040404040404040404040404040404040404050505050404040105040404050604040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404030404040404040404040304040404040404040404040403040404040304040404040404010504040404040405040405050604040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404030404040404040404040304040404030404040404040304040404030404040404040404040404040405050405040606040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040403040404030404040404040404040404040404040404040404040404040304040404040404050505040406040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404030403040404040304040404030404040404040404040403040404040404040304040404040504040406060404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040403040404030404040404040304040404040404030404040404040404030404040404040404040404040406060404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040304040404040404040404040404040404040404040404040404040404040404040404040404040406040404040404040404040404040404040404040404040404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000857008500085000000012300157001570014700155002450015700157001570015700167001670016700167001670016700167001670016700167001670016700167001650016500000000000000000
001000003905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
