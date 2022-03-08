pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
	pinit()
	states={pturn,pmov}
	state=1
end

function _update()
	states[state]()
	updbtns()
end

function _draw()
	cls()
	circfill(p.x,p.y,7,6)
	if state==1 then
		local l=p.pow*10
		line(p.x,p.y,p.x+sin(p.ang)*l,p.y+cos(p.ang)*l,7)
	end
end
-->8
--utility

btns={false,false,false,false,false,false}

function updbtns()
	for i=0,5 do
		btns[i+1]=btn(i)
	end
end

function btnd(n)
	return (btn(n)==true and btns[n+1]==false)
end


function norm(v)
	local l=sqrt(v.x*v.x+v.y*v.y)
	return {x=v.x/l,y=v.y/l}
end

function vadd(a,b)
	return {x=a.x+b.x,y=a.y+b.y}
end

function vsub(a,b)
	return {x=a.x-b.x,y=a.y-b.y}
end

function vmul(a,b)
	return {x=a.x*b,y=a.y*b}
end

-->8
--player
function pinit()
	p={}
	p.x=64
	p.y=64
	p.dx=0
	p.dy=0
	p.ang=0
	p.pow=1
end

function pturn()
	if (btn(0)) p.ang-=0.01
	if (btn(1)) p.ang+=0.01
	if (btn(2)) p.pow+=0.1
	if (btn(3)) p.pow-=0.1
	p.pow=min(max(p.pow,0.2),2)
	
	if btnd(4) then
		state=2
		p.dx+=sin(p.ang)*p.pow
		p.dy+=cos(p.ang)*p.pow
	end
end

function pmov()
	p.x+=p.dx
	p.y+=p.dy
	p.dx*=0.95
	p.dy*=0.95
	local spd=sqrt(p.dx*p.dx+p.dy*p.dy)
	if spd<0.3 then
		state=1
	 p.dx,p.dy=0,0
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
