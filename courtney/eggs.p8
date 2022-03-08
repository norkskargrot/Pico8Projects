pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	x=64
	y=64
	size=6
end

function _update()
	
	if btn(0) then 
		x=x-4
	end
	
	if btn(1) then
		x=x+4
	end
	
	if btn(2) then
		y=y-4
	end
	
	if btn(3) then 
		y=y+4
	end
	
	eggfence(size)
end

function _draw()
	cls(6)
	egg(size,x,y)
	egg(8,x+12,y+12)
end

function egg(size,px,py)
	circfill(px,py,size,7)
	circfill(px,py,size/2,10)
end

function eggfence(size)
	if x<size then
		x=size
	end
	
	if x>127-size then
		x=127-size
	end

	if y<size then 
		y=size
	end
	
	if y>127-size then
		y=127-size
	end

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88888888888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8888eee8888888888888888888888888888888888888888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee88888e88888888888888888888888888888888888888888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee888888888888888888888888888888888888888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111bbb1bbb1bb111711ccc117111111eee1e1e1eee1ee111111111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111b1b11b11b1b1711111c1117111111e11e1e1e111e1e11111111111111111111111111111111111111111111111111111111111111111111
111111e11ee111111bb111b11b1b171111cc1117111111e11eee1ee11e1e11111111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111b1b11b11b1b1711111c1117111111e11e1e1e111e1e11111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1111111bbb11b11b1b11711ccc1171111111e11e1e1eee1e1e11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116161111161611111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116161777161611711c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111116661111166617771ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111116177711161171111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111666111116661111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111118888811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666116611661666166616611166166611718878811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161116111611161116161611161117118887811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661161116111661166116161611166117118887811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161616161611161116161611161117118887811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166616661611166616161166166611718878811111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111117771111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111117777111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111117711111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111661166616661616117111711111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161616171111171111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111616166116661616171111171111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161666171111171111111111111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666161616161666117111711111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1b1111bb11711c1111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111b111b111b1117111c1111171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111b111b111bbb17111ccc11171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111b111b11111b17111c1c11171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1bbb1bb111711ccc11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661166116611711ccc11111616111116161171111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161116111711111c11111616111116161117111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116611611161117111ccc11111161111116661117111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116111616161617111c1111711616117111161117111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661666166611711ccc17111616171116661171111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661166116611711ccc11111ccc1c1111111ccc1c1111711111111111111111111111111111111111111111111111111111111111111111111111111111
111116111611161117111c1111111c1c1c1111111c1c1c1111171111111111111111111111111111111111111111111111111111111111111111111111111111
111116611611161117111ccc11111ccc1ccc11111ccc1ccc11171111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161616161711111c11711c1c1c1c11711c1c1c1c11171111111111111111111111111111111111111111111111111111111111111111111111111111
111116661666166611711ccc17111ccc1ccc17111ccc1ccc11711111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661166116611711166166616661666111116661616111116661616117111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111611161117111611116111161611111116161616111116161616111711111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116611611161117111666116111611661111116661161111116661666111711111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111616161617111116116116111611117116111616117116111116111711111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666166611711661166616661666171116111616171116111666117111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1bbb1bbb11bb1bbb1bbb1b111b111171166616161111166616161111116616661666166611111ccc1171111111111111111111111111111111111111
11111b1111b11b1b1b111b1111b11b111b11171116161616111116161616111116111161111616111111111c1117111111111111111111111111111111111111
11111b1111b11bb11b111bb111b11b111b11171116661161111116661666111116661161116116611111111c1117111111111111111111111111111111111111
11111b1111b11b1b1b111b1111b11b111b11171116111616117116111116117111161161161116111171111c1117111111111111111111111111111111111111
111111bb1bbb1b1b11bb1b111bbb1bbb1bbb117116111616171116111666171116611666166616661711111c1171111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1bbb1bbb11bb1bbb1bbb1b111b111171166616161111166616161111116616661666166611171ccc11111cc11ccc1171111111111111111111111111
11111b1111b11b1b1b111b1111b11b111b11171116161616111116161616111116111161111616111171111c111111c11c1c1117111111111111111111111111
11111b1111b11bb11b111bb111b11b111b111711166611611111166616661111166611611161166111711ccc111111c11c1c1117111111111111111111111111
11111b1111b11b1b1b111b1111b11b111b111711161116161171161111161171111611611611161111711c11117111c11c1c1117111111111111111111111111
111111bb1bbb1b1b11bb1b111bbb1bbb1bbb1171161116161711161116661711166116661666166617111ccc17111ccc1ccc1171111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282228882822282228888888888888888888888888888888888888888888888888228822282828882822282288222822288866688
82888828828282888888888288828828828882888888888888888888888888888888888888888888888888888828888282828828828288288282888288888888
82888828828282288888822288228828822282228888888888888888888888888888888888888888888888888828882282228828822288288222822288822288
82888828828282888888828888828828888288828888888888888888888888888888888888888888888888888828888288828828828288288882828888888888
82228222828282228888822282228288822282228888888888888888888888888888888888888888888888888222822288828288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

