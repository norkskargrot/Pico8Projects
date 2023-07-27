pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
o={}
framecount=0
btnpress={}

function _init()
	curroom=rooms[1]
	decompresmap(0,0,curroom.data)
	initplayer()
	initmapemitters(curroom)
	
	for i=0,5 do
		btnpress[i]=0
	end
end

function _update60()
	updbtnpress()
	for k,v in pairs(o) do
		v.update(v)
	end
	animatelava()
end

function _draw()
	cls(14)
	
	local camx=clamp(p.x-64,0,curroom.w*8-128)
	local camy=clamp(p.y-64,0,curroom.h*8-128)
	camera(camx,camy)
	
	map(0,0,0,0,curroom.w,curroom.h)
	for k,v in pairs(o) do
		v.draw(v)
	end
	map(0,0,0,0,curroom.w,curroom.h,2)
	--drawlogs()
	--drawgates()
end

function drawspri(x,y,spri,flp)
	for i=0,15 do
		pal(i,0)
	end
	local camy=peek2(0x5f2a)
	clip(0,0,127,y+8-camy)
	spr(spri,x+1,y,1,1,flp,false)
	spr(spri,x-1,y,1,1,flp,false)
	spr(spri,x,y+1,1,1,flp,false)
	spr(spri,x,y-1,1,1,flp,false)
	resetpal()
	clip()
	spr(spri,x,y,1,1,flp,false)
end

function solidarea(x,y)
	if (issolid(x,y)) return true
	if (issolid(x+7,y)) return true
	if (issolid(x,y+7)) return true
	if (issolid(x+7,y+7)) return true
	return false
end

function issolid(x,y)
	return fget(mget(x/8,y/8),0)
end

function isgrounded(x,y)
	if (issolid(x,y+8)) return true
	if (issolid(x+7,y+8)) return true
	return false
end

function resetpal()
	pal()
	pal(14,128,1)
	pal(3,131,1)
	pal(4,132,1)
	pal(11,133,1)
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
	
function initplayer()
	p={}
	p.x=0
	p.y=0
	p.dx=0
	p.dy=0
	p.dir=true
	p.timer=0
	p.spr=0
	p.animoffset=0
	
	p.update=pnormal
	p.draw=pdraw
	add(o,p)
end

function palways(p)
	--x-axis collision
	for i=p.x+p.dx,p.x,-(p.dx/abs(p.dx)) do
		if (not solidarea(i,p.y)) then
			p.x=i
			break
		end
	end
	p.dx*=friction;
	
	--y-axis collision
	for i=p.y+p.dy,p.y,-(p.dy/abs(p.dy)) do
		if (not solidarea(p.x,i)) then
			p.y=i
			break
		end
		if (abs(i-p.y)<2) then
			p.dy=0
		end
	end
	
	--gravity
	p.dy+=gravity;
	--limit fall speed
	p.dy=min(p.dy,maxfallspd)
	
	--edge collision
	if (p.x<0) p.x=0
	if (p.y<0) p.y=0
	local xmax=curroom.w*8-8
	if (p.x>xmax) p.x=xmax
	local ymax=curroom.h*8-8
	if (p.y>ymax) p.y=ymax
	
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
	
	--particles when in rain
	local mspace=mget((p.x+4)/8,(p.y+4)/8)
	if mspace==17 or mspace==20 then
		if randchance(4) then
			local x=p.x+rnd(8)
			local dx=rnd(1)-0.5
			initpart(x,p.y,dx,-rnd(1),4,12)
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
	--x-axis input
	if (btn(0)) then
		p.dir=true
		if (not btn(3)) then
			p.dx-=acc;
		end
	end
	if (btn(1)) then
		p.dir=false
		if (not btn(3)) then
			p.dx+=acc;
		end
	end
	
	local pspeed=abs(p.dx)
	if isgrounded(p.x,p.y) and pspeed>0.2 then
		if (randchance(10)) then
			partatp(p,-p.dx/10,-pspeed/5,20,7)
		end
	end

	--jump
	if btnd(2) and isgrounded(p.x,p.y) then
		p.dy=-jumpforce;
		partatp(p,-0.3,-0.25,10,7)
		partatp(p,0.25,-0.2,10,7)
		partatp(p,-0.5,0,10,7)
		partatp(p,0.5,0,10,7)
	end
	
	
	if btnd(4) then 
		p.update=pattack
		p.timer=animspeed*4
	end
end

function pattack(p)
	palways(p)
	p.timer-=1
	p.spr=6
	p.animoffset=1
	if (p.timer<=animspeed*3) then
		p.spr=7
		p.animoffset=2
	end
	if (p.timer<=animspeed*2) then
		p.spr=8
		p.animoffset=4
	end
	if (p.timer<=animspeed) then
		p.spr=9
		p.animoffset=4
	end
	if (p.timer<=0) then
		p.update=pnormal
		local newx=p.x+2*dirtoi(p.dir)
		if not solidarea(newx,p.y) then
			p.x=newx
		end
		p.spr=0
		p.animoffset=0
	end
end

function pdraw(p)
	if (p.spr==0) then
		local spri = flr(time()*6)%3+1
		if (isgrounded(p.x,p.y)) then
			if btn(3) then 
				spri=5
			elseif abs(p.dx)>0.1 then
				local val=flr(time()*6)%4
				if val==0 then
					spri=1
				elseif val==1 then
					spri=10
				elseif val==2 then
					spri=11
				elseif val==3 then
					spri=10
				end
			end
		else
			spri=4
		end
		drawspri(p.x,p.y,spri,p.dir)
	else
		local x=p.x+p.animoffset*dirtoi(p.dir)
		drawspri(x,p.y,p.spr,p.dir)
	end
end

function dirtoi(dir)
	if (dir) then
	 return -1
	else
	 return 1
	end
end

function partatp(p,dx,dy,t,col)
	initpart(p.x+3,p.y+7,dx,dy,t,col)
end


-->8
--particles
function initmapemitter(x,y,f,t,col)
	local e={}
	e.x=x
	e.y=y
	e.f=f
	e.t=t
	e.col=col
	e.update=emitterupdate
	e.draw=null
	add(o,e)
end

function emitterupdate(e)
	if randchance(e.f) then
		local x=e.x+rnd(8)
		local dx=rnd(1)-0.5
		initpart(x,e.y,dx,-rnd(1),e.t,e.col)
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
	{w=16,h=16,
		data="qarerq_?cebfuebeaq+maaaerebf?lqeuqreq<)aamdaqereu<)arqbfra_fxaan[arerq_?cebfuebe?paa+iser2cj@ebfue7i[mdnaa6mr2cj qcjuqre=m+ma2_fqebj0u=haqbfrq+?eaaera-d!<caui9mqaaa?l-mq<pb=aaf5aaexaaa[a6ia<baa<cau<caq<pbaidn)aaaqicfpasi+q+mwi7ea<-m+<6mu<)a=2baambe6a_haq+haqba[a-daa-iaidi7aaa)mdfamdn5mdntaaa-e+fxi+fxi+fxidaamci7abi?,6evatma",
		exts={
			{dir="⬅️",l=9,h=11,r=2,dp=2},
			{dir="➡️",l=13,h=13,r=2,dp=0},
			{dir="➡️",l=10,h=10,r=2,dp=0},
			{dir="⬆️",l=10,h=13,r=5,dp=-5},
		}
	},
	{w=26,h=16,
		data=".abeam_?ka-e?pae?x6mqaba9<pcay7evasiqa_?faaeqa-e?9aata7i-adeq<5baidmam=?ga6fsube7<?aq<)baecat<?aay7esubi7iceqasi8<?aqasiqaba9<?aamci7i=?cadeqatm-a7i6ecm_abeam_?da-e?x6m8abe?p6m-i+?daba9<?aam=?fa-?ci+?fa6m6e8iam_?da-e??aa=e9mam=?da-i?dbaqi7evi=?ca-e?dba=asi=i+?ca-i?hba=i+?ea-e?1aaqasi8<5dam=?faai7atm-a_?faqiqiceqasitice6ece8atm6eci7abaaici7e9i-i8i-e+i-icm_icmqicm_atmqaaa-atma",
		exts={	
			{dir="⬅️",l=13,h=13,r=1,dp=0},
			{dir="⬅️",l=10,h=10,r=1,dp=0},
			{dir="➡️",l=11,h=13,r=1,dp=-2},
			{dir="⬇️",l=21,h=22,r=3,dp=-14},
			{dir="⬇️",l=7,h=7,r=4,dp=-1},
		}
	},
	{w=16,h=24,
		data="q6bi7<pbqaaa?tae6ecm_<?caatmq<5baasi?xaaqa_?daaeqatmqa_?da6iq<5daide?|aa6ece?@aaqasi-e+?laam_a_?naaeq<)aaabi7<)aqi=?daaeq<?aaatmqaaa=aaa?pae?)aa6ece6ece?@aa-ede-e+?laai7a_?daae?5aa-ede?paaqi=?haaeq<?aaa7m6ece?taaqa_?daaeqatmqa_?daaeq<5daabe?}aaqa_?naaeq<5daabe?}aaqa_?naaea",
		exts={
			{dir="⬆️",l=7,h=8,r=2,dp=14},
			{dir="⬇️",l=1,h=14,r=1,dp=0},
			{dir="➡️",l=5,h=5,r=4,dp=-4},
		}
	},
	{w=16,h=16,
		data="qa7i=i8i-e+i=icm_i8mqicm?xaat<)baasiq<pbam=?gaam_asi?paat<)baasi-edi7aaa9<)baatm6ecm_a6it<)baasi-e+?ca6m9aaaq<?aaatm6e=?da-e?1aa6ecm_<?aam=?eaaeaatm6e=?da-e?1aa6ecm_<)aayrf?laaq<)aaatm6e=?ca-eq<)baasi-e+?ca-iaaae?taa-edi7aaeam_?haai7atm?l6ev<?bsatm6eci7asi6eci7asi6eci7a",
		exts={
			{dir="⬅️",l=1,h=1,r=3,dp=4},
		}
	},
	{w=16,h=16,
		data="qarerq_lq<)axaaaqaqerq_?cebfpa_?ea6iaereu<)arq_hq<pbaidarebf?lqeu<ce?paaxicarebf?lqeu<-h?taa=aqerq_?cebf5<=?eaaeaereu<)arqbe6e=fxaaaqarerq_?cebfaatm?taapereu<)arqbaq<5ba<rerq_?cebfaa_?ca-fxi=lrebf?lqeuaae?taa=<qerq_?cebfaa_?eaae5ereu<)arqbaq2_?daae)ereu<)arqba8<pbaa_drebf?lqeua6m?taa8<rerq_?debaq<?aa27m)<?areba",
		exts={
			{dir="⬇️",l=5,h=8,r=1,dp=5},
			{dir="⬆️",l=8,h=9,r=6,dp=0},
			{dir="⬇️",l=0,h=3,r=1,dp=0},
			{dir="⬇️",l=11,h=15,r=1,dp=-11},
		}
	},
	{w=16,h=16,
		data="qa_?chbe?1qeq<)braber<?axabe?1qepare?paaqa-?ge_hq<)axaaaqa-?derea",
		exts={
			{dir="⬇️",l=8,h=9,r=5,dp=0},
			{dir="⬇️",l=0,h=3,r=5,dp=0},
			{dir="⬇️",l=11,h=15,r=5,dp=0},
		}
	},
}

function changeroom(e)
	curroom=rooms[e.r]
	memset(0x2000,0,0x1000)
	decompresmap(0,0,curroom.data)
	o={}
	add(o,p)
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
	initmapemitters(curroom)
end

function initmapemitters(room)
	for i=0,room.w-1 do
		for j=0,room.h-1 do
			local cur=mget(i,j)
			local below=mget(i,j+1)
			if cur==17 or cur==20 then
				if fget(below,0) then
					initmapemitter(i*8,j*8+8,5,4,12)
				elseif below==18 or below==22 then
					initmapemitter(i*8,j*8+13,1,10,6)
				end
			elseif cur==18 then
					initmapemitter(i*8,j*8+5,100,5,10)
					initmapemitter(i*8,j*8+5,50,5,9)
			end
		end
	end
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

function animatelava()
	framecount+=1
	if framecount%30==0 then
		scrollsprh(18)
		scrollsprv(19,2)
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
	local l=peek4(addr+rowcount*64)
	for i=rowcount,1,-1 do
		local cur=addr+i*64
		local nxt=cur-64
		poke4(cur,peek4(nxt))
	end
	poke4(addr,l)
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

function clamp(val,l,h)
	return min(h,max(l,val))
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

__gfx__
00000000000000000000000000000000000000000000000007600000007777700070770000000000000000000000000000000000000000000000000000010000
0000000000000b500000000000000b5060055000000000007060ff000700ff070000ff700000ff700000000000000ff000000000000000000000000000010000
0070070000000ff000000b5000000ff0600ff000000ff02070f0ff000000ff060200ff070200ff0000000ff000000ff000000000000000000000000000010000
000770000000500000000ff00005500006000f20000ff002700f000002ff00062f0f00072f0f000700000ff0000ff000000000000000000000000000000c0000
000770000005b5500005500000f0b50200f5502200ff00f2000fff00020ff0f020ffff6620fff007000ff00000f0ff0200000000000000000000000000000000
0070070000f0b50200f0b5020600b520000550000f0ff002002ff200020f0f0000ff000000ff0f0700f0ff020600ff2000000000000000000000000000000000
0000000006005020060050206000502000500500600f0f00000ff000000f00000f00f0000f00f0660600f02060000f2000000000000000000000000000000000
00000000600b0020600b0020000b00000050000060f00f0000f0f000000f00000f000f000f000f006000f020000f00f000000000000000000000000000000000
0555555b100000000000000000000a98000100000000098200000000444444440000000000000000000000000000000000000000000000000000000000000000
5555555b100010000000000000000898010000000000099800000000bb4bbb4b0000000000000000000000000000000000000000000000000000000000000000
555555bb10001000000000000000098901000100000009a90000000000b000b00000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb0000101000000000000009890d000100000098a900000000004000400000000000000000000000000000000000000000000000000000000000000000
555bb555001000100000000000000a8900000d0000aa98980000000000b000b00000000000000000000000000000000000000000000000000000000000000000
555b5555001000d088a98889000009990000000099a9a889000000a9bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
55bb555500d000002988298800000989000100008898982800000a98000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb00000000822282820000098a000100002982828900000982000000000000000000000000000000000000000000000000000000000000000000000000
0005555b555555505555550000000988003030000004000003044003000000000000000000000000000000000000000000000000000000000000000000000000
0555555b555555505555555000000a8830330303303b0400000b4030030003000000000000000000000000000000000000000000000000000000000000000000
5b55555b555555505555555b0000098903033030341b0444000b4000003030300000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbb0000092933333333034b4403000b4000030303330000000000000000000000000000000000000000000000000000000000000000
555b5555555b5555555b555500000888133133133103b03000444000303133130000000000000000000000000000000000000000000000000000000000000000
555b5555555b5555555b555500000a89313313034004b01300b44000030313030000000000000000000000000000000000000000000000000000000000000000
555b5555555b5555555b555500000a88031011300444b00000b44400031031300000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbb000009983103000030bb04000b44b400310313130000000000000000000000000000000000000000000000000000000000000000
5555555b5555555b5555555b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555b5555555b5555555b0000000b0000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555bb555555b5555555b0000000b0000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbb0b0009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
555b5555555b555555bb55b5000b0000000b00000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
555b5555555bb555bbbbbbbb000b0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555b555555bbb550bbbb0bbb000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbb0000000000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000201000200000200010002020000000002010101000102020102020200000000020101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111141111111414111000343300001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111141111111414111000000033001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111141111111414111017170034341000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111141111111414111000000000332200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111272427111414112234333400003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1127242524241414113233330017171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
112424251f001414113400000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000f262f001432321000003333331000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323232323200141f001017000034002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001f00002f00142f001000000000003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
342f00001022140f202133343316121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f33330f321432323217000013102000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101f00341f00140034000f000023003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202100002f33140033341f333413000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3031171732171732171732000023202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1020121212121212121212121215303100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0013001f1d6201e62021620216201d620136201b6201b620176201c620196201c620196201e620196201e6201f62020620206202062020620206201c620176201b6201c6201c6201e6201b6201d6201d6201d620
__music__
02 00424344

