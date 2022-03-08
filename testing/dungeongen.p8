pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
	initgenstages()
	newroomlayout()
end

function _update()
	genstages[genstage]()
end

function _draw()
	cls()
	camera(-64,-64)
	for k,v in pairs(rooms) do
		rectfill(v.x,v.y,v.x+v.w,v.y+v.h,5)
		rect(v.x,v.y,v.x+v.w,v.y+v.h,6)
	end
	for k,v in pairs(lockedrooms) do
		rectfill(v.x,v.y,v.x+v.w,v.y+v.h,5)
		rect(v.x,v.y,v.x+v.w,v.y+v.h,7)
	end
	for k,v in pairs(doors) do
		pset(v.x,v.y,5)
	end
end

-->8
--room generation

function initgenstages()
	genstages={
		spreadrooms,
		collapserooms,
		doors,
		done,
	}
end

--init the room generation
function newroomlayout()
	genstage=1
	rooms={}
	lockedrooms={}
	doors={}
	
	for i=0,50 do
		local dx,dy=rnd(2)-1,rnd(2)-1
		local l=sqrt(dx*dx+dy*dy)
		dx,dy=dx/l,dy/l
		
		add(rooms,
			{
				w=ceil(rnd(10))+3,
				h=ceil(rnd(10))+3,
				x=0,
				y=0,
				dx=dx,
				dy=dy,
				c=ceil(rnd(5))
			})
	end
end

--inital spread of rooms
function spreadrooms()

	--dont destroy list items while looping
	local roomstodel={}
	
	--for each room: 
		--move it
		--check if it overlaps locked rooms
		--if not, lock it
	for k,v in pairs(rooms) do
		v.x+=v.dx
		v.y+=v.dy
		if not listoverlap(v,lockedrooms) then
			add(roomstodel,v)
			v.x=flr(v.x)
			v.y=flr(v.y)
			add(lockedrooms,v)
		end
	end
	
	--remove locked rooms from list
	for k,v in pairs(roomstodel) do
		del(rooms,v)
	end
	
	--check if finished spreading
	if #rooms==0 then
	 genstage=2
	 for k,v in pairs(lockedrooms) do
	 	add(rooms,v)
	 end
	 lockedrooms={}
	end
end

function collapserooms()
	local roommoved=false
	for k,v in pairs(rooms) do
		local dirx,diry=sgn(v.x),sgn(v.y)
		
		--check and move x
		if abs(v.x)>1 then
			v.x-=dirx
			local solid
			if listoverlap(v,rooms) then
				v.x+=dirx
			else
				roommoved=true
			end
		end
		
		--check and move y
		if abs(v.y)>1 then
			v.y-=diry
			local solid
			if listoverlap(v,rooms) then
				v.y+=diry
			else
				roommoved=true
			end
		end
	end
	if not roommoved then
		genstage=3
	end
end

function doors()
	for k,v in pairs(rooms) do
		--local dirx,diry=sgn(v.x),sgn(v.y)
			
			
		v.x-=1
		local solid
		local hit,hitrooms=listoverlap(v,rooms)
		if hit then
			for k,b in pairs(hitrooms) do
				adddoor(v,b)
			end
		end
		v.x+=1
	
		v.y-=1
		local solid
		local hit,hitrooms=listoverlap(v,rooms)
		if hit then
			for k,b in pairs(hitrooms) do
				adddoor(v,b)
			end
		end
		v.y+=1
	end
	genstage=4
end

function adddoor(r1,r2)
	local x1=max(r1.x,r2.x)+1
	local y1=max(r1.y,r2.y)+1
	local x2=min(r1.x+r1.w,r2.x+r2.w)-1
	local y2=min(r1.y+r1.h,r2.y+r2.h)-1
	if x1>=x2 and y1>=y2 then
	 return
	end
	local xmin=min(x1,x2)
	local ymin=min(y1,y2)
	local x=xmin+flr(rnd(max(x1,x2)-xmin))+1
	local y=ymin+flr(rnd(max(y1,y2)-ymin))+1
	add(doors,{x=x,y=y})
end

function done()
end
-->8
--collisions

function listoverlap(a,l)
	local hit,rooms=false,{}
	for k,b in pairs(l) do
		if boxboxoverlap(a,b)
		and a!=b then 
			hit=true
			add(rooms,b)
		end
	end
	return hit,rooms
end

function boxboxoverlap(a,b)
 return not (a.x>=b.x+b.w
	         or a.y>=b.y+b.h 
	         or a.x+a.w<=b.x 
	         or a.y+a.h<=b.y)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
