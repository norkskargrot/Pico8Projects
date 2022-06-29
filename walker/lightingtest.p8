pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
shades={[0]=
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

cols={[0]=
	{[0]=0,128,132,4,137,9,10},
	{[0]=0,129,1,131,3,139,11},
	{[0]=0,128,130,133,5,13,6},
}

tim=0

function _update()
	if (btn(0)) tim-=1
	if (btn(1)) tim+=1
	tim=max(tim,0)
end

function _draw()
	cls()
	local mod=flr(tim/16)
	for i=0,2 do
		for j=0,2 do
			pal(i*3+j,cols[i][j+mod],1)
		end
	end


	cls()
	for j=0,2 do
		for i=0,127,8 do
			-- l between 0 and 15
			local l=i/8
			
			l=l+tim%16
			fillp(shades[l%16])
			l=flr(l/16)%2+j*3
			local c1=l
			local c2=l+1
			local c=c2<<4|c1
			local h=j*32
			rectfill(i,h,i+7,h+31,c)
		end
	end
	
	fillp()
	for i=0,3 do
		for j=0,2 do
			rectfill(j*4,i*4,j*4+3,i*4+3,i*3+j)
		end
	end
end

function colfill(l,t)
	l=l+tim%16
	fillp(shades[l%16])
	l=flr(l/16)%2+t*3
	local c1=l
	local c2=l+1
	return c2<<4|c1
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000