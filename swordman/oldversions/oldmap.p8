pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
atkcolliders={}
framecount=0
btnpress={}
dedcirc=0
txtscroll=0
currmsg=nil

function _init()
	initenemies()
	loadroom(1)
	initplayer()
	initmapemitters(curroom)
	
	for i=0,5 do
		btnpress[i]=0
	end
end

function _update60()
	if currmsg then
		if (txtscroll>#currmsg+120) currmsg=nil
		txtscroll+=0.5
	end
	if p.hp<=0 then
		txtscroll+=0.5
		dedcirc=max(dedcirc-2,20)
		if (dedcirc==20 and btn(5)) run()
		return
	end
	atkcolliders={}
	updbtnpress()
	p.update(p)
	for k,v in pairs(o) do
		v.update(v)
	end
	animatelava()
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
		local y=txtdraw(p.dedmsg,7,false,9)
		if (txtscroll>#p.dedmsg+10) print("❎ retry",10,y+4,7)
	end
end

function gamedraw()
	cls(14)
	
	local camx=clamp(p.x-64,0,curroom.w*8-128)
	local camy=clamp(p.y-64,0,curroom.h*8-128)
	camera(camx,camy)
	
	map(0,0,0,0,curroom.w,curroom.h)
	p.draw(p)
	for k,v in pairs(o) do
		v.draw(v)
	end
	map(0,0,0,0,curroom.w,curroom.h,2)
	--draw ui
	local camx,camy=peek2(0x5f28),peek2(0x5f2a)
	camera()
	drwhp()
	if (currmsg) txtdraw(currmsg,14,true,0)
	camera(camx,camy)
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
	--x-axis collision
	for i=p.x+p.dx,p.x,-(p.dx/abs(p.dx)) do
		if (not solidarea(i,p.y,p.w,p.h)) then
			p.x=i
			break
		end
		p.dx=0
		hit=true
	end
	p.dx*=friction;
	
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
		p.dy+=gravity
	else
		p.dy*=friction
	end
	--limit fall speed
	p.dy=min(p.dy,maxfallspd)
	
	--edge collision
	if (p.x<0) p.x,hit=0,true
	if (p.y<0) p.y,hit=0,true
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

function strtoscrsiz(s,b)
	local ss={}
	while #s>29 do
		for i=flr((128-b*2)/4),10,-1 do
			if ord(s,i)==32 then
				add(ss,sub(s,1,i-1))
				s=sub(s,i+1)
				break
			end
		end
	end
	add(ss,sub(s,1,i))
	return ss
end

function issolid(x,y)
	return fget(mget(x/8,y/8),0)
end

function isgrounded(x,y,w,h)
	if (issolid(x,y+h+1)) return true
	if (issolid(x+w,y+h+1)) return true
	return false
end

function txtdraw(s,col,bubble,offset)
	s=strtoscrsiz(sub(s,1,txtscroll),6)
	local txth=7*#s
	local y=4+(119-txth-offset)*pscrnhalf()
	local xmax=0
	for k,v in pairs(s) do
		if (#v>xmax) xmax=#v
	end
	xmax=6+4*xmax
	if bubble then
		rectfill(3,y+1,xmax+1,y+txth,6)
		line(4,y+txth+1,xmax,y+txth+1,6)
		line(4,y,xmax,y,7)
		line(3,y+1,3,y+txth,7)
	else
		rectfill(3,y,121,y+txth,0)
	end
	for k,v in pairs(s) do
		print(v,6,y+2+(k-1)*7,col)
	end
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

function null()
end




-->8
--player
animspeed=4
jumpforce=2.8
gravity=0.15
acc=0.1
friction=0.9
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
	p.x,p.y,p.dx,p.dy=0,0,0,0
	p.w,p.h=5,7
	p.grav=true
	p.dir=1
	p.timer=0
	p.spr=0
	p.animoffset=0
	p.drwoff=-1
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
	
	if (maphurt(p)) playerdmg("just wanted to dip his toes in")
	chaparticles(p)
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
	--x-axis input
	if (btn(0)) then
		p.dir=-1
		if (not btn(3)) then
			p.dx-=acc;
		end
	end
	if (btn(1)) then
		p.dir=1
		if (not btn(3)) then
			p.dx+=acc;
		end
	end
	
	--run particles
	local pspeed=abs(p.dx)
	if isgrounded(p.x,p.y,p.w,p.h) and pspeed>0.2 then
		if (randchance(10)) then
			partatp(p,-p.dx/10,-pspeed/5,20,7)
		end
	end

	--jump
	if btnd(2) and isgrounded(p.x,p.y,p.w,p.h) then
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
		if (isgrounded(p.x,p.y,p.w,p.h)) then
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

function playerdmg(dedmsg)
	if p.dmgtim<=0 then
		p.hp-=1
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
function initmapemitter(x,y,w,f,t,col)
	local e={}
	e.x,e.y,e.w,e.f,e.t,e.col=x,y,w,f,t,col
	e.update=emitterupdate
	e.draw=null
	add(o,e)
end

function emitterupdate(e)
	if randchance(e.f) then
		local x=e.x+rnd(e.w)
		local dx=rnd(1)-0.5
		initpart(x,e.y,dx,-rnd(1),e.t,e.col)
	end
end

function chaparticles(p)
	local mspace=mget((p.x+4)/8,(p.y+4)/8)
	if mspace==17 or mspace==20 or mspace==24 or mspace==40 then
		if randchance(2) then
			local x=p.x+p.drwoff+rnd(p.w)
			local dx=rnd(1)-0.5
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
-->8
--map
rooms={
--1:detailed starting area
	{w=16,h=16,
		data="qarerq_?cebfuebeaq+maa6irebf?lqeuqre6<)aamda6ereu<)arqbfri=fxq+m[arerq_?cebfuebeam9n[m9ire_j02cguqre8aaa[aaa86_j0ucj06bgreda+m+fxabg0qsj?lag#6bn+qtn[m9ir6se!6bku6se+aaa+aaaqe8i7ice7ici7a_faqdnaica5mdo)mda)a6iaq9n+aqi[<ca;adia<ae_aan+y7esa-d+6+d-aam7e=faa-e7ice5aan5udn;q+npaaa9aam8acaa<=maa-m[<_m[mbaai8ix2rix2bex2rmxa-i6a7i6<)csu7i8ica",
		exts={
			{dir="⬅️",l=9,h=11,r=2,dp=2},
			{dir="➡️",l=13,h=13,r=2,dp=0},
			{dir="➡️",l=10,h=10,r=2,dp=0},
			{dir="⬆️",l=10,h=13,r=5,dp=-5},
		},
		enms={
			{typ=1,x=6,y=6.5},
			{typ=3,x=9,y=7},
			{typ=2,x=13,y=4},
			{typ=2,x=3,y=13},
			{typ=3,x=8,y=13},
		},	
	},
--2:long lava halls
	{w=26,h=16,
		data=".abeam_?ka-e?pae?x6mqaba9aan+<5bay7evasiqaba[aaa[aaeqa-e?paa[<?aambe8admqabn{mdn}m9m-a-i?paa+aaawirfqe=?daba+a-m[aaa7a-e?paawi7evasi8abe6e8i?pae6eceqa-i?paa9asi8<)a-abe-edmqici7atmqabat<?aam_?fi9iqa_?didm=<?aqa-iaqdnamca[<?aa<)a=q+?ea6m6e8iambaaq+mt<)aaq+?daan[m+?ea6m_ida9<?aam=?ca-mam+m?paa+<pbaa7esu7i?laatmda[qda+udn+aan}mdaaq+m=asi=i+m+a-iam+m?laa+aaa+aan[<)aaqdn=idn{<)a[mba+u+m?laaqasi8a-m[a-m{q+?ca-m?laa9<)aaq+maasi-edmq<?aamda7a7iqabi7m7iqasiqicm_asi6eceaa6i6esm8a9i8atm9a9i-e9i-a7i-edm_abaaadm_a",
		exts={	
			{dir="⬅️",l=13,h=13,r=1,dp=0},
			{dir="⬅️",l=10,h=10,r=1,dp=0},
			{dir="➡️",l=11,h=13,r=1,dp=-2},
			{dir="⬇️",l=21,h=22,r=3,dp=-14},
			{dir="⬇️",l=7,h=7,r=4,dp=-1},
		},
		enms={
			{typ=1,x=6,y=7},
			{typ=2,x=3,y=13},
			{typ=3,x=8,y=13},
			{typ=3,x=10,y=13},
		},
		msg="welcome to the evil lava dungeon god this text is cheesy"
	},
--3:tall jumping room
	{w=16,h=24,
		data="q6bi7<pbqaaa?tae6ecm_<?caatmq<5baasi?xaaqa_?daaeqatmqa_?da6iq<5daide?|aa6ece?@aaqasi-e+?laam_a_?naaeq<)aaabi7<)aqi=?daaeq<?aaatmqaaa=aaa?pae?)aa6ece6ece?@aa-ede-e+?laai7a_?daae?5aa-ede?paaqi=?haaeq<?aaa7m6ece?taaqa_?daaeqatmqa_?daaeq<5daabe?}aaqa_?naaeq<5daabe?}aaqa_?naaea",
		exts={
			{dir="⬆️",l=7,h=8,r=2,dp=14},
			{dir="⬇️",l=1,h=14,r=1,dp=0},
			{dir="➡️",l=5,h=5,r=4,dp=-4},
		}
	},
--4:lavafall room with platforms
	{w=16,h=16,
		data="qa7i=i8i-e+i=icm_i8mqicm?xaat<)baasiq<pbam=?gaam_asi?paat<)baasi-edi7aaa9<)baatm6ecm_a6it<)baasi-e+?ca6m9aaaq<?aaatm6e=?da-e?1aa6ecm_<?aam=?eaaeaatm6e=?da-e?1aa6ecm_<)aayrf?laaq<)aaatm6e=?ca-eq<)baasi-e+?ca-iaaae?taa-edi7aaeam_?haai7atm?l6ev<?bsatm6eci7asi6eci7asi6eci7a",
		exts={
			{dir="⬅️",l=1,h=1,r=3,dp=4},
		}
	},
--5:tower climb
	{w=16,h=16,
		data="qarerqreq<)axmdnq<)arq_?cebfrabaamdn{i=?cebf?lqeuebe?paa+e=?cebf?lqeuebm[aaax27i?lqeu<)arqre+2dnamda_<)arq_?cebfrqda+<)aaa_?cebf?lqeuadi72baamdm?lqeu<)arqre8edaam9n[<)arq_?cebfraba+aaa[m+?cebf?lqeuebe+aaax2ri_ereu<)arqre62dn?laa6<)arq_?cebfra=?eaae?lqeu<)arqreq2_famdn8<)arq_?cebfrica[a-m{a=?cebf?lqeue7iaa-maa6i?lqeu<)arqreq<)aa2_f-<)arqrea",
		exts={
			{dir="⬇️",l=5,h=8,r=1,dp=5},
			{dir="⬆️",l=8,h=9,r=6,dp=0},
			{dir="⬇️",l=0,h=3,r=1,dp=0},
			{dir="⬇️",l=11,h=15,r=1,dp=-11},
		},
		enms={
			{typ=1,x=7,y=4},
			{typ=3,x=6,y=11},
			{typ=3,x=8,y=8},
		}
	},
--6:tower top
	{w=16,h=16,
		data="qarerqrerqreu<?arqbf?pqeuereuebf?pqeuq_?debfrebfrq_?debfu<?arqrerqreu<?arqbf?pqeuereuebf?pqeuq_?debfrebfrq_?debfu<?arqrerqreu<?arqbf?pqeuereuebf?pqeuq_?debfrebfrq_?debfu<?arqrerqreu<?arqbf?pqeuereuebf?pqeuq_?debfrebfrqbf?lqeuq_?debfqebfrq_?cebirq_?debf-acf?p-f8eteu<?arqbf8qbnaa-mqqreu<?arqbfq<)axaan6qreuerera",
		exts={
			{dir="⬇️",l=8,h=9,r=5,dp=0},
			{dir="⬇️",l=0,h=3,r=5,dp=0},
			{dir="⬇️",l=11,h=15,r=5,dp=0},
		}
	},
--7:intro forest
	{w=40,h=16,
		data="#areu<)arqreuereuebfrebfuebfrebfrebfrqbfrebfrqrerqrerqbfrq_?cebfrqrerqreuereuqreuereuereuebfuereuebfrebfrebfuebf?lqeuebfrebfrqrerqbfrqrerqrerqreuqrerqreuereuereuqreu<)arqreuereuebfrebfuebfrebfrebfrqbfrebfrqrerqrerqbfrq_?cebfrqrerqreuereuqreuereuereuebfuereuebfrebfrebfuebf?lqeuebfrebfrqrerqbfrqrerqrerqreuqrerqreuereuereuqreu<)arqreuereuebfrebfuebfrebfrebfrqbfrebfrqrerqrerqbfrq_?cebfrqrerqreuereuqreuereuereuebfuereuebfrebfrebfuebf?lqeuebfrebfrqrerqbfrqrerqrerqreuqrerqreuereuereuqreu<)arqreuereuebfrebfuebfrebfrebfrqbfrebfrqrerqrerqbfrqrer6bfrqrerqreuereuqreuereuereuebfuereuebfrebfrebfuebg@6bgu2=jy6reyq_jr6bfrqrerqrerqreuqrerqreuereuereuqbg@qcjy2cj 2=jy6_j0qcgyebfrebfrebfrqbfrebfrqrerqrerqbfyqsj06=j0u=?cqcg0ucjy6reuereuereuebfuereuebfrebfrebfuebk!#bkr#7j#yse##7jr6cfrqrerqrerqreuqrerqreuereuereuqrg$0rg$0sgz0sgz0skz0rk$0rg$<)az0sg$0rkz0sg$0sgz0sgz0sga",
		exts={
		}
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
		currmsg=curroom.msg
		curroom.msg=nil
		txtscroll=0
	else
		currmsg=nil
	end
	initmapemitters(curroom)
end

function initmapemitters(room)
	for i=0,room.w-1 do
		for j=0,room.h-1 do
			local cur=mget(i,j)
			local below=mget(i,j+1)
			if cur==17 or cur==20 or cur==24 or cur==40 then
				if fget(below,0) then
					initmapemitter(i*8,j*8+8,8,5,4,12)
				elseif below==18 or below==22 then
					initmapemitter(i*8,j*8+13,8,1,10,6)
				end
			elseif cur==18 then
					initmapemitter(i*8,j*8+5,8,100,5,10)
					initmapemitter(i*8,j*8+5,8,50,5,9)
			elseif cur==53 or cur==54 or cur==55 then
					initmapemitter(i*8+3,j*8+4,0,10,6,9)
			end
		end
	end
end

function animatelava()
	framecount+=1
	if framecount%30==0 then
		scrollsprh(18)
		scrollsprv(19,2)
	end
	if framecount%10==0 then
		switchspr(53,54)
		switchspr(54,55)
	end
	scrollsprv(15,3)
	scrollsprv(17,1)
	scrollsprv(20,1)
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
	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("memory=",0,12,7)
	print(stat(0),28,12,7)
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

function boxpointoverlap(px,py,bx,by,bw,bh)
	return px>bx 
				and px<bx+bw
		  and py>by 
		  and py<by+bh
end

function boxboxoverlap(a,b)
 return not (a.x>b.x+b.w 
	         or a.y>b.y+b.h 
	         or a.x+a.w<b.x 
	         or a.y+a.h<b.y)
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
		--bat
		{upd=batupd,
			grav=false,
			w=7,h=4,hp=1,
			dedspr=80,drwoff=0,
			dedmsg="was torn to shreds by a bat",
			},
		--zombie
		{upd=zomupd,
			grav=true,
			w=5,h=7,hp=2,
			dedspr=81,drwoff=-1,
			dedmsg="was mutilated by a zombie",
		},
		--skeleton
		{upd=skelupd,
			grav=true,
			w=5,h=7,hp=3,
			dedspr=82,drwoff=-1,
			dedmsg="got boned",
		},
		--arrow
		{upd=arrupd,
			grav=false,
			w=0,h=0,hp=1,
			dedspr=82,drwoff=0,
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
	e.typ=typ
	e.drwoff=typ.drwoff
	e.dmgtim=0
	e.spr=0
	e.dir=1
	e.update=typ.upd
	e.draw=edraw
	add(o,e)
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
	if not issolid(e.x+e.w/2+e.w/2*e.dir,e.y+8) and isgrounded(e.x,e.y,e.w,e.h)then
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
		if not issolid(e.x+e.w/2+e.w/2*e.dir,e.y+8) and isgrounded(e.x,e.y,e.w,e.h)then
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
			arr.dx,arr.dy=e.dir*5,rnd(0.5)-0.25
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
			initpart(e.x+e.w/2,e.y+e.h/2,rnd(1)*hitdir-0.2*hitdir,rnd(1)-0.5,5+rnd(10),2)
		end
		e.dir=-(e.x-p.x)/abs(e.x-p.x)
		e.dmgtim=10
		e.hp-=1
	end
end

function hitplayer(e)
	if boxboxoverlap(p,e) then
		playerdmg(e.typ.dedmsg)
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
00000000600500c0600500c0000500d000500000605005000050500000050000050005000500050060005d200005005000000000000000000000000000000000
0555555b100000000000000000000a98c00000000000098200000000444444440101010033b33333010101000000000000000000000000000000000000000000
5555555b100010000000000000000898001000000000099800000000bb4bbb4b00101010333333e3001010100000000000000000000000000000000000000000
555555bb10001000000000000000098900100100000009a90000000000b000b0011101013e33e3ee011101010000000000000000000000000000000000000000
bbbbbbbb00001010000000000000098900100100000098a9000000000040004010101110ee3eeeeb101011100000000000000000000000000000000000000000
555bb555001000100000000000000a8900000c0000aa98980000000000b000b001011101eeedebde010111010000000000000000000000000000000000000000
555b5555001000c088a98889000009990000000099a9a889000000a9bbbbbbbb10110100ddeeebbe101101000000000000000000000000000000000000000000
55bb555500c000002988298800000989100000008898982800000a980000000001011010bbeeeeee010130100000000000000000000000000000000000000000
bbbbbbbb00000000822282820000098a1000000029828289000009820000000000101100eeeebeee031031000000000000000000000000000000000000000000
555555005555555b5555555b0000098800303000000400000304400300000000100b010033333300000000000000000000000000000000000000000000000000
555555505555555b555555bb00000a8830330303303b0400000b4030030003000100b00133e33333000000000000000000000000000000000000000000000000
5555555b55bb55bb5555bb5b0000098903033030341b0444000b400000303030110b1010e3e3e3ee000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbb0000092933333333034b4403000b4000030303331b0bb100eeeeeeeb000000000000000000000000000000000000000000000000
555b5555555b555555bb555500000888133133133103b030004440003031331310bbb0b0eddeebde000000000000000000000000000000000000000000000000
555b5555555b5555555b555500000a89313313034004b01300b4400303031303010bbb01bbddebbe000000000000000000000000000000000000000000000000
555bb55555bbbb55555b555500000a88031011300444b00000b3440303103130000bb000bbbbeeee000000000000000000000000000000000000000000000000
bbbbbbbbbbbb0bbbbbbbbbbb000009983103000030bb04000b43b30331031313000bb000ebbeeebe000000000000000000000000000000000000000000000000
5555555b5555555bcccccccc000000000000000000b0b000b0b0b00000b0b0b0005b000000000000000000000000000000000000000000000000000000000000
5555555b5555555bcccccccc0000000b0000000b0b0b0b000b0b0b000b0b0b0b0050000000000000000000000000000000000000000000000000000000000000
0555555b55555bb0cccccccc0000000b0000000bb0bbb0b0b09bb0b000bb90b000b5000000000000000000000000000000000000000000000000000000000000
0bbbbbbbbbbbb000ccccccccb0bbbbbbbbbbbb0b0bbabb000bbabb000bbabb000005000000000000000000000000000000000000000000000000000000000000
0b5bbb5555b00000cccccccc000b0000000b0000b0bbb0b0b0bbb00000bbb0b0005b000000000000000000000000000000000000000000000000000000000000
00bb5555555b0000cccccccc000b0000000b00000b090b000b09000000090b000050000000000000000000000000000000000000000000000000000000000000
00005555555b5000cccccccc000b00000000000000040000000400000004000000b5000000000000000000000000000000000000000000000000000000000000
0000000bbbbbb000ccccccccbbbbb00000000000000b0000000b0000000b00000005000000000000000000000000000000000000000000000000000000000000
00111000110001100000000000000000000000000006600000066000000660000006600000400000004000000000000000000000000000000000000000000000
11a1a110bb111bb00003200000320000000320000006600000066000000660000006600004006600040066000000000000000000000000000000000000000000
1b111b1000a1a00003e330003e33000003e330004000060000000000000006040000000004006600040066000000000000000000000000000000000000000000
b00000b000111000000eb000000eb000000eb0004006506000065040000650040000604006660000066600600444446000000000000000000000000000000000
000000000000000003bb000003bbb00003bb00000600006000060400060000600006040004005600040056600000000000000000000000000000000000000000
0000000000000000000eb000000eb000000eb0000040600000445000000544000044500004066000040005000000000000000000000000000000000000000000
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
__gff__
0000000000000000000000000000000201000200000200010001000000000002010101000102020100010200000000020101000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111111141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1114111118141114111114111411111414111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1118271818142727181811181427111814111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1827242418272425272718182724241818111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1824252428272425242424182425241818111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1128261a28111a26282611281a26112814111411111411111411141411111411141111141111141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1929191929291919291919292919192929191929191919291929192919291929291919291919291900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0013001f1d6201e62021620216201d620136201b6201b620176201c620196201c620196201e620196201e6201f62020620206202062020620206201c620176201b6201c6201c6201e6201b6201d6201d6201d620
__music__
02 00424344

