pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
	cls()
	genmap()
	px,py=0,0
end

function _update()
	playerupdate()
end

function _draw()
	cls(12)
	drawterrain()
end

function drawterrain2d()
	for x=0,127 do
		for y=0,127 do
			local v=peek(0x8000+x+y*128)
			pset(x,y,v)
		end
	end
end
-->8
--map
function getheight(x,y)
	return peek(0x8000+x/100+y/100*128)
end

function genmap()
	os2d_noise(rnd())
	for x=0,127 do
		for y=0,127 do
			local addr=0x8000+x+y*128
			local v=genheight(x,y)
			poke(addr,v)
			pset(x,y,v)
		end
	end
end

function genheight(x,y)
	local v=0
	v+=os2d_eval(x/40,y/40,10)*4
	v+=os2d_eval(x/10,y/10)
	v/=3
	v=v/2+0.5
	v=min(max(0,v),0.999)
	v=v*v
	return flr(v*16)
end

-->8
--utility
function remap(v,l1,h1,l2,h2)
	return (v-l1)*(h2-l2)/(h1-l1)+l2
end

-- opensimplex noise

-- adapted from public-domain
-- code found here:
-- https://gist.github.com/kdotjpg/b1270127455a94ac5d19

--------------------------------

-- opensimplex noise in java.
-- by kurt spencer
-- 
-- v1.1 (october 5, 2014)
-- - added 2d and 4d implementations.
-- - proper gradient sets for all dimensions, from a
--   dimensionally-generalizable scheme with an actual
--   rhyme and reason behind it.
-- - removed default permutation array in favor of
--   default seed.
-- - changed seed-based constructor to be independent
--   of any particular randomization library, so results
--   will be the same when ported to other languages.

-- (1/sqrt(2+1)-1)/2
local _os2d_str=-0.211324865405187
-- (  sqrt(2+1)-1)/2
local _os2d_squ= 0.366025403784439

-- cache some constant invariant
-- expressions that were 
-- probably getting folded by 
-- kurt's compiler, but not in 
-- the pico-8 lua interpreter.
local _os2d_squ_pl1=_os2d_squ+1
local _os2d_squ_tm2=_os2d_squ*2
local _os2d_squ_tm2_pl1=_os2d_squ_tm2+1
local _os2d_squ_tm2_pl2=_os2d_squ_tm2+2

local _os2d_nrm=47

local _os2d_prm={}

-- gradients for 2d. they 
-- approximate the directions to
-- the vertices of an octagon 
-- from the center
local _os2d_grd = 
{[0]=
     5, 2,  2, 5,
    -5, 2, -2, 5,
     5,-2,  2,-5,
    -5,-2, -2,-5,
}

-- initializes generator using a 
-- permutation array generated 
-- from a random seed.
-- note: generates a proper 
-- permutation, rather than 
-- performing n pair swaps on a 
-- base array.
function os2d_noise(seed)
    local src={}
    for i=0,255 do
        src[i]=i
        _os2d_prm[i]=0
    end
    srand(seed)
    for i=255,0,-1 do
        local r=flr(rnd(i+1))
        _os2d_prm[i]=src[r]
        src[r]=src[i]
    end
end

-- 2d opensimplex noise.
function os2d_eval(x,y)
    -- put input coords on grid
    local sto=(x+y)*_os2d_str
    local xs=x+sto
    local ys=y+sto
   
    -- flr to get grid 
    -- coordinates of rhombus
    -- (stretched square) super-
    -- cell origin.
    local xsb=flr(xs)
    local ysb=flr(ys)
   
    -- skew out to get actual 
    -- coords of rhombus origin.
    -- we'll need these later.
    local sqo=(xsb+ysb)*_os2d_squ
    local xb=xsb+sqo
    local yb=ysb+sqo

    -- compute grid coords rel.
    -- to rhombus origin.
    local xins=xs-xsb
    local yins=ys-ysb

    -- sum those together to get
    -- a value that determines 
    -- which region we're in.
    local insum=xins+yins

    -- positions relative to 
    -- origin point.
    local dx0=x-xb
    local dy0=y-yb
   
    -- we'll be defining these 
    -- inside the next block and
    -- using them afterwards.
    local dx_ext,dy_ext,xsv_ext,ysv_ext

    local val=0

    -- contribution (1,0)
    local dx1=dx0-_os2d_squ_pl1
    local dy1=dy0-_os2d_squ
    local at1=2-dx1*dx1-dy1*dy1
    if at1>0 then
        at1*=at1
        local i=band(_os2d_prm[(_os2d_prm[(xsb+1)%256]+ysb)%256],0x0e)
        val+=at1*at1*(_os2d_grd[i]*dx1+_os2d_grd[i+1]*dy1)
    end

    -- contribution (0,1)
    local dx2=dx0-_os2d_squ
    local dy2=dy0-_os2d_squ_pl1
    local at2=2-dx2*dx2-dy2*dy2
    if at2>0 then
        at2*=at2
        local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb+1)%256],0x0e)
        val+=at2*at2*(_os2d_grd[i]*dx2+_os2d_grd[i+1]*dy2)
    end
   
    if insum<=1 then
        -- we're inside the triangle
        -- (2-simplex) at (0,0)
        local zins=1-insum
        if zins>xins or zins>yins then
            -- (0,0) is one of the 
            -- closest two triangular
            -- vertices
            if xins>yins then
                xsv_ext=xsb+1
                ysv_ext=ysb-1
                dx_ext=dx0-1
                dy_ext=dy0+1
            else
                xsv_ext=xsb-1
                ysv_ext=ysb+1
                dx_ext=dx0+1
                dy_ext=dy0-1
            end
        else
            -- (1,0) and (0,1) are the
            -- closest two vertices.
            xsv_ext=xsb+1
            ysv_ext=ysb+1
            dx_ext=dx0-_os2d_squ_tm2_pl1
            dy_ext=dy0-_os2d_squ_tm2_pl1
        end
    else  //we're inside the triangle (2-simplex) at (1,1)
        local zins = 2-insum
        if zins<xins or zins<yins then
            -- (0,0) is one of the 
            -- closest two triangular
            -- vertices
            if xins>yins then
                xsv_ext=xsb+2
                ysv_ext=ysb
                dx_ext=dx0-_os2d_squ_tm2_pl2
                dy_ext=dy0-_os2d_squ_tm2
            else
                xsv_ext=xsb
                ysv_ext=ysb+2
                dx_ext=dx0-_os2d_squ_tm2
                dy_ext=dy0-_os2d_squ_tm2_pl2
            end
        else
            -- (1,0) and (0,1) are the
            -- closest two vertices.
            dx_ext=dx0
            dy_ext=dy0
            xsv_ext=xsb
            ysv_ext=ysb
        end
        xsb+=1
        ysb+=1
        dx0=dx0-_os2d_squ_tm2_pl1
        dy0=dy0-_os2d_squ_tm2_pl1
    end
   
    -- contribution (0,0) or (1,1)
    local at0=2-dx0*dx0-dy0*dy0
    if at0>0 then
        at0*=at0
        local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb)%256],0x0e)
        val+=at0*at0*(_os2d_grd[i]*dx0+_os2d_grd[i+1]*dy0)
    end
   
    -- extra vertex
    local atx=2-dx_ext*dx_ext-dy_ext*dy_ext
    if atx>0 then
        atx*=atx
        local i=band(_os2d_prm[(_os2d_prm[xsv_ext%256]+ysv_ext)%256],0x0e)
        val+=atx*atx*(_os2d_grd[i]*dx_ext+_os2d_grd[i+1]*dy_ext)
    end
    return val/_os2d_nrm
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

waterheight=0.5

function drawterrain()
	local drawdist=8000
	local fov=0.7
	
	local aperspstart=200
	local lightend=190
	local hscale=10
	local drawstepdeltanear=0.2
	local drawstepdeltafar=50
	
	local waterheight=waterheight
	
	--distance of samples from player
	local dz,z=5,1
	--columns
	local colwidth=8
	local numcols=128/colwidth
	
	
	--precalc angle params
	local sinr=sin(rot.h)
	local cosr=cos(rot.h)
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
	--loop until z=drawdist
	while z<drawdist do
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
		local lastcolh=0
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
					if z<aperspstart then
						fillp(0)
					else
						col=col|12*16
						fillp(aperspshade&0xffff)
					end
					if z-1*dz>lastdraw[0][i] then
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i]-1,col)
						fillp(0)
						line(sscol,ybuff[i],sscol+colwidth-1,ybuff[i+1],colours[lastdraw[1][i]][3])

						--rectfill(sscol,ybuff[i],sscol+colwidth-1,ybuff[i],colours[lastdraw[1][i]][3])
					else
						rectfill(sscol,ssheight,sscol+colwidth-1,ybuff[i],col)
					end
					--line(sscol-colwidth,lastcolh+1,sscol,ssheight+1,colours[ttype][3])
					lastcolh=ssheight
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
		line(sscol,ybuff[max(0,i-1)],sscol+colwidth-1,h,colours[lastdraw[1][i]][3])
		--rectfill(sscol,h,sscol+colwidth-1,h,colours[lastdraw[1][i]][3])
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
-->8
--player
playerheight=100
mspeed=1
lspeed={h=0.01,v=2}

pos={x=120,y=120,z=1}
rot={h=2,v=64}

function playerupdate()
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
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
