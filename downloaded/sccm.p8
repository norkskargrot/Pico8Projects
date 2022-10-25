pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- skeleton code compress map
-- written by dw817 (12-31-19)
-- requested by scrubsandwich

-- standard ⌂ pico-8 license

-- updates:
-- 01/01/20
-- thanks big to merwok for
-- considering a function
-- within a function. works
-- great and frees up the
-- need to have true exposed
-- global variables remaining
-- after you compress or
-- decompress.

-- note, do not use sprite #255
-- as i'm using that number as
-- part of my compression
-- algorithm.

function _init()

_n=nil _={}
_[0]=false _[1]=true

-- create 6-bit table
chr6,asc6,char6={},{},"abcdefghijklmnopqrstuvwxyz.1234567890 !@#$%,&*()-_=+[{]};:'|<>/?"
for i=0,63 do
  c=sub(char6,i+1,i+1) chr6[i]=c asc6[c]=i
end
char6=_n

-- create 8-bit table
chr8,asc8,char8={},{},"\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31 !\"#$%&'()*+,-./0123456789:;<=>?@\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~○█▒🐱⬇️░✽●♥☉웃⌂⬅️😐♪🅾️◆…➡️★⧗⬆️ˇ∧❎▤▥\154\155\156\157\158\159\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255"
for i=0,255 do
  c=sub(char8,i+1,i+1) chr8[i]=c asc8[c]=i
end
char8=_n

cls()
?"this is what the map looks"
?"like right now."
key()

map()
key(0)

t=compresmap(0,0,16,16)
?"16x16 map has been compressed"
?'to string "t" that is now '..#t
?"chars in size."
?""
?"now clearing actual map area."

for i=0,15 do
  for j=0,15 do
    mset(j,i,0)
  end
end

?"map cleared."
?""
?"this is what it looks like"
?"now."
key()

map()
key(0)

?"now decompressing t of "..#t
?"chars back to actual map data."
key()

decompresmap(0,0,t)

map()
key(0)

?"complete!"

repeat
  flip()
until forever

end


-- comprehensive compress
-- mapper data. h+v are
-- top-left position to start
-- and x+y are size across and
-- down to work with.
-- return value is 6-bit
-- string.
-- approx 66% compression.
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


-- simple wait for (o) key.
function key(a)
  if a!=0 then
    color(12)
    ?""
    ?"press (o) to continue."
  end
  color(6)
  for i=0,1 do
    repeat
      flip()
    until btn(4)==_[i]
  end
  sfx(0)
  cls()
end

__gfx__
000000001111111022222220333333304444444055555550ddddddd088888880eeeeeee000000000000000000000000000000000000000000000055555000000
000000001117111027777220377777304444744057777750ddd7ddd087777780ee777ee000000000000000000000000000000000000000000005566666550000
000000001177111022222720333373304447744057555550dd7dddd088888780e7eee7e000000000000000000000000000000000000000000056600000665000
000000001117111022277220333773304474744055777550d7d77dd088887880ee777ee000000000000000000000000000000000000000000560000000006500
000000001117111022722220373337304777774055555750d7ddd7d088878880e7eee7e000000000000000000000000000000000000000000560aa9998806500
000000001177711027777720337773304444744055777550dd777dd088788880ee777ee000000000000000000000000000000000000000005600aa0000800650
000000001111111022222220333333304444444055555550ddddddd088888880eeeeeee000000000000000000000000000000000000000005600bb0000000650
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005600bb0000000650
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005600cc0000000650
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005600cc0000f00650
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560ddeeeff06500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560000000006500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056600000665000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005566666550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555000000
__label__
11111110111111101111111000000000000000000000000000000000000000000000000000000000000000000000000000000000222222202222222022222220
11171110111711101117111000000000000000000000000000000000000000000000000000000000000000000000000000000000277772202777722027777220
11771110117711101177111000000000000000000000000000000000000000000000000000000000000000000000000000000000222227202222272022222720
11171110111711101117111000000000000000000000000000000000000000000000000000000000000000000000000000000000222772202227722022277220
11171110111711101117111000000000000000000000000000000000000000000000000000000000000000000000000000000000227222202272222022722220
11777110117771101177711000000000000000000000000000000000000000000000000000000000000000000000000000000000277777202777772027777720
11111110111111101111111000000000000000000000000000000000000000000000000000000000000000000000000000000000222222202222222022222220
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111110111111100000000000000000333333303333333000000000333333303333333000000000000000000000000000000000000000002222222022222220
11171110111711100000000000000000377777303777773000000000377777303777773000000000000000000000000000000000000000002777722027777220
11771110117711100000000000000000333373303333733000000000333373303333733000000000000000000000000000000000000000002222272022222720
11171110111711100000000000000000333773303337733000000000333773303337733000000000000000000000000000000000000000002227722022277220
11171110111711100000000000000000373337303733373000000000373337303733373000000000000000000000000000000000000000002272222022722220
11777110117771100000000000000000337773303377733000000000337773303377733000000000000000000000000000000000000000002777772027777720
11111110111111100000000000000000333333303333333000000000333333303333333000000000000000000000000000000000000000002222222022222220
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111110000000000000000000000000000000000000000033333330000000003333333033333330000000008888888000000000000000000000000022222220
11171110000000000000000000000000000000000000000037777730000000003777773037777730000000008777778000000000000000000000000027777220
11771110000000000000000000000000000000000000000033337330000000003333733033337330000000008888878000000000000000000000000022222720
11171110000000000000000000000000000000000000000033377330000000003337733033377330000000008888788000000000000000000000000022277220
11171110000000000000000000000000000000000000000037333730000000003733373037333730000000008887888000000000000000000000000022722220
11777110000000000000000000000000000000000000000033777330000000003377733033777330000000008878888000000000000000000000000027777720
11111110000000000000000000000000000000000000000033333330000000003333333033333330000000008888888000000000000000000000000022222220
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000033333330000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000037777730000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000033337330000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000033377330000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000037333730000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000033777330000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000033333330000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555055555550555555505555555000000000888888800000000000000000333333303333333000000000000000004444444000000000ddddddd0ddddddd0
5777775057777750577777505777775000000000877777800000000000000000377777303777773000000000000000004444744000000000ddd7ddd0ddd7ddd0
5755555057555550575555505755555000000000888887800000000000000000333373303333733000000000000000004447744000000000dd7dddd0dd7dddd0
5577755055777550557775505577755000000000888878800000000000000000333773303337733000000000000000004474744000000000d7d77dd0d7d77dd0
5555575055555750555557505555575000000000888788800000000000000000373337303733373000000000000000004777774000000000d7ddd7d0d7ddd7d0
5577755055777550557775505577755000000000887888800000000000000000337773303377733000000000000000004444744000000000dd777dd0dd777dd0
5555555055555550555555505555555000000000888888800000000000000000333333303333333000000000000000004444444000000000ddddddd0ddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555500000000000000000000000000000000000000000000000000000000000000000000000000000000044444440444444400000000000000000ddddddd0
577777500000000000000000000000000000000000000000000000000000000000000000000000000000000044447440444474400000000000000000ddd7ddd0
575555500000000000000000000000000000000000000000000000000000000000000000000000000000000044477440444774400000000000000000dd7dddd0
557775500000000000000000000000000000000000000000000000000000000000000000000000000000000044747440447474400000000000000000d7d77dd0
555557500000000000000000000000000000000000000000000000000000000000000000000000000000000047777740477777400000000000000000d7ddd7d0
557775500000000000000000000000000000000000000000000000000000000000000000000000000000000044447440444474400000000000000000dd777dd0
555555500000000000000000000000000000000000000000000000000000000000000000000000000000000044444440444444400000000000000000ddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555500000000000000000444444404444444000000000000000008888888000000000000000004444444044444440000000000000000000000000ddddddd0
577777500000000000000000444474404444744000000000000000008777778000000000000000004444744044447440000000000000000000000000ddd7ddd0
575555500000000000000000444774404447744000000000000000008888878000000000000000004447744044477440000000000000000000000000dd7dddd0
557775500000000000000000447474404474744000000000000000008888788000000000000000004474744044747440000000000000000000000000d7d77dd0
555557500000000000000000477777404777774000000000000000008887888000000000000000004777774047777740000000000000000000000000d7ddd7d0
557775500000000000000000444474404444744000000000000000008878888000000000000000004444744044447440000000000000000000000000dd777dd0
555555500000000000000000444444404444444000000000000000008888888000000000000000004444444044444440000000000000000000000000ddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555550000000000000000044444440444444400000000000000000000000000000000000000000444444400000000000000000ddddddd0ddddddd0ddddddd0
57777750000000000000000044447440444474400000000000000000000000000000000000000000444474400000000000000000ddd7ddd0ddd7ddd0ddd7ddd0
57555550000000000000000044477440444774400000000000000000000000000000000000000000444774400000000000000000dd7dddd0dd7dddd0dd7dddd0
55777550000000000000000044747440447474400000000000000000000000000000000000000000447474400000000000000000d7d77dd0d7d77dd0d7d77dd0
55555750000000000000000047777740477777400000000000000000000000000000000000000000477777400000000000000000d7ddd7d0d7ddd7d0d7ddd7d0
55777550000000000000000044447440444474400000000000000000000000000000000000000000444474400000000000000000dd777dd0dd777dd0dd777dd0
55555550000000000000000044444440444444400000000000000000000000000000000000000000444444400000000000000000ddddddd0ddddddd0ddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555500000000000000000000000004444444044444440444444404444444044444440444444404444444000000000ddddddd0ddddddd00000000000000000
577777500000000000000000000000004444744044447440444474404444744044447440444474404444744000000000ddd7ddd0ddd7ddd00000000000000000
575555500000000000000000000000004447744044477440444774404447744044477440444774404447744000000000dd7dddd0dd7dddd00000000000000000
557775500000000000000000000000004474744044747440447474404474744044747440447474404474744000000000d7d77dd0d7d77dd00000000000000000
555557500000000000000000000000004777774047777740477777404777774047777740477777404777774000000000d7ddd7d0d7ddd7d00000000000000000
557775500000000000000000000000004444744044447440444474404444744044447440444474404444744000000000dd777dd0dd777dd00000000000000000
555555500000000000000000000000004444444044444440444444404444444044444440444444404444444000000000ddddddd0ddddddd00000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555505555555000000000000000000000000000000000444444404444444000000000000000000000000000000000ddddddd0ddddddd0ddddddd000000000
577777505777775000000000000000000000000000000000444474404444744000000000000000000000000000000000ddd7ddd0ddd7ddd0ddd7ddd000000000
575555505755555000000000000000000000000000000000444774404447744000000000000000000000000000000000dd7dddd0dd7dddd0dd7dddd000000000
557775505577755000000000000000000000000000000000447474404474744000000000000000000000000000000000d7d77dd0d7d77dd0d7d77dd000000000
555557505555575000000000000000000000000000000000477777404777774000000000000000000000000000000000d7ddd7d0d7ddd7d0d7ddd7d000000000
557775505577755000000000000000000000000000000000444474404444744000000000000000000000000000000000dd777dd0dd777dd0dd777dd000000000
555555505555555000000000000000000000000000000000444444404444444000000000000000000000000000000000ddddddd0ddddddd0ddddddd000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd0ddddddd0ddddddd0ddddddd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd7ddd0ddd7ddd0ddd7ddd0ddd7ddd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd7dddd0dd7dddd0dd7dddd0dd7dddd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7d77dd0d7d77dd0d7d77dd0d7d77dd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7ddd7d0d7ddd7d0d7ddd7d0d7ddd7d0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd777dd0dd777dd0dd777dd0dd777dd0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd0ddddddd0ddddddd0ddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000087777780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088888780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088887880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088878880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088788880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0
877777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0
888887800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0
888878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0
888788800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0
887888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0
888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0
8777778087777780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0
8888878088888780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0c7ccc7c0
8888788088887880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0
8887888088878880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0c7ccc7c0
8878888088788880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0
8888888088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888880888888808888888000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0ccccccc0
87777780877777808777778000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0cc777cc0
88888780888887808888878000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0c7ccc7c0c7ccc7c0
88887880888878808888788000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0cc777cc0
88878880888788808887888000000000000000000000000000000000000000000000000000000000000000000000000000000000c7ccc7c0c7ccc7c0c7ccc7c0
88788880887888808878888000000000000000000000000000000000000000000000000000000000000000000000000000000000cc777cc0cc777cc0cc777cc0
88888880888888808888888000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0ccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0101010000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000003030003030000000000020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000300030300070000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050500070000030300000400060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000040400000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000404000007000004040000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000404000000000004000006060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000004040404040404000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505000000000404000000000606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707000000000000000000000000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070000000000000000000008080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010800003001524015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
