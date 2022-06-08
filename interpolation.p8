pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
cellsize=8

function _init()
	cellcount=128/cellsize
	cells={}

	for i=0,cellcount do
		cells[i]={}
		for j=0,cellcount do
			cells[i][j]=rnd(16)
		end
	end
	
	for i=0,cellcount-1 do
		for j=0,cellcount-1 do
			fillcell(i,j)
		end
	end
end

function fillcell(x,y)
	local h=cells[x][y]
	local h➡️=cells[(x+1)%cellcount][y]
	local h⬇️=cells[x][(y+1)%cellcount]
	local h➡️⬇️=cells[(x+1)%cellcount][(y+1)%cellcount]
	local dx1=h➡️-h
	local dx2=h➡️⬇️-h⬇️
	for i=0,cellsize do
		for j=0,cellsize do
			local px,py=i/cellsize,j/cellsize
			local x1=h+px*dx1
			local x2=h⬇️+px*dx2
			local v=x1+py*(x2-x1)
			pset(i+x*cellsize,j+y*cellsize,v)
		end
	end
end

function _draw()

end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
