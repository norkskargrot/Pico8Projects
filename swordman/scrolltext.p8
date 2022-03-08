pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
colliders={}
atkcolliders={}
framecount=0
btnpress={}
dedcirc=0
txtscroll=0
currmsg=nil

camx,camy=0,0
camfx=26
camdir=-1
cammov=0

function _init()
	poke(0x5f2c,3)
	initenemies()
	loadroom(1)
	initplayer()
	initmapemitters(curroom)
	
	for i=0,5 do
		btnpress[i]=0
	end
end

function _update60()
	framecount+=1
	txtscroll+=0.15
	if currmsg then
		if (txtscroll>#currmsg) and btn(5) then
		 currmsg=nil
		end	
	end
	if p.hp<=0 then
		dedcirc=max(dedcirc-2,20)
		if (dedcirc==20 and btn(5)) run()
		return
	end
	
	atkcolliders={}
	initlightning()
	updbtnpress()
	p.update(p)
	for k,v in pairs(o) do
		v.update(v)
	end
	animatemap()
end

function _draw()
	if p.hp<=0 then
		dedscrndraw()
	else
		gamedraw()
	end
	--drawlogs()
	--drawgates()
	--drawcolliders()
end

function gamedraw()
	cls(14)
	gamecam()
	camera(camx,camy)
	map(0,0,0,0,curroom.w,curroom.h)
	for k,v in pairs(o) do
		v.draw(v)
	end
	p.draw(p)
	map(0,0,0,0,curroom.w,curroom.h,2)
	--draw ui
	camera()
	drwhp()
	if (currmsg) txtdraw(currmsg,14,true,0)
	camera(camx,camy)
end

function gamecam()
	--x-axis
	local px=p.x+p.w/2
	local a,b=6,16
	local gx=camx
	if px*camdir<(camx+camfx)*camdir-b then
		camfx=32+a*camdir
		camdir=-camdir
		cammov=0
	end
	if px*camdir>(camx+camfx)*camdir then
		gx=px-camfx
	end
	
	gx=clamp(gx,0,curroom.w*8-64)
	if cammov<1 and abs(gx-camx)>2 then
	 cammov+=0.006
		camx+=(gx-camx)*cammov
	else
		camx=gx
	end
	
	--[[
	camxfx=camx+32
	line(camxfx+a,0,camxfx+a,127,8)
	line(camxfx-a,0,camxfx-a,127,8)
	line(camxfx+a+b,0,camxfx+a+b,127,9)
	line(camxfx-a-b,0,camxfx-a-b,127,9)
	line(px,0,px,127,7)
	]]--
	
	--y-axis
	if isgrounded(p) or p.y-28>camy then
		local gy=clamp(p.y-28,0,curroom.h*8-64)
		camy+=(gy-camy)*0.04
	end
end

function dedscrndraw()
	if dedcirc>20 then
		local r=dedcirc
		local x=p.x+p.w/2
		local y=p.y+p.h/2
		circ(x,y,r,0)
		circ(x+1,y,r,0)
		circ(x,y+1,r,0)
		circ(x+1,y+1,r,0)
		txtscroll=0
	else
		camera()
		local y=txtdraw(p.dedmsg,7,false,9)
		if (txtscroll>#p.dedmsg+10) print("❎ retry",10,y+4,7)
		camera(camx,camy)
	end
end

function drawspriback(x,y,h,spri,flp)
	setpal(0)
	local camy=peek2(0x5f2a)
	clip(0,0,127,y+h+1-camy)
	spr(spri,x+1,y,1,1,flp,false)
	spr(spri,x-1,y,1,1,flp,false)
	spr(spri,x,y+1,1,1,flp,false)
	spr(spri,x,y-1,1,1,flp,false)
	resetpal()
	clip()
end

function physupd(p)
	local hit=false
	--slope handling
	if fget(mget((p.x+p.dx)/8,(p.y+p.h)/8),7) and p.dy>=0 then
		p.x+=p.dx
		local ymap=flr((p.y-1)/8)*8
		p.y=ymap+p.x%8
		if (abs(p.dx)>0.3) p.dx+=0.03
	elseif fget(mget((p.x+p.dx+p.w)/8,(p.y+p.h)/8),6) and p.dy>=0 then
		p.x+=p.dx
		local ymap=flr((p.y-1)/8)*8
		p.y=ymap+8-(p.x+p.w)%8
		if (abs(p.dx)>0.3) p.dx-=0.03
	else
		--x-axis collision
		for i=p.x+p.dx,p.x,-(p.dx/abs(p.dx)) do
			if (not solidarea(i,p.y,p.w,p.h)) then
				p.x=i
				break
			end
			p.dx=0
			hit=true
		end
	end
	if (not p.rolls) p.dx*=friction;

	--y-axis collision
	for i=p.y+p.dy,p.y,-(p.dy/abs(p.dy)) do
		if (not solidarea(p.x,i,p.w,p.h)) then
			p.y=i
			break
		end
		p.dy=0
		hit=true
	end
	
	--gravity
	if p.grav then
		--if in water
		if fget(getptile(p),2) then
			p.dy-=0.1
			p.dy*=0.75
		else
			p.dy+=gravity
		end
	else
		p.dy*=friction
	end
	--limit fall speed
	p.dy=min(p.dy,maxfallspd)
	
	--edge collision
	if (p.x<0) p.x,hit=0,true
	--if (p.y<0) p.y,hit=0,true
	local xmax=curroom.w*8-p.w
	local ymax=curroom.h*8-p.h
	if (p.x>xmax) p.x,hit=xmax,true
	if (p.y>ymax) p.y,hit=ymax,true
	return hit
end

function solidarea(x,y,w,h)
	if (issolid(x,y)) return true
	if (issolid(x+w,y)) return true
	if (issolid(x,y+h)) return true
	if (issolid(x+w,y+h)) return true
	return false
end

function issolid(x,y)
	local m=mget(x/8,y/8)
	--check for slopes
	if fget(m,7) then
		if (x%8-y%8<1) return true
		return false
	end
	if fget(m,6) then
		if (y%8+x%8>7) return true
		return false
	end
	--check objects
	for k,v in pairs(colliders) do
		local p={x=x,y=y}
		if (boxpointoverlap(p,v)) return true
	end
	
	--check for normal solid
	return fget(m,0)
end

function getptile(p)
	return mget((p.x+p.w/2)/8,(p.y+p.h/2)/8)
end

function isgrounded(p)
	if (issolid(p.x,p.y+p.h+4)) return true
	if (issolid(p.x+p.w,p.y+p.h+4)) return true
	return false
end

function txtdraw(s,col,bubble,offset)
	
	s=sub(s,txtscroll,txtscroll+12)
	local txth=7
	local y=4+(119-txth-offset)*pscrnhalf()
	local xmax=6+4*#s
	if bubble then
		rectfill(3,y+1,xmax+1,y+txth,6)
		line(4,y+txth+1,xmax,y+txth+1,6)
		line(4,y,xmax,y,7)
		line(3,y+1,3,y+txth,7)
		if (fin) then
			circfill(xmax-3,y+txth+7,4,7)
			circfill(xmax-3,y+txth+8,4,6)
			print("x",xmax-4,y+txth+6,col)
		end
	else
		rectfill(3,y,121,y+txth,0)
	end
	print(s,6-txtscroll%1*4,y+2,col)
	return y+txth
end

function setpal(col)
	for i=0,15 do
		pal(i,col)
	end
end

function pscrnhalf()
	if (peek2(0x5f2a)+p.y+p.h/2>64) return 0
	return 1
end

function resetpal()
	pal()
	pal(14,128,1)
	pal(3,131,1)
	pal(4,132,1)
	pal(11,133,1)
	pal(13,134,1)
	pal(12,140,1)
end

function dirtoflp(dir)
	if (dir==-1) return true
	return false
end

function randchance(t)
	return flr(rnd(t))==0
end

function updbtnpress()
	for i=0,5 do
		if btnpress[i]==0 then
			if btn(i) then
				btnpress[i]=1
			end
		elseif btnpress[i]==1 then
			if not btn(i) then
				btnpress[i]=0
			else
				btnpress[i]=2
			end
		else
			if not btn(i) then
				btnpress[i]=0
			end
		end
	end
end

function btnd(i)
	return btnpress[i]==1
end

function onscreen(x,y)
	local camx,camy=peek2(0x5f28),peek2(0x5f2a)
	if 		x>=camx 
		and x<camx+128
		and y>=camy
		and y<camy+128
		then return true
	end
	return false
end

function null()
end




-->8
--player
animspeed=4
jumpforce=2.8
gravity=0.15
acc=0.07
friction=0.9
airres=0.98
maxfallspd=4

dedmsgs={
	pre={"our","this","one","another"},
	adj={"noble","pathetic","ill-fated","drunken","careless"},
	noun={"hero","fool","knight","protagonist","ruffian"},
}

--[[player levels
0:nude
1:armour
2:sword
3:shield
]]--
	
function initplayer()
	p={}
	p.x,p.y,p.dx,p.dy=8,72,0,0
	p.w,p.h=3,7
	p.grav=true
	p.dir=1
	p.timer=0
	p.spr=0
	p.animoffset=0
	p.drwoff=-2
	p.hp=3
	p.maxhp=3
	p.dmgtim=0
	
	p.armor=false
	p.sword=false
	p.shield=false
	
	p.update=pnormal
	p.draw=pdraw
end

function palways(p)
	p.dmgtim=max(p.dmgtim-1,0)
	physupd(p)
	local xmax=curroom.w*8-8
	local ymax=curroom.h*8-8
	--exits to next room
	if p.x<=0 then
	 exitindir("⬅️",p.y)
	elseif p.x>=xmax then
	 exitindir("➡️",p.y)
	elseif p.y<=0 then
	 exitindir("⬆️",p.x)
	elseif p.y>=ymax then
	 exitindir("⬇️",p.x)
	end
	
	--map damage
	if (maphurt(p)) playerdmg("just wanted to dip his toes in")
	chaparticles(p)
	
	--freeze in water if no armour
	if not p.armour then
		if fget(getptile(p),2) then
			local dy=p.dy
			playerdmg(1,"froze in seconds")
			p.dy=dy
		end
	end
	
	--move held object
	if p.hold then
		p.hold.x=p.x+p.drwoff/2
		p.hold.y=p.y-p.hold.h
	end
	
	--triggered messages
	if curroom.msgtrig then
		for k,v in pairs(curroom.msgtrig) do
			if boxboxoverlap(v,p) then
				currmsg=v.msg
				del(curroom.msgtrig,v)
				txtscroll=0
			end
		end
	end
end

function exitindir(dir,tpos)
	for k,v in pairs(curroom.exts) do
			if v.dir==dir then
				if tpos>=v.l*8 and tpos<=(v.h+1)*8 then
					changeroom(v)
				end
			end
		end
end

function pnormal(p)
	palways(p)
	if(currmsg) return
	
	--is the player sheilding?
	local sheilding=btn(3) and isgrounded(p) and p.sheild
	
	--x-axis input
	if (btn(0)) then
		p.dir=-1
		if (not sheilding) then
			p.dx-=acc;
		end
	end
	if (btn(1)) then
		p.dir=1
		if (not sheilding) then
			p.dx+=acc;
		end
	end
	
	--run particles
	local pspeed=abs(p.dx)
	if isgrounded(p) and pspeed>0.2 then
		if (randchance(10)) then
			partatp(p,-p.dx/10,-pspeed/5,20,7)
		end
	end

	--jump
	if btnd(2) and isgrounded(p) then
		p.dy=-jumpforce;
		partatp(p,-0.3,-0.25,10,7)
		partatp(p,0.25,-0.2,10,7)
		partatp(p,-0.5,0,10,7)
		partatp(p,0.5,0,10,7)
	end
	
	--attack
	if btnd(4) and p.sword then 
		p.update=pattack
		p.timer=animspeed*4
	end
	
	--swim
	if fget(getptile(p),2) and p.armour then
		if btn(2) then
			if p.dy<0 and not fget(mget((p.x+p.w/2)/8,p.y/8),2) then
				p.dy=-2;
			else
				p.dy-=0.1
			end
		end
		if(btn(3)) p.dy+=0.2
	end
	
	--grab
	if btnd(3) then
		if p.hold==nil then
			local c={}
			c.x=p.x-p.w/2+6*p.dir
			c.y=p.y-2
			c.w=8
			c.h=8
			for k,v in pairs(colliders) do
				if boxboxoverlap(c,v) then
					del(colliders,v)
					del(o,v)
					p.hold=v
				end
			end
		else
			local obj=p.hold
			obj.dx=p.dir
			obj.dy=-1
			add(colliders,obj)
			add(o,obj)
			p.hold=nil
		end
	end
	
	--temporary: level up
	if (btn(0,1)) p.armour=true
	if (btn(3,1)) p.sword=true
	if (btn(1,1)) p.sheild=true
end

function pattack(p)
	palways(p)
	p.timer-=1
	p.spr=6
	p.animoffset=1
	if (p.timer<=animspeed*3) then
		p.spr=7
		p.animoffset=2
		swordcollider(p)
	end
	if (p.timer<=animspeed*2) then
		p.spr=8
		p.animoffset=4
		swordcollider(p)
	end
	if (p.timer<=animspeed) then
		p.spr=9
		p.animoffset=4
	end
	if (p.timer<=0) then
		p.update=pnormal
		local newx=p.x+2*p.dir
		if not solidarea(newx,p.y,p.w,p.h) then
			p.x=newx
		end
		p.spr=0
		p.animoffset=0
	end
end

function swordcollider(p)
	local c={}
	c.x=p.x-p.w/2+6*p.dir
	c.y=p.y-2
	c.w=8
	c.h=8
	add(atkcolliders,c)
end

function pdraw(p)
	if p.hp<=0 then
		plvldraw(p.x,p.y,1,p.dir,p.lvl,false)
		return
	end
	if (p.spr==0) then
		local spri = flr(time()*6)%3+1
		if (isgrounded(p)) then
			if btn(3) and p.sheild then 
				spri=5
			elseif abs(p.dx)>0.1 then
				local val=flr(time()*6)%4
				if val==0 then
					spri=1
				elseif val==2 then
					spri=11
				else
					spri=10
				end
			end
		else
			spri=4
		end
		plvldraw(p.x,p.y,spri,p.dir,p.lvl,false)
	else
		local x=p.x+p.animoffset*p.dir
		plvldraw(x,p.y,p.spr,p.dir,p.lvl,true)
	end
end

function plvldraw(x,y,spri,dir,lvl,atk)
	flp=dirtoflp(dir)
	x+=p.drwoff
	--the background
	if p.shield then
	 palt(13,0)
	else
	 palt(2,0)
	end
	if (not p.sword) palt(6,0)
	drawspriback(x,y,p.h,spri,flp)
	
	--the foreground
	if not p.armour then
	 pal(5,15)
	 pal(11,15)
	end
	if (not p.sword) palt(6,0)
	if p.sheild then
		pal(14,2)
	 pal(12,2)
	 palt(13,0)
	else
	 palt(2,0)
	 pal(12,15)
	 pal(13,15)
	 pal(14,15)
	end
	if (p.dmgtim>0) setpal(7)
	spr(spri,x,y,1,1,flp,false)
	resetpal()
	if (p.hold) p.hold.draw(p.hold)
end

function drwhp()
	for i=0,p.maxhp-1 do
		if i>=p.hp then
			pal(2,0)
			pal(7,0)
			pal(8,0)
		end
		spr(12,3+i*8,3)
		resetpal()
	end
end

function playerdmg(dmg,dedmsg)
	if p.dmgtim<=0 then
		p.hp=max(p.hp-dmg,0)
		p.dmgtim=20
		p.dy=-1
		gamedraw()
	end
	if p.hp==0 then
		p.dedmsg=
			sub(dedmsgs.pre[flr(rnd(#dedmsgs.pre)+1)]
							.." "..
							dedmsgs.adj[flr(rnd(#dedmsgs.adj)+1)]
							.." "..
							dedmsgs.noun[flr(rnd(#dedmsgs.noun)+1)]
							.." "..dedmsg..".",1)
		dedcirc=180
	end
end

function partatp(p,dx,dy,t,col)
	initpart(p.x+3,p.y+7,dx,dy,t,col)
end

function maphurt(p)
	local mspace=mget((p.x+p.w/2)/8,(p.y+p.h/2)/8)
	return mspace==18 or mspace==19 or mspace==21 or mspace==35
end


-->8
--particles
mtypes={
	rainy={42,43,36,37,38,39,24,40,26,60,20},
	wet={26,60,17,24,40},
	torch={53,54,55},
}

emittertypes={
--rainonsolid
	{dx=0.5,dy=-0.5,rdy=1,w=8,f=5,t=4,col=12},
--rainonwater
	{dx=0.2,dy=0.05,rdy=0.15,w=8,f=20,t=30,col=6},
--torch
	{dx=0.5,dy=-0.8,rdy=0.5,w=0,f=10,t=6,col=9},
--lava
	{dx=0,dy=-1,rdy=0,w=8,f=50,t=5,col=9},
}

function initmapemitters(room)
	for i=0,room.w-1 do
		for j=0,room.h-1 do
			local cur=mget(i,j)
			local below=mget(i,j+1)
			if arrcontain(mtypes.wet,cur) then
				if fget(below,0) then
						initmapemitter(i,j,1)
				elseif fget(below,2) then
				 	initmapemitter(i,j,1)
				 	initmapemitter(i,j,2)
				end
			elseif cur==18 then
				initmapemitter(i,j,4)
			elseif arrcontain(mtypes.torch,cur) then
				initmapemitter(i+0.4,j-0.5,3)
			end
			if arrcontain(mtypes.rainy,cur) then
				initrainback(i,j)
			end
		end
	end
end

function initrainback(i,j)
	local r={}
	r.x,r.y=i*8,j*8
	r.update=null
	r.draw=drwrainback
	add(o,r)
end

function drwrainback(r)
	spr(17,r.x,r.y)
end

function initmapemitter(i,j,typ)
	local e={}
	e.x,e.y,e.typ=i*8,j*8+8,typ
	e.update=emitterupdate
	e.draw=null
	add(o,e)
end

function emitterupdate(e)
	local typ=emittertypes[e.typ]
	if (not onscreen(e.x,e.y)) return
	if randchance(typ.f) then
		local x=e.x+rnd(typ.w)
		local dx=rndz(typ.dx)
		local dy=typ.dy+rndz(typ.rdy)
		initpart(x,e.y,dx,dy,typ.t,typ.col)
	end
end

function chaparticles(p)
	local mspace=mget((p.x+4)/8,(p.y+4)/8)
	if arrcontain(mtypes.wet,mspace) then
		if randchance(2) then
			local x=p.x+rnd(p.w)
			local dx=rndz(1)
			initpart(x,p.y,dx,-rnd(1),4,12)
		end
	end
end

function initpart(x,y,dx,dy,t,col)
	local p={}
	p.x=x
	p.y=y
	p.dx=dx
	p.dy=dy
	p.t=t
	p.col=col
	
	p.update=updatepart
	p.draw=drawpart
	add(o,p)
end

function updatepart(p)
	p.x+=p.dx
	p.y+=p.dy
	p.t-=1
	if(p.t<=0) then
		del(o,p)
	end
end

function drawpart(p)
	pset(p.x,p.y,p.col)
end

function initlightning()
	if randchance(500) then
		local l={}
		l.x,l.y,l.dx,l.dy=p.x+rndz(128),127,0,0
		l.t=200
		l.update=lightningupd
		l.draw=lightningdrw
		l.seed=rnd(100)
		add(o,l)
	end
end

function lightningupd(l)
	l.y=128
	for i=0,127,8 do
		if issolid(l.x,i) then
			l.y=i
			break
		end
	end
	if p.armour then
		l.x=p.x+p.w/2
		l.y=min(p.y,l.y)
	end
	l.t-=1
	if l.t>10 then
		local ts=(200-l.t)/50
		if (randchance(l.t/50)) initpart(l.x,l.y,rndz(ts),rndz(ts),5,7)
	elseif l.t<=0 then
		del(o,l)
	end
end

function lightningdrw(l)
	if l.t>10 then
		return
	end
	local col=7
	if framecount%8<2 then
	 cls(13)
	 col=0
	end
	srand(l.seed)
	local x=l.x
	local y=l.y
	while y>0 do
		local nx=x+rndz(40)
		local ny=y-rnd(20)
		line(x,y,nx,ny,col)
		fillp(0b1111110111111111.1)
		circfill(x,y,rnd(40),6)
		fillp(0b1111110111110111.1)
		circfill(x,y,rnd(20),6)
		fillp()
		x,y=nx,ny
	end
end
-->8
--map
rooms={
--1:intro forest
	{w=84,h=16,
		msg="i cant belive those damned bandits took my clothes as well. i'm going to freeze to death if i don't find somewhere warm soon",
		msgtrig={
			{x=60*8,y=11*8,w=1*8,h=2*8,msg="looks like some sort of crypt."},
		},
		data="ub_?.h_j?hve@q=jyebg@6bg?huey<pbr6re@qsj0<)ayqcjy6_??e_?c6_j@e_?c6bj0ucjy6_j q=?c6_?/ebgy2=?cqcg#6reyyse#ebk!6bky6_?<e_?c6bkyqsjy6bkre7k$0rkz0rk,6ser6_?webgr2=?pebg@2ser6bg?5qe0<)bye7j##skz0=?c09o:#to:0_k?5rey6_j0qcg@qcj?9qe@6_j?laj?pagr6rer6re@q=j@<)ay6se%0rk:#+o:#9o:&+o'09o:0+kre_j@6_?fe_j@<?ar6_?eebg#qsj02=?cq=jre_j0erey2cj@2cj q=jy6=?d6_jy2cj qcgr68kz0ro:&9oa&to|0+o-esi6i8i7eter<)a02ser6re@<)a0erey6_?febkrycgyqsj0qcg@<)a06_j0ucjy67jr6bg#<)ay2cjy6bj 6se%0so:#9o|<)aa09oa#9oqm9n5q9namterqsj06re?lag0qsj02=?d6_?derg$0rg,6cg qcgyqcj qcgyqsjr68kz0=kr6sey6cj qcgyyck%0to|#to?laa|<?aa#+o8aan)mda[a-?ce7j#qre?laguqsj0erey6cgrqrer#to'0to,e7j#ebgyerjy6cg#y8k$#to|0tk$&se#e7jre7kz0so:#9oa&da|0+?ca-oa&to-acapa6m_0tkz0rk,#re.6se.e7j.ere.6ser#rera6o|&9o'0ro$0=k#e7jr68k:0so'&+o'&+o'0tk$0rk:0so:#9o:aaa|<?aa#+?ea6oqe+m5itm'&+o'09o:<)az0so$0rk$0ro?lqg$0rk$&da:a-oa&9o|0to$0rkz0so'0+o|aaa|09oa#9o|#+o'&9o|a-o'&+?da-o?1aaqedaaide:&daa#+oaa-oaa6o|#da|<)aa#+?ca-oa#da",
		exts={
			{dir="➡️",l=11,h=13,r=2,dp=-1},
			{dir="⬇️",l=54,h=55,r=3,dp=-40},
		},
		enms={
			{typ=5,x=12,y=14},
			{typ=2,x=13,y=14},
		},
	},
--2:castle entrance
	{w=16,h=16,
		msg="a castle! doesn't look warm but better than nothing in this weather. that water looks freezing though, it'd be suicide jumping in there without wearing something warmer.",
		data="qa_?me7ix2_?mebeaa-?me7iaq+?mebiaa-?meriam+?meba+y+?kebirqda[<)cra9i?l-fy6_?je7i[mda?pag?5qe7aan[<)ay<pcr&_m[aqe#6_?ie_m[udnr6=?jebaaq+mz0rk$&=?febe8isi80+o?lqo?xalqism:adaa&9o:<5b2isi_0+oa",
		exts={
			{dir="⬅️",l=10,h=12,r=1,dp=1},
			{dir="⬇️",l=5,h=10,r=3,dp=0},
		},
		enms={
			--{typ=2,x=11,y=14},
		},
	},
--3:crypt entrance
	{w=32,h=16,
		data="6a_?ea_?hesmaa6mqetm'<)caa_?fa6n?laa{<)aaide:#daa0+?jaae?+aa=arm'aqo?)aaq<pba<?bqeto:aqo'<?caabaau+?gaae7esm'<?daa_?jaae:09o'<pca0+?fa-?ga_?daae70da:#da?l6oa#toa#9oaa6oa#9i?@aaqeso709o'0+?d#toaa6o?paa'<)ca<5bqeso'0+?caqo'#daa#to?dba?xae70ti7#toaeso'<pcay+?ka-?hariqabaau+?na6n?pba:aro?pae?lba?pae?lqoa#+?ca-?ga_?eaqn?taa]<pba#+?naaeq<5ea#da'<5ca<?cqaba",
		exts={
			{dir="⬆️",l=15,h=16,r=1,dp=40},
		},
		enms={
			--{typ=2,x=11,y=14},
		},
	},
}

function changeroom(e)
	loadroom(e.r)
	local xmax=8*curroom.w-9
	local ymax=8*curroom.h-9
	if e.dir=="⬅️" then
	 p.x,p.y=xmax,e.dp*8+p.y
	elseif e.dir=="➡️" then
	 p.x,p.y=1,e.dp*8+p.y
	elseif e.dir=="⬆️" then
	 p.x,p.y=e.dp*8+p.x,ymax
	elseif e.dir=="⬇️" then
	 p.x,p.y=e.dp*8+p.x,1
	end
end

function loadroom(i)
	curroom=rooms[i]
	memset(0x2000,0,0x1000)
	decompresmap(0,0,curroom.data)
	o={}
	if curroom.enms then
		initroomenemies(curroom.enms)
	end
	if curroom.msg then
		--currmsg=curroom.msg
		curroom.msg=nil
		txtscroll=0
	else
		currmsg=nil
	end
	initmapemitters(curroom)
end

function animatemap()
	--lava
	if framecount%30==0 then
		scrollsprh(18)
		scrollsprv(19,2)
	end
	--torches
	if framecount%10==0 then
		switchspr(53,54)
		switchspr(54,55)
	end
	--water
	if framecount%20==0 then
		scrollsprh(28)
		scrollsprh(44)
	end
	--rain and drips
	scrollsprv(15,3)
	scrollsprv(17,1)
end

function scrollsprh(spri)
	local addr=512*(spri\16)+4*(spri%16)
	for i=0,7 do
		local rowadd=addr+i*64
		local f=peek(rowadd)
		for j=0,3 do
			local cur=peek(rowadd+j)
			local nxt=peek(rowadd+j+1)
			if (j==3) nxt=f
			local lft=(cur>>4)&0x0f
			local rgt=(nxt<<4)&0xf0
			local byt=lft|rgt
			poke(rowadd+j,byt)
		end
	end
end

function scrollsprv(spri,h)
	local addr=512*(spri\16)+4*(spri%16)
	local rowcount=h*8-1
	local l=$(addr+rowcount*64)
	for i=rowcount,1,-1 do
		local cur=addr+i*64
		local nxt=cur-64
		poke4(cur,$nxt)
	end
	poke4(addr,l)
end

function switchspr(spr1,spr2)
	local ad1=512*(spr1\16)+4*(spr1%16)
	local ad2=512*(spr2\16)+4*(spr2%16)
	for i=0,7 do
		local nad1=ad1+i*64
		local nad2=ad2+i*64
		local val=$(nad1)
		poke4(nad1,$(nad2))
		poke4(nad2,val)
	end
end

function cpyspr(tar,src)
	local srcad=512*(src\16)+4*(src%16)
	local tarad=512*(tar\16)+4*(tar%16)
	for i=0,7 do
		local offset=i*64
		memcpy(tarad+offset,srcad+offset,4)
	end
end
-->8
--utility
function drawlogs()
	local camx,camy=peek2(0x5f28),peek2(0x5f2a)
	camera()

	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("memory=",0,12,7)
	print(stat(0),28,12,7)
	camera(camx,camy)
end

function drawcolliders()
	for k,v in pairs(atkcolliders) do
		rect(v.x,v.y,v.x+v.w,v.y+v.h,10)	
	end
	for k,v in pairs(o) do
		if v.w and v.h then
			rect(v.x,v.y,v.x+v.w,v.y+v.h,8)
			pset(v.x+v.w/2,v.y+v.h/2,8)
		end
	end
	for k,v in pairs(colliders) do
		rect(v.x,v.y,v.x+v.w,v.y+v.h,10)
	end
	rect(p.x,p.y,p.x+p.w,p.y+p.h,9)
end

function drawgates()
	local xmax=curroom.w*8-1
	local ymax=curroom.h*8-1
	for k,v in pairs(curroom.exts) do
		if v.dir=="⬅️" then
			line(0,v.l*8,0,v.h*8+7,8)
		elseif v.dir=="➡️" then
			line(xmax,v.l*8,xmax,v.h*8+7,8)
		elseif v.dir=="⬆️" then
			line(v.l*8,0,v.h*8+7,0,8)
		elseif v.dir=="⬇️" then
			line(v.l*8,ymax,v.h*8+7,ymax,8)
		end
	end
end

function clamp(val,l,h)
	return min(h,max(l,val))
end

function arrcontain(arr,val)
	for k,v in pairs(arr) do
		if (v==val) return true
	end
	return false
end

function boxpointoverlap(p,b)
	return p.x>b.x 
				and p.x<b.x+b.w
		  and p.y>b.y 
		  and p.y<b.y+b.h
end

function boxboxoverlap(a,b)
 return not (a.x>b.x+b.w 
	         or a.y>b.y+b.h 
	         or a.x+a.w<b.x 
	         or a.y+a.h<b.y)
end

function rndz(val)
	return rnd(val)-val/2
end

function sign(val)
	return val/min(abs(val),0.001)
end
-->8
--map tool compressing
chr6,asc6,char6={},{},"abcdefghijklmnopqrstuvwxyz.1234567890 !@#$%,&*()-_=+[{]};:'|<>/?"
for i=0,63 do
  c=sub(char6,i+1,i+1) chr6[i]=c asc6[c]=i
end
char6=_n

function loadmap(i)
	memset(0x2000,0,0x1000)
	decompresmap(0,0,rooms[i].data)
	cstore(0x2000,0x2000,0x1000)		
end

function savemap(i)
	printh(compresmap(0,0,rooms[i].w,rooms[i].h),"@clip")
end

function compresmap(h,v,x,y)
local r,b6,c6,n,c,lc="",0,0,0
  function to6(a)
    for i=1,#a do
      for j=0,7 do
        if (band(a[i],2^j)>0) c6+=2^b6
        b6+=1
        if (b6==6) r=r..chr6[c6] c6=0 b6=0
      end
    end
  end
  to6({x,y}) x-=1 y-=1
  for i=0,y do
    for j=0,x do
      c=mget(h+j,v+i)
      if (c==lc) n+=1
      if c!=lc or (j==x and i==y) then
        if n<2 then
          for k=0,n do
            to6({lc})
          end
        else
          to6({255,n,lc})
        end
        lc=c n=0
      end
    end
  end
  to6({c,0})
  return r
end

-- take 6-bit string of t and
-- decompress it to the mapper
-- as 8-bit data.
function decompresmap(h,v,t)
local r,b6,c6,cp,n=t,0,0,1,0
  function to8()
  local s=0
    for i=0,7 do
      if (b6==0) c6=asc6[sub(r,cp,cp)] cp+=1
      if (band(c6,2^b6)>0) s+=2^i
      b6=(b6+1)%6
    end
    return s
  end
  local x,y,xp,yp,c=to8()-1,to8()-1,h,v
  repeat
    if n>0 then
      n-=1
    else
      c=to8()
      if (c==255) n=to8() c=to8()
    end
    mset(xp,yp,c)
    --spr(c,xp*8,yp*8)
    xp+=1
    if (xp>h+x) xp=h yp+=1
    if (yp>v+y) return
  until forever
end

-->8
--enms&objs
function initenemies()
	enmtyps={
		--1:bat
		{upd=batupd,
			grav=false,
			w=7,h=4,hp=1,
			dedspr=80,drwoff=0,
			dedmsg="was torn to shreds by a bat",
			},
		--2:zombie
		{upd=zomupd,
			grav=true,
			w=5,h=7,hp=2,
			dedspr=81,drwoff=-1,
			dedmsg="was mutilated by a zombie",
		},
		--3:skeleton
		{upd=skelupd,
			grav=true,
			w=5,h=7,hp=3,
			dedspr=82,drwoff=-1,
			dedmsg="got boned",
		},
		--4:arrow
		{upd=arrupd,
			grav=false,
			w=0,h=0,hp=1,
			dedspr=82,drwoff=0,
			dedmsg="lost his life to a lucky arrow",
		},
		--5:barrel
		{upd=barupd,
			grav=true,
			rolls=true,
			solid=true,
			w=5,h=5,hp=1,
			dedspr=82,drwoff=-2,
			dedmsg="lost his life to a lucky arrow",
		},
	}
end

function initroomenemies(enemies)
 for k,v in pairs(enemies) do
 	initenemy(v.typ,v.x*8,v.y*8)
 end
end

function initenemy(typ,x,y)
	local typ=enmtyps[typ]
	local e={}
	e.x,e.y,e.dx,e.dy=x,y,0,0
	e.w,e.h=typ.w,typ.h
	e.hp=typ.hp
	e.grav=typ.grav
	e.rolls=typ.rolls
	e.typ=typ
	e.drwoff=typ.drwoff
	e.dmgtim=0
	e.spr=0
	e.dir=1
	e.update=typ.upd
	e.draw=edraw
	add(o,e)
	if (typ.solid) then
		add(colliders,e)
	end
	return e
end

function batupd(e)
	--move
	e.dx+=0.2*sin(time())
	e.dy+=0.2*cos(time()*3)
	physupd(e)
	--animate
	e.spr=64+flr(time()*5)%2
	
	chaparticles(e)
	hitplayer(e)
	takedmg(e)
end

function zomupd(e)
	--chnage dir if wall
	if solidarea(e.x+e.dir,e.y,e.w,e.h) then
		e.dir=-e.dir
	end
	--chnage dir if edge
	if not issolid(e.x+e.w/2+e.w/2*e.dir,e.y+8) and isgrounded(e)then
		e.dir=-e.dir
	end
	--move
	e.dx+=0.01*e.dir
	physupd(e)
	--walk anim
	e.spr=66+(framecount/16)%3
	
	chaparticles(e)
	hitplayer(e)
	takedmg(e)
end

function skelupd(e)
	if (not e.st) e.st=0
	if e.st==0 then
		--chnage dir if wall
		if solidarea(e.x+e.dir,e.y,e.w,e.h) then
			e.dir=-e.dir
		end
		--chnage dir if edge
		if not issolid(e.x+e.w/2+e.w/2*e.dir,e.y+8) and isgrounded(e)then
			e.dir=-e.dir
		end
		--move
		e.dx+=0.01*e.dir
		--walk anim
		e.spr=69+(framecount/15)%4
		--aim for player
		if facingp(e) then
			e.st=1
			e.tim=0
		end
	else
		e.tim+=1
		e.spr=72+e.tim/30
		if e.tim>=89 then
			local arr=initenemy(4,e.x,e.y+3)
			arr.dx,arr.dy=e.dir*5,rndz(0.5)
			arr.ddx=arr.dx/10
			arr.ddy=arr.dy/10
			arr.dir=e.dir
			arr.draw=drawarrow
			e.st=0
		end
	end
	physupd(e)
	chaparticles(e)
	hitplayer(e)
	takedmg(e)
end

function dedupd(e)
	physupd(e)
end

function arrupd(e)
	e.dx+=e.ddx
	e.dy+=e.ddy
	if physupd(e) then 
		e.ddx,e.ddy=0,0
		e.update=deadarr
		e.tim=120
	end
	hitplayer(e)
end

function barupd(e)
	e.spr=76
	if solidarea(e.x+e.dx,e.y,e.w,e.h) then
		e.dx=-e.dx*0.8
		if (abs(e.dx)<0.3) e.dx=0
	end
	if (abs(e.dx)>0) e.spr=77
	e.dir=-sign(e.dx)
	physupd(e)
end

function deadarr(e)
	e.tim-=1
	if (e.tim<=0) del(o,e)
end

function drawarrow(e)
	local lend=e.x-e.dir*4
	line(e.x-1,e.y,lend+1,e.y,0)
	line(e.x,e.y+1,lend,e.y+1,0)
	line(e.x,e.y-1,lend,e.y-1,0)
	line(e.x,e.y,lend,e.y,4)
	pset(e.x,e.y,6)
end

function takedmg(e)
	--damage timer
	e.dmgtim=max(e.dmgtim-1,0)
	--kill if out of hp
	if e.hp<=0 and e.dmgtim<=0 then
		e.update=dedupd
		e.spr=e.typ.dedspr
		e.grav=true
		return
	end
	--detect hits
	if (e.dmgtim>0) return
	if hitcollide(e) or maphurt(e) then
		local hitdir=(e.x-p.x)/abs(e.x-p.x)
		e.dx+=2*hitdir
		e.dy-=2
		for i=0,10 do
			initpart(e.x+e.w/2,e.y+e.h/2,rnd(1)*hitdir-0.2*hitdir,rndz(1),5+rnd(10),2)
		end
		e.dir=-(e.x-p.x)/abs(e.x-p.x)
		e.dmgtim=10
		e.hp-=1
	end
end

function hitplayer(e)
	if boxboxoverlap(p,e) then
		playerdmg(1,e.typ.dedmsg)
	end
end

function facingp(e)
	--vertical check
	if (abs(p.y-e.y)>8) return false
	--horizontal direction check
	if ((e.x-p.x)/abs(e.x-p.x)==-e.dir) return true
	return false
end

function hitcollide(e)
	for k,v in pairs(atkcolliders) do
		if (boxboxoverlap(e,v)) return true
	end
	return false
end

function edraw(e)
	local flp=not dirtoflp(e.dir)
	drawspriback(e.x+e.drwoff,e.y,e.h,e.spr,flp)
	if e.dmgtim>0 then
		setpal(7)
	end
	spr(e.spr,e.x+e.drwoff,e.y,1,1,flp)
	resetpal()
end
__gfx__
00000000000000000000000000000000600000000000000007600000007777700070770000000000000000000000000000000000000000000000000000010000
0000000000000b500000000000000b50600b5000000000007060b5000700b5070000b5700000b5700000000000000b5000999a00000000000000000000010000
0070070000000ff000000b5000000ff0600ff000000b502070f0ff000000ff060200ff070200ff0000000b5000000ff0094879a0000000000000000000010000
000770000000500000000ff0000550000f0000f2000ff0027005000002f500062f0500072f05000700000ff000055000042888900000000000000000000c0000
000770000005b5500005500000f0b50e00555522005500f200055500020b50f020b55f6620b550070005500000f0b50e04228890000000000000000000000000
0070070000f0b50e00f0b50e0600b520000b50020f0b5002002b52000205050000b5000000b50f0700f0b50e0600552004422990000000000000000000000000
000000000600502006005020600050200050050060050500000550000005000005005000050050660600502060000b2000444400000000000000000000000000
00000000600500c0600500c0000500d0005000006050050000505000000500000500050005000500000000000005005000000000000000000000000000000000
0555555b100000000000000000000a9800000000000009820000000044444444010101003000031300dddd0000000b5bc1111cc1000000000000000000000000
5555555b100010000000000000000898000000000000099800000000bb4bbb4b00101010313013000d5555d00000055011c1c11c000000000000000000000000
555555bbc0001000000000000000098900000000000009a90000000000b000b0011101010031030005bbbb5000000b50c11c1111000000000000000000000000
bbbbbbbb00001000000000000000098900000000000098a90000000000400040101011100030000b05555550000005501c11ccc1000000000000000000000000
555bb555000000100000000000000a89000dd00000aa98980000000000b000b001011101000d0bd005bbbb5000000b50111c111c000000000000000000000000
555b55550010001088a988890000099900d55d0099a9a889000000a9bbbbbbbb10110100dd000bb005555550000005501cc11111000000000000000000000000
55bb5555001000c02988298800000989005555008898982800000a980000000001011010bb000000dd3dddd300000b55c11c111c000000000000000000000000
bbbbbbbb00c00000822282820000098a00055000298282890000098200000000001011000000b000bb3b3b3b0000055511c111c1000000000000000000000000
555555005555555b5555555b0000098800303030000400000304400300000000100b010010000003000003033030000000c0cc00000000000000000000000000
555555505555555b555555bb00000a8830333303303b0400000b4030030003000100b001130030330000310311300300c11cc1cc000000000000000000000000
5555555b55bb55bb5555bb5b0000098903033030341b0444000b400000303030110b10100303130000303113d1e03000c1cc1c11000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbb0000092933333333034b4403000b4000030303331b0bb1000300000b00011deeeeeb30001c11ccc1000000000000000000000000
555b5555555b555555bb555500000888133133133103b030004440003031331310bbb0b00dd00bd003eebbeeeeee3003111c1c1c000000000000000000000000
555b5555555b5555555b555500000a89313313034004b01300b4400303031303010bbb01bbdd0bb00131eeeeeeebde301cc11111000000000000000000000000
555bb55555bbbb55555b555500000a88031031300444b00000b3440303103130000bb000bbbb000031ddeedebbebb11ec11c111c000000000000000000000000
bbbbbbbbbbbb0bbbbbbbbbbb000009983103000030bb04000b43b30331031313000bb0000bb000b0eebbeeeebbeeeeee11c111c1000000000000000000000000
5555555b5555555b000000dd000000000000000000b0b000b0b0b00000b0b0b0005b0000000dd00b0b0000000000000000000000000000000000000000000000
5555555b5555555b000000550000000b000000000b0b0b000b0b0b000b0b0b0b0050000000bbbd0000000bd0000bb000000000dd000000000000000000000000
0555555b55555bb00000dd550000000b00000000b0bbb0b0b09bb0b000bb90b000b50000d0bbbb0000000bb0000bb00000000055000000000000000000000000
0bbbbbbbbbbbb0000000bbbbb00bbbbbbbbbbbb00bbabb000bbabb000bbabb0000050000000bb0b000bb00000000000000000055000000000000000000000000
0b5bbb5555b0000000ddb555000b0000000b0000b0bbb0b0b0bbb00000bbb0b0005b0000bd00000000bb0000000000b000000055000000000000000000000000
00bb5555555b00000055b555000b0000000b00000b090b000b09000000090b0000500000bb000bb0000000000000000000000055000000000000000000000000
00005555555b5000dd55bb55000b0000000b000000040000000400000004000000b5000000b00bb0000000b00b0000000d53dd53000000000000000000000000
0000000bbbbbb000bbbbbbbbbbbbb00000bbbbbb000b0000000b0000000b0000000500000000000000000000000000005b3bb3b3000000000000000000000000
0011100011000110000000000000000000000000000660000006600000066000000660000040000000400000000000000b444000004400000000000000000000
11a1a110bb111bb0000320000032000000032000000660000006600000066000000660000400660004006600000000000556600004bb40000000000000000000
1b111b1000a1a00003e330003e33000003e3300040000600000000000000060400000000040066000400660000000000bb4444004bbbb4000000000000000000
b00000b000111000000eb000000eb000000eb00040065060000650400006500400006040066600000666006004444460bbb444004bbbb4000000000000000000
000000000000000003bb000003bbb00003bb0000060000600006040006000060000604000400560004005660000000000555600004bb40000000000000000000
0000000000000000000eb000000eb000000eb000004060000044500000054400004450000406600004000500000000000bbb4000004400000000000000000000
0000000000000000000e0000000e0000000b00000006000000006000000060000000600000400500004605000000000000000000000000000000000000000000
00000000000000000003030000030000003030000060060000006000006006000006600000060660000606600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21a11220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003bb3200000606600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003ebb2e226066006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ggllllggggggggggggssggssllllssggggggggssggggggggggggggssggggggggggggggssgg1111ggggggggssggggggggggggggssggggggggggggggssgggggggg
ggllllggggggggggggssggssllllssggggggggssggggggggggggggssggggggggggggggssgg1111ggggggggssggggggggggggggssggggggggggggggssgggggggg
llggggggmmmmgggglljjggggggggjj11jjjjggjjgggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggg
llggggggmmmmgggglljjggggggggjj11jjjjggjjgggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggg
ggggggllllllmmggggjj11jjgg11jjgggg1111jjgg11jjgggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggg
ggggggllllllmmggggjj11jjgg11jjgggg1111jjgg11jjgggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggg
ggmmggllllllllggggggggjj11ggjjggggmm11ggggjjggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11gggg
ggmmggllllllllggggggggjj11ggjjggggmm11ggggjjggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11gggg
ggggggggll999999aaggggjjgg999999aaggggggll999999aagggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggg
ggggggggll999999aaggggjjgg999999aaggggggll999999aagggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggg
ggllmmgg99kk887799aagggg99kk887799aagggg99kk887799aagggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11
ggllmmgg99kk887799aagggg99kk887799aagggg99kk887799aagggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11
ggllllggkk2288888899mmggkk2288888899ggggkk2288888899gg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11
ggllllggkk2288888899mmggkk2288888899ggggkk2288888899gg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11gggggg11
ggggggllkk2222888899llggkk2222888899llggkk2222888899gg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssssgggg11ggggggss
ggggggllkk2222888899llggkk2222888899llggkk2222888899gg11ggggggssgggggg11ggggggssgggggg11ggggggssgggggg11ggggggssssgggg11ggggggss
ggggggggkkkk22229999ggggkkkk22229999llggkkkk22229999ggssggggggggggggggssggggggggggggggssggggggggggggggssssggggggggssggssgggggggg
ggggggggkkkk22229999ggggkkkk22229999llggkkkk22229999ggssggggggggggggggssggggggggggggggssggggggggggggggssssggggggggssggssgggggggg
llggllggggkkkkkkkkggggggmmkkkkkkkkggggggmmkkkkkkkkjjggjjgggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggg
llggllggggkkkkkkkkggggggmmkkkkkkkkggggggmmkkkkkkkkjjggjjgggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggggg11gggggggggggg
ggggggggggggllmmggggggllllllmmggggggggllllllmmgggg1111jjgg11jjgggg11gggggg11gggggg11gggggg11gggggg11jjgggg11jjgggg11jjgggg11jjgg
ggggggggggggllmmggggggllllllmmggggggggllllllmmgggg1111jjgg11jjgggg11gggggg11gggggg11gggggg11gggggg11jjgggg11jjgggg11jjgggg11jjgg
ggggggggggggllllggmmggllllllllggggmmggllllllllggggmm11ggggjjggggggssgggggg11ggggggssgggggg11ggggggssggjjggjjggjjggssggjjggjjggjj
ggggggggggggllllggmmggllllllllggggmmggllllllllggggmm11ggggjjggggggssgggggg11ggggggssgggggg11ggggggssggjjggjjggjjggssggjjggjjggjj
ggggggllllggggggggggggggllllggllggggggggllllggllgggggggglljjgggggggggggggg11gggggggggggggg11ggggggggjjggjj11jjjjjjggjjggjj11jjjj
ggggggllllggggggggggggggllllggllggggggggllllggllgggggggglljjgggggggggggggg11gggggggggggggg11ggggggggjjggjj11jjjjjjggjjggjj11jjjj
ggggggllllggggggggllmmggggggggggggllmmggggggggggggggggggggjjgg11jjgggggggggggg11gggggggggggggg11ggjjggjj11jjjj11jjjjggjj11jjjj11
ggggggllllggggggggllmmggggggggggggllmmggggggggggggggggggggjjgg11jjgggggggggggg11gggggggggggggg11ggjjggjj11jjjj11jjjjggjj11jjjj11
ggggggggggggggggggllllggggggllllggllllggggggllllggggggggllmmggjjgggggg11gggggg11gggggg11gggggg11ggggjj11jj11jj11jjggjj11jj11jj11
ggggggggggggggggggllllggggggllllggllllggggggllllggggggggllmmggjjgggggg11gggggg11gggggg11gggggg11ggggjj11jj11jj11jjggjj11jj11jj11
ggggggggggggggllggggggllggggllllggggggllggggllllggllllggllll1111gggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggjj11ggjj11jj
ggggggggggggggllggggggllggggllllggggggllggggllllggllllggllll1111gggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggjj11ggjj11jj
ggggggggggggggggggggggggggggggggggggggggggggggggggllllggggggggggggggggssggggggggggggggssggggggggggjj11ssjj11jj11jjjj11ssjj11jj11
ggggggggggggggggggggggggggggggggggggggggggggggggggllllggggggggggggggggssggggggggggggggssggggggggggjj11ssjj11jj11jjjj11ssjj11jj11
gg55555555555555ll55555555555555ll55555555555555ll55555555555555ll11gggggggggggggg11gggggggggggggg11ggjjggjjggjjgg11ggjjggjjggjj
gg55555555555555ll55555555555555ll55555555555555ll55555555555555ll11gggggggggggggg11gggggggggggggg11ggjjggjjggjjgg11ggjjggjjggjj
gg555555555555llll555555555555llll55555555555555ll55555555555555ll11gggggg11gggggg11gggggg11ggggggjjggjjjjjjjjggjjjjggjjjjjjjjgg
gg555555555555llll555555555555llll55555555555555ll55555555555555ll11gggggg11gggggg11gggggg11ggggggjjggjjjjjjjjggjjjjggjjjjjjjjgg
ll55555555llll55ll55555555llll55ll5555llll5555llll5555555555llllggssgggggg11ggggggssgggggg11ggggggssjjggjjjjggjjggssjjggjjjjggjj
ll55555555llll55ll55555555llll55ll5555llll5555llll5555555555llllggssgggggg11ggggggssgggggg11ggggggssjjggjjjjggjjggssjjggjjjjggjj
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllgggggggggggggg11gggggggggggggg11ggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllgggggggggggggg11gggggggggggggg11ggggggjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
555555llll555555555555llll55555555555555ll555555555555llgggggggggggggggggggggg11gggggggggggggg11gg11jjjj11jjjj11jj11jjjj11jjjj11
555555llll555555555555llll55555555555555ll555555555555llgggggggggggggggggggggg11gggggggggggggg11gg11jjjj11jjjj11jj11jjjj11jjjj11
55555555ll55555555555555ll55555555555555ll55555555555555llgggggggggggg11gggggg11gggggg11gggggg11ggjj11jjjj11jj11jjjj11jjjj11jj11
55555555ll55555555555555ll55555555555555ll55555555555555llgggggggggggg11gggggg11gggggg11gggggg11ggjj11jjjj11jj11jjjj11jjjj11jj11
55555555ll55555555555555ll555555555555llllllll5555555555ll55gggggggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggjj11ggjj11jj
55555555ll55555555555555ll555555555555llllllll5555555555ll55gggggggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggjj11ggjj11jj
llllllllllllllllllllllllllllllllllllllllllggllllllllllllllllggggggggggssggggggggggggggssggggggggggjj11ssjjggggggggjj11ssjjgggggg
llllllllllllllllllllllllllllllllllllllllllggllllllllllllllllggggggggggssggggggggggggggssggggggggggjj11ssjjggggggggjj11ssjjgggggg
ggggggggggggggggggllggllggllgggggggggggggggggggggggggggggggggggggg11gggggggggggggg11gggggggggggggg11ggjjggjjggjjgg11ggggkkgggggg
ggggggggggggggggggllggllggllgggggggggggggggggggggggggggggggggggggg11gggggggggggggg11gggggggggggggg11ggjjggjjggjjgg11ggggkkgggggg
ggggggggggggggggggggllggllggllggggggggggggggggggggggggggggggggggll11gggggg11gggggg11gggggg11ggggggjjggjjjjjjjjggjjjjggjjll11kkgg
ggggggggggggggggggggllggllggllggggggggggggggggggggggggggggggggggll11gggggg11gggggg11gggggg11ggggggjjggjjjjjjjjggjjjjggjjll11kkgg
ggggggggggggggggggllgg9999llggllggggggggggggggggggggggggggggggggllssgggggg11ggggggssgggggg11ggggggssjjggjjjjggjjggjjkk11ll11kkkk
ggggggggggggggggggllgg9999llggllggggggggggggggggggggggggggggggggllssgggggg11ggggggssgggggg11ggggggssjjggjjjjggjjggjjkk11ll11kkkk
ggllllllllllllllggggllllaallllggggggggggggggggggggllggggllllllllllgggggggg11gggggggggggggg11ggggggjjjjjjjjjjjjjjjjggjjkkllkkkkgg
ggllllllllllllllggggllllaallllggggggggggggggggggggllggggllllllllllgggggggg11gggggggggggggg11ggggggjjjjjjjjjjjjjjjjggjjkkllkkkkgg
ggggggggllggggggggllggllllllggggggggggggggggggggggggggggllgggggggggggggggggggg11gggggggggggggg11gg11jjjj11jjjj11jjjj11ggjjllggjj
ggggggggllggggggggllggllllllggggggggggggggggggggggggggggllgggggggggggggggggggg11gggggggggggggg11gg11jjjj11jjjj11jjjj11ggjjllggjj
ggggggggllggggggggggllgg99ggggggggggggggggggggggggggggggllgggggggggggg11gggggg11gggggg11gggggg11ggjj11jjjj11jj11jjkkgg11kkllgg11
ggggggggllggggggggggllgg99ggggggggggggggggggggggggggggggllgggggggggggg11gggggg11gggggg11gggggg11ggjj11jjjj11jj11jjkkgg11kkllgg11
ggggggggllggggggggggggggkkggggggggggggggggggggggggggggggllgggggggggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggkkkkkkllggss
ggggggggllggggggggggggggkkggggggggggggggggggggggggggggggllgggggggggggg11ggggggssgggggg11ggggggssggggjj11ggjj11jjggggkkkkkkllggss
ggggggllllllllllllggggggllggggggggggggggggggggggggllllllllllggggggggggssggggggggssggggssggggggggggjj11ssjjggggggggjjggllllggkkgg
ggggggllllllllllllggggggllggggggggggggggggggggggggllllllllllggggggggggssggggggggssggggssggggggggggjj11ssjjggggggggjjggllllggkkgg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg11gggggggggg0000ssgggggggggggggg11gggggggggggggg11jjggkkkkgggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg11gggggggggg0000ssgggggggggggggg11gggggggggggggg11jjggkkkkgggg
ggggggggggggggggllgggggggggggggggggggggggggggggggggggggggggggggggg11gggggg1100ffff00gggggg11gggggg11gggggg11gggggg11ggggllkkggjj
ggggggggggggggggllgggggggggggggggggggggggggggggggggggggggggggggggg11gggggg1100ffff00gggggg11gggggg11gggggg11gggggg11ggggllkkggjj
ggggggggggggggggllggggggggggggggggggggggggggggggggggggggggggggggggssgggggg1100ffff00gggggg11ggggggssgggggg11ggggggssggggllkkgggg
ggggggggggggggggllggggggggggggggggggggggggggggggggggggggggggggggggssgggggg1100ffff00gggggg11ggggggssgggggg11ggggggssggggllkkgggg
ggllggggllllllllllggggggggggggggggllllllllllllllgggggggggggggggggggggggggg11gg0000ff00gggg11gggggggggggggg11ggggggggggggllkkgggg
ggllggggllllllllllggggggggggggggggllllllllllllllgggggggggggggggggggggggggg11gg0000ff00gggg11gggggggggggggg11ggggggggggggllkkgggg
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggggggggg00ffffffff00gggggg11gggggggggggggg11ggggggkkkkkkgg11
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggggggggg00ffffffff00gggggg11gggggggggggggg11ggggggkkkkkkgg11
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggg11gg00ff00ffff00ff00gggg11gggggg11gggggg11ggggggllkkkkgg11
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggg11gg00ff00ffff00ff00gggg11gggggg11gggggg11ggggggllkkkkgg11
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggg11gggg000000ff0000ggggggssgggggg11ggggggssgggggglljjkkkkss
ggggggggllggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggg11gggg000000ff0000ggggggssgggggg11ggggggssgggggglljjkkkkss
ggllllllllllggggggggggggggggggggggggggllllllllllllggggggggggggggggggggssggss00ff0000ff00ggssssggggssggssggggggggggggllkkjjlljjgg
ggllllllllllggggggggggggggggggggggggggllllllllllllggggggggggggggggggggssggss00ff0000ff00ggssssggggssggssggggggggggggllkkjjlljjgg
ggggggggggggggggggggggggggggggmmmm55555555555555llggggggmmmmggggll11ggggggggggggjjjjggggggggjj11jjjjggggggggjj11jj11gggggggggggg
ggggggggggggggggggggggggggggggmmmm55555555555555llggggggmmmmggggll11ggggggggggggjjjjggggggggjj11jjjjggggggggjj11jj11gggggggggggg
gggggggggggggggggggggggggggggg555555555555555555llggggllllllmmgggg11jjggggjjggjjjjjj11jjgg11jjggggjj11jjgg11jjgggg11jjggggjjggjj
gggggggggggggggggggggggggggggg555555555555555555llggggllllllmmgggg11jjggggjjggjjjjjj11jjgg11jjggggjj11jjgg11jjgggg11jjggggjjggjj
ggggggggggggggggggggggggggmmmm55555555555555llllggmmggllllllllggggggjjggjj11jjggggggggjj11ggjjggggggggjj11ggjjggggggjjggjj11jjgg
ggggggggggggggggggggggggggmmmm55555555555555llllggmmggllllllllggggggjjggjj11jjggggggggjj11ggjjggggggggjj11ggjjggggggjjggjj11jjgg
ggggggggggggggggggggggggggllllllllllllllllllggggggggggggllllggllggggjjggggggggggllggggjjggggggggllggggjjggggggggllggjjgggggggggg
ggggggggggggggggggggggggggllllllllllllllllllggggggggggggllllggllggggjjggggggggggllggggjjggggggggllggggjjggggggggllggjjgggggggggg
ggggggggggggggggggggggmmmmll5555555555llggggggggggllmmggggggggggggggmmmmggggllmmggggggggmmggllmmggggggggmmggllmmggggmmmmggggllmm
ggggggggggggggggggggggmmmmll5555555555llggggggggggllmmggggggggggggggmmmmggggllmmggggggggmmggllmmggggggggmmggllmmggggmmmmggggllmm
gggggggggggggggggggggg5555ll555555555555llggggggggllllggggggllllggllllmmmmggllllggmmmmggggggllllggmmmmggggggllllggllllmmmmggllll
gggggggggggggggggggggg5555ll555555555555llggggggggllllggggggllllggllllmmmmggllllggmmmmggggggllllggmmmmggggggllllggllllmmmmggllll
ggggggggggggggggggmmmm5555llll5555555555ll55ggggggggggllggggllllggllllllllggggggggllllggggggggggggllllggggggggggggllllllllgggggg
ggggggggggggggggggmmmm5555llll5555555555ll55ggggggggggllggggllllggllllllllggggggggllllggggggggggggllllggggggggggggllllllllgggggg
ggggggggggggggggggllllllllllllllllllllllllllggggggggggggggggggggggggllllggggggllggggggggggllggggggggggggggllggggggggllllggggggll
ggggggggggggggggggllllllllllllllllllllllllllggggggggggggggggggggggggllllggggggllggggggggggllggggggggggggggllggggggggllllggggggll
ggggggggggggggmmmm55555555555555llggllggggggggggggggggggggggggggggggggggggggggggggggllggggggggggggggggggmmmmggggllggllgggggggggg
ggggggggggggggmmmm55555555555555llggllggggggggggggggggggggggggggggggggggggggggggggggllggggggggggggggggggmmmmggggllggllgggggggggg
gggggggggggggg555555555555555555llggggggggggllmmggggggggllllggggggggggggllllggggggggggggggggllmmggggggllllllmmggggggggggggggllmm
gggggggggggggg555555555555555555llggggggggggllmmggggggggllllggggggggggggllllggggggggggggggggllmmggggggllllllmmggggggggggggggllmm
ggggggggggmmmm55555555555555llllggggggggggggllllggggggggllllggggggggggggllllggggggggggggggggllllggmmggllllllllggggggggggggggllll
ggggggggggmmmm55555555555555llllggggggggggggllllggggggggllllggggggggggggllllggggggggggggggggllllggmmggllllllllggggggggggggggllll
ggggggggggllllllllllllllllllggggggggggllllggggggggggggggggggggggggggggggggggggggggggggllllggggggggggggggllllggllggggggllllgggggg
ggggggggggllllllllllllllllllggggggggggllllggggggggggggggggggggggggggggggggggggggggggggllllggggggggggggggllllggllggggggllllgggggg
ggggggmmmmll5555555555llggggggggggggggllllggggggggggggggggggggllggggggggggggggllggggggllllggggggggllmmggggggggggggggggllllgggggg
ggggggmmmmll5555555555llggggggggggggggllllggggggggggggggggggggllggggggggggggggllggggggllllggggggggllmmggggggggggggggggllllgggggg
gggggg5555ll555555555555llggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggllllggggggllllgggggggggggggggg
gggggg5555ll555555555555llggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggllllggggggllllgggggggggggggggg
ggmmmm5555llll5555555555ll55ggggggggggggggggggllggggllggggggggggggggllggggggggggggggggggggggggllggggggllggggllllggggggggggggggll
ggmmmm5555llll5555555555ll55ggggggggggggggggggllggggllggggggggggggggllggggggggggggggggggggggggllggggggllggggllllggggggggggggggll
ggllllllllllllllllllllllllllgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggllllllllllllllllllllllllllgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
mmgg555555555555llggggggmmmmggggllggggggggggggggggggggggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggggggggggggggggg
mmgg555555555555llggggggmmmmggggllggggggggggggggggggggggggggggggggggggggggggggggggggllgggggggggggggggggggggggggggggggggggggggggg
5555555555555555llggggllllllmmggggggggggllllggggggggggggggggggggggggggggggggggggggggggggggggllmmggggggggllllgggggggggggggggggggg
5555555555555555llggggllllllmmggggggggggllllggggggggggggggggggggggggggggggggggggggggggggggggllmmggggggggllllgggggggggggggggggggg
55555555555555llllmmggllllllllggggggggggllllggggggggggggggggggggggggggggggggggggggggggggggggllllggggggggllllgggggggggggggggggggg
55555555555555llllmmggllllllllggggggggggllllggggggggggggggggggggggggggggggggggggggggggggggggllllggggggggllllgggggggggggggggggggg
llllllllllllllllllggggggllllggllggggggggggggggggggggggggggggggggggggggggggggggggggggggllllgggggggggggggggggggggggggggggggggggggg
llllllllllllllllllggggggllllggllggggggggggggggggggggggggggggggggggggggggggggggggggggggllllgggggggggggggggggggggggggggggggggggggg
55555555llll555555llmmggggggggggggggggggggggggllggggggggggggggggggggggggggggggggggggggllllggggggggggggggggggggllgggggggggggggggg
55555555llll555555llmmggggggggggggggggggggggggllggggggggggggggggggggggggggggggggggggggllllggggggggggggggggggggllgggggggggggggggg
55555555ll55555555llllggggggllllgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
55555555ll55555555llllggggggllllgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
555555llll55555555ggggllggggllllggggllggggggggggggggggggggggggggggggggggggggggggggggggggggggggllggggllgggggggggggggggggggggggggg
555555llll55555555ggggllggggllllggggllggggggggggggggggggggggggggggggggggggggggggggggggggggggggllggggllgggggggggggggggggggggggggg

__gff__
0000000000000000000000000000000201000200000200010001000104000002010101000302020300014383040000020101410000000000020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112711111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111272427181118271818111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111111181111111111181127242524181818242418181111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111118181827271118181824242524181827252418181811111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111111111111118182724242418281811182611281128261828181811111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111818182818242518182811112a2919291919292b28111118111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111811271111111111111111111111111111111118272711111818111111111111111124181818181818181126282a2919293939393a393a3939192b1111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181827242418272424111111111111111111271827242424181818181118111118112724272718181828112a1929393a3b393a3a393b3b3a393a39392b11112727181111111111112727111111111811111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
182824252427242424271111272411111827242727242524271828181818182718272425241811282a191939393b3a003b393b393b302121202222213111112424242711111811272424241111181811111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11281126181824252424182724242418272425241818261118182818181827241818242528112a2939393a3a3b000000393a003a3a1033361f3436003311112425241811181818242425242718181818111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
192919192b281825241818242425241818242511282a19292b1128111828242524181826282a39393b3a390000003b000000003a3b2200342f3300340011111126281411181818142425241111182818111411110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a393a39392b112628111818112518281828262a293a393b3929292b1128112611112a192939393a3a003b003b390000003b003b393020000f00323139291919292b1a111a28111a11261a11111a2811111a11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003a3b3b3a3a193929292b28112611282a3929393a3b3b3a3b3b3a3929291929392939393a3a3900003b000000003a00000000003a1031331f32313a3b3b3a393a391919192939291929291939191919291929290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b0039003b003b3a3b39392919291929393a393b3b00003b393a003a3a3b3a3b3a3b3a3b003b3a3b000000003b00000000000000103100003210393b00003a3b00003b00003a3b3a003b0000003a0000003b003a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0013001f1d6201e62021620216201d620136201b6201b620176201c620196201c620196201e620196201e6201f62020620206202062020620206201c620176201b6201c6201c6201e6201b6201d6201d6201d620
__music__
02 00424344

