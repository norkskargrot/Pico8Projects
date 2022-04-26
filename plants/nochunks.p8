pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
p={}
s={}

function _init()
	for i=0,50 do
		newpart()
	end
	
	n={}
	n.p1=p[flr(rnd(50))+1]
	n.p2=p[flr(rnd(50))+1]
	add(s,n)
	
	framecount=0
end

function _update()
	framecount+=1
	--[[
	if framecount%10==0 then
		local op=s[#s].p1
	 local np=newpart()
	 np.x=op.x
	 np.y=op.y
	 s[#s].p1=np
	 add(s,{p1=op,p2=np})
	end
	]]--
	
	for i=1,#p do
		local pi=p[i]
		for j=i+1,#p do
			local pj=p[j]
			local dx,dy=pi.x-pj.x,pi.y-pj.y
			local d=dist(dx,dy)
			if d<10 then
			 pi.dx+=dx/d
			 pj.dx-=dx/d
			 pi.dy+=dy/d
			 pj.dy-=dy/d
			end
		end
	end
	
	for k,v in pairs(s) do
		local p1=v.p1
		local p2=v.p2
		local dx,dy=p1.x-p2.x,p1.y-p2.y
		local d=dist(dx,dy)
		local a=(d-8)*0.1
		local ax=a*dx/d
		local ay=a*dy/d
	 p1.dx-=ax
	 p2.dx+=ax
	 p1.dy-=ay
	 p2.dy+=ay
	end
	
	for k,v in pairs(p) do
		v.dx*=0.8
		v.dy*=0.8
		v.x=min(max(v.x+v.dx,0),127)
		v.y=min(max(v.y+v.dy,0),127)
	end
end

function _draw()
 cls()
	for k,v in pairs(s) do
		line(v.p1.x,v.p1.y,v.p2.x,v.p2.y,7)
	end
	for k,v in pairs(p) do
		circfill(v.x,v.y,2,7)
	end
	print(stat(1),1,1)
end
-->8
function newpart()
	local n={}
	n.x,n.y=rnd(127),rnd(127)
	n.dx,n.dy=rnd(1)-0.5,rnd(1)-0.5
	add(p,n)
	return n
end

function dist(dx,dy)
 local maskx,masky=dx>>31,dy>>31
 local a0=(dx+maskx)^^maskx
 local b0=(dy+masky)^^masky
 if a0>b0 then
  return a0*0.9609+b0*0.3984
 end
 return b0*0.9609+a0*0.3984
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
