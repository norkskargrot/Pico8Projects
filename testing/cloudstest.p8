pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
skx=10
cloud_c=12

wrld=0

function _update()
 if (btn(0)) then
 	wrld-=0.002
 end
 
 if (btn(1)) then
 	wrld+=0.002
 end
end

function _draw()
	cls(7)
	sky_cast(wrld)
	rectfill(0,64,127,127,3)
end

function sky_cast(world_ang)

 local camx,camy=
  sin(world_ang),cos(world_ang)
 
 local stx,sty=
  -camx+cos(world_ang),
  -camy+(-sin(world_ang))
 
 pal(6,cloud_c)
 poke(0x5f38,4)
	poke(0x5f39,4)
	poke(0x5f3a,sky_x1)

 for y=0,60 do
  local curdist=128/(2*y-128)

  local d16,j=
   curdist/64,
   y%2*.03

  tline(0,y,127,y,
   j-skx+28+stx*curdist*1.2,
   j+28+sty*curdist*1.2,
   d16*camx,d16*camy)
 end
 skx+=0.0075
end

function drawlogs()
	print("cpu use=",0,0,7)
	print(stat(1),32,0,7)
	
	print("fps=",0,6,7)
	print(stat(7),16,6,7)
	
	print("memory=",0,12,7)
	print(stat(0),28,12,7)
	
	print("x=",0,18,7)
	print(pos.x*tscale,8,18,7)
	
	print("y=",0,24,7)
	print(pos.y*tscale,8,24,7)
end

__gfx__
111fff222dddddddddddddcccccccccccccccccccc1dddddddddd222ffffffc0dd746d666d6666ddd66ddd111115ddddddddd511116dd66666d6666dd66699dd
1111f22222ddddddddddd22222222222222222222215ddddddd6dd22ffffffccdd94dddddddddddddddddd111115dd66666dd5111166dddddddddddddddd99dd
1111ff222d2ddddddddd522222222222222222222215dddddddd2d222ffffff0dd94ddddddd6d6666ddddd111115ddddddddd5111166ddddddddd66666dd77dd
1111ff2222dddddddddd11111111111111111111111dddddddddd2222fffffffdd94dddddddddddddddd55111115555dddddd511116dddccdddddddddddd99dd
1111f22222dddddddddddd11111111111111111111ddddddddd6dd222fffffffdd94dddddddddddddddddd111115ddddddddd511116ddddddddddddddddd99dd
1111fff22d2dddddddddddd1115d55555555111111dddddddddd22222fffffc0d694ccccd666666d666ddd111115dd6666ddd51111666666ddcccd66dd6d79dd
1111fff222d2ddddddddd5d1115dd555555dd11111ddddddddd6dd2222ffffccdd94dddddddddddddddddd111115ddddddddd511116ddddddddddddddddd99dd
1111ff2222ddddddddddddd1115dd5d5555dd11111dddddddddd622222fffcccdd94d66dccccd6666ddddd111115dddd55555511116ddddddddddddddddd99dd
1111ff2222d2ddddddddddcccccccccccccccccccc1ddddddddddd2222ffffccdd94dddddddddddddddddd111115ddddddddd511116dddccccccd6d666d697dd
1111f22222ddddddddddd22222222222222222222215ddddddd62d22222fffc0dd94ddddddddddddddd55511111555555dddd5111166dddddddddddddddd99dd
1111ff22222d2ddddddd522222222222222222222215ddddddddddd2222ffcf0d6a6dccccccd6666dddddd111115ddddddddd5111166dddddddddddddddd99dd
1111fff22222dddddddd11111111111111111111111dddddddd6d2d2222ffcffdd94dddddddddddddddddd111115ddd555555511116dd66666ddcccdddd677dd
1111f2f2222ddddddddddd11111111111111111111dddddddddd6d2222fffcf0dd94dddddddddd6666dddd111115ddddddddd511116ddddddddddddddddd99dd
111ff2f2222d2ddddddd5d51115d55555555111111ddddddddddddd222ffffc0dd96dd66dddddddddddd55111115ddddddddd511116ddddddddddddddddd99dd
111fff222222ddddddddddd1115dd5555555511111dddddd6ddd62d222fffcfcdddddddddddddddddddddd111115dd666dddd51111666dd66666666d666ddddd
111ffff2222ddddddddddd51115d5d55555dd11111dddddddd66ddd22fffffc0ddddddd5555dd66dddd555111115ddddd6666511116ddddddddddddddddddddd
0000000000000000000000cccccccccccccccccccccccccc1dddddddffffffc00000222d2ff22221155555cccccccccccccccccccc1555511ffff122d0000000
00000000000000000000022222222222222222222222222215ddddddffffffcc0000222d2f2f22211555522222222222222222222215d5511ffff122d0000000
00000000000000000000022222222222222222222222222215dddddd2ffffff00000222d2f2f2221155551111111111111111111111555511ffff122d0000000
0000000000000000000001111111111111111111111111111ddddddd2fffffff0000222d2f2f2221155511111111111111111111115555551ffff122d0000000
000000000000000000000011111111111111111111111111dddddddd2fffffff0000222d2f22f2211555551111155555555d111111555d551fff1122d0000000
000000000000000000000000551111555555d55555551111dddddddd2fffffc00000222d2f22f221155d55511155555555551111115555551fff1122d0000000
000000000000000000000000551111d5555d5d5555555111dddddddd22ffffcc0000222d2f22f22115555551115555555555d111115555551fff1122d0000000
000000000000000000000000d51111d555555d55555dd111dddddddd22fffccc0000222d2f222f2115555551115555555555d111115555551ff1f122d0000000
0000000000000000000000cccccccccccccccccccccccccc1ddddddd22ffffcc0000222d2f222f21155555cccccccccccccccccccc1555151ff1f122d0000000
00000000000000000000022222222222222222222222222215dddddd222fffc00000222d2f222f21155552222222222222222222221555151ff1f122d0000000
00000000000000000000022222222222222222222222222215dddddd222ffcf00000222d2f2222f1155551111111111111111111111555511f1ff122d0000000
0000000000000000000001111111111111111111111111111ddddddd222ffcff0000222d2f2222f1155511111111111111111111115555511f1ff122d0000000
000000000000000000000011111111111111111111111111dddddddd22fffcf00000222d2f2222f11555551111155555555d111111555d511f1ff122d0000000
000000000000000000000000551111555555555555551111dddddddd22ffffc00000222d2f2222211555555111555555555511111155555511fff122d0000000
000000000000000000000000551111d55555555555555111dddddddd22fffcfc0000222d2ff2222115555551115555555555d1111155555511fff122d0000000
0000000000000000000000005511115d55555555555dd111dddddddd2fffffc00000222d2ff222211555d551115555555555d11111555d5511fff122d0000000
1ed9dd2cccccc5e10000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000030000000
e1d8d2ccccccc5e1000000000000000000000000000000000000000000000000000000000000000000000000000000000050003e0000000000000300e3000000
e1d4ddccccccc5e100000000000000000000000000000000000000000000000000000000000000000000000000000000003553e15510000000000e30e0000000
11d4ddccccccc5e1000000000000000000000000000000000000000000000000000000000000000000000eeeee00000000e533ffe5000000000001ee20000000
11d8ddccccccc5e10000000000000000000000000303300000000000000000000000000000000000000eee3bbe0000000015ee5e535000000000301f233e0000
11d9d2ccccccc5e100000000000000000000000003333333003300000000000000000000000000000001e3333be0eee000353e5e50000000000e333ee3e00000
1ed9ddccccc2c5e1000000000000000000000000033333330033000003330000000000000000000000ee1ee33eee3bb005e533355330000000001eeeee100000
e1d8ddccccccc5e10000000000000000000303333333333333330333333330000000000000000000001eee1ee1e3333e0533ee33e3e000000000011111003000
e1d4ddccccccc5e1000000000000000000333333333333333333333333333300000000000000000000111ee11e1eeeee00e3e1efee153000000ee33f2033e000
11d8ddccccccc5e10000000000000000033333333333e3ee333333333333e3e000000000000000000001111e11e1e1e0031ef1f53e15e0000000ee3333eee000
11d9d2ccccccc5e10000000000000000333eee3333eeeeee333eee3333eeeee000000000000000000ee111ee111eee10031f5533e33f1e0000001e3eee110000
1ed9ddccccccc5e10000000000000000eeeeee3333eeeeeeeeeeee3333eeeeee0000000000000000e135e1111ff111e00e3e5eeeee3fe3000033011111133e00
e1d9d2ccccccc5e10000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000001e3b2e11e152f13b3113ee1e11efe33000e3330ff033e000
e1d9ddccccccc5e100000000000000001eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000011e3511ee15f1e33011111ffe1efee00000ee33f23e11000
11d9ddccccccc5e100000000000000001eeeeeeeeeeee1ee1eeeeeeeeeeee1ee0000000000000000111eee11e11eeeee051ef11e3e111e3000001eefe1110000
11d9ddccccccc5e1000000000000000011e1e1e1e1e1e1e111111111111111110000000000000000051111e11e1e11113151ef131f11e3000000011111000000
e1d4ddccccccc5e11111111111111111311111111111111111111111111111110000000000000000001153ee1111111e03ee111ee51e31300ee3333320033330
11d4ddccccccc5e1111111111eeeeeee331313131313131333131313131313130000000000000000e1ee335eee1155530ee1fff111fee10000e3e1e33e333e00
11d8ddccccccc5e11eeeeeeeeeeeeeee333333333333333333333333333333330000000000000000011ee333ee1e33e1015ee55555511000000e111ee1110000
11d9d2ccccccc5e11eeeccccceeeecee3131313331313133313131333131313300000000000000001111ee1ee1eeee110000e5c5500000000000011111100000
1ed9ddccccc2c5e11111111111111111333333333333333333333333333333330000000000000000ff1111eee11e1110000005cc000000000e0e333feeee3330
e1d8767c67776c511111111eeeeeeeee3333333333333333333333333333333300000000000000005f11e1111eee1ee0000005cc000000000eeeee3333eeeee0
e1d4677676c77c511eeeeeeeeeeeeeee3333333333333333333333333333333300000000000000000ff1111153e1ee11000005c6000000000011111e33111000
11d8ddccccccc5e11eeecceeecccceee33333333333333333333333333333333000000000000000001eee5553333e111000005c6000000000000111e33100000
11d9d2ccccccc5e11111111111111111333333333333333333333333333333330000000000000000011ee3333eee11110000055c0000000000ee331111e33000
1ed9ddccccccc5e1111111eeeeeeeeee3b33333333333333333333333333b3330000000000000000111111eeeee111100000055c00000000eeee333ffeee3330
e1d9d2ccccccc5e11eeeeeeeeeeeeeee333333333333b33333333b33b3333333000000000000000001ff111111111110000005c60000000011ee3331feeee1e3
e1d9ddccccccc5e11eeceeccceeeccce33333b33333333333b33333333333333000000000000000000fff1f11ffff100000005c6000000000111e111f1e1111e
11d9ddccccccc5e11111111111111111333333033303330333333303330333030000000000000000000ff1f2411fff100000e5cc0000000000011111f1110000
11d9ddccccccc5e111111eeeeeeeeeee030303333330333303330333333033300000000000000000000000f2400000000000ef5c000000000000000f20000000
1ed9dd2cccccc5e11eeeeeeeeeeeeeee000033030303303333303303030300000000000000000000000000f2200000000001fff5f10000000000000f20000000
e1d8d2ccccccc5e11ecccccceeecccee0003003330300300303030333033030000000000000000000111111ff111100003e3eeeee3130000055ff111211f5550
000000000000000000cccc0000ffff00880ff08800ffff0000ffff0000ffff00000f500000000000000000000000000000000000000000000000000066600000
000000000000000000fff50005c77cf07785c8770fc77cf00fc77cf005c77cf0000f500000000000000000000000000000000000000000000000000066000000
000000000000000000fee1002f777f7f48748748f77777cff77ff7cf2f777f7f000f55115555ccccc55555550000000000000000000000000000000060000000
0000000000000000005e3c00cf7f7f7f00477400ff7777fff7fccf7fcf7f7f7f000ff0110000000000000c0c0000000000666666666666666666666000000000
000000000000000000cccc00cf5f5f7f88744788f7fccf7fff7777ffcf5f5f7f000f500000000000000c5c0c00000000006c888ccccccccccc888cc000000000
000000000000000000fff500f7fcf77f7785c477fc7ff7cffc7777cff7fcf77f000f5000000000c555c005550000000000c89998cc6cc66cc89998c000000000
000000000000000000f441000f777cf04805c0480fc77cf00fc77cf00f777cf0000f50000c555c00000000000000000000c88888ccccccccc88888c000000000
000000000000000000548c0000ffff00000f500000ffff0000ffff0000ffff00000f5f5555000000000000000000000000c8999866cc6cc6c89998c000000000
000000000000000000ffff00000ff00000ffff00000ff000000ff000000ff000000f50000000000cdf1ddddddddddddd00cc888fcccccccccc888fc060000000
00000000000000000005c0000005c0000005c0000005c0000005c0000005c000000f5000000000cdd5566d666666dd6600fffffffffffffffffffff066600000
00000000000000000005c0000005c0000005c0000005c0000005c0000005c000000f5000000000dc65d6ddd6666d6776000005c111000001115c000066660000
00000000000000000005c0000005c0000005c0000005c0000005c0000005c000000f5000000000f551d5ddddddd6667700000671111000111167000066666000
00000000000000000005c0ff0005c0ff0005c0ff0005c0ff0005c0ff0005c0ff000f500000000015f1d55555ddddd666000006710ff000ff0167000066660000
00000000000000000005cff00005cff00005cff00005cff00005cff00005cff0000f50000000001511d1555555dddddd00000671000000000167000066000000
00000000000000000005cf000005cf000005cf000005cf000005cf000005cf00000f50000000001511d1515ff5555ddd00000671000000000067000000000000
000000000000000000ff5f0000ff5f0000ff5f0000ff5f0000ff5f0000ff5f00000f5000000000f511d15151f55f555500000670000000000067000000000000
0000000000000000000000000000000000099000000000000000000000000000000f50000000001511d15151f55111150f23457689abcdef0000011110555000
0000000000000000000220000000000000099000000000000000000000222000000f50000000001d51d1515115511f110123456789abcdef0055111ff05c6000
000fff0000000000000220000000000000099000004400000099900000222000000f500000000011d15d515115511f1f0124459789a9cd2f052511f111266c00
00022f0000022000000220000002200000040000004444000499900002f22000000f50006666cc41d165dd5115511f1f010045d189a12100052c5111e66cc000
00022f0000022200000f000000422000004990000044f400049949000f220000000f5000ccccdd4411d655d115511f1f0100451589a12100052251e666c55000
00ff2ff00008800000f2f0000422240004999900000f00000499490022222000000f5000ccccddd811d65651fd51111f000000000000000005555e6c55557770
00f22ff0000200000f22220000040000099999000044400000090000f2f22f00000f5000cccccddd9f11d661f5dd111f00000000000000000555555555559170
002222000288800002222f0000222000099999000044400009999000ff222f00000f5000cccccdddd81116d1f655dd1100000000000000000f55557775559775
002222f02288880002222f000222240009999900004f4000409990000f2ff000000f5000cccccdddd9c116d1fd5655dd66666666008822000ff5577175552225
002222f02288880002222f00022224000994990000ff400004999000f2f22000000f5000ccccccddd89c11d1fd5d66556666666600492f000ff5577775511155
00f22200228888000f2f2f00022224000440440000f4400009999900f2222000000f5000ccccccdddd9c11cffd5d6d666666666600492f000fff5f9992511555
00ffff000280820000f0f00004242400009090000044400009999900f2222000000f5000cccccccdddd9c11ffd5d6d666666666600492f000fff55ff25555555
00ffff0000808000002020000040400000909000004f400000404000f2002000000f5000cccccccdddd89c1ffd5d6d6d6666666600492f000ffff55556666555
00ff220000808000002020000020200000909000004040000090900002002000000f5000cccccccddddd99c11cdd6d6d6666666600e12f0000fffff5ff545550
000f020000808000002020000020200000909000004040000090900002002000000f5000ccccccccddddd8c111cddd6d6666666600111f00000fffffff665500
002f2f000028220000ffff0000444400004444000ffff0000040400002202200000f5000cccccccccddddd9c111cdd6d6666666600492f000000ffffffff0000
006666666600000000000066666666660076dddddddddddddddd67000000dddd0000dddddddd00000000ffffffffff000ffffffff000ffffff0005ffffff0000
00066666666000000000066666666666076dddddddddddddddddd67000dd66d600dd66d66d66dd00000f5555555555f0f5c77777f00fc7777cf00f77777c5000
0000066666666600006666666666666676d555555555555555555d67dd667d77dd667d7777d766dd00fcc66666666ccffc7c5ffff00f77ff77f00f7f55c7f000
000000666666666006666666666666666d55555555555555555555d66d77d6666d77d666666d77d600feeeeeeeeeeeeff7758000000f750057f00f7fffc7f000
00000006666666666666666666666666d5551111511111151111555d7666dddd7666dddddddd666700f555555555555ff77f8000000f7f00f7f00f7777750000
00000000666666666666666666666666d5511111511111151111155dddddd555ddddd555555ddddd001ffffffffffff0f77f8888888575ff57588f7ffffc5000
00000000666666666666666666666660155111115111111511111551d5511511d55115111151155d00f55e1f00000000f77f84444457777777754f7f44f77500
00000000666666666666666666666600151111115111111511111151515ff5ff515ff5ffff5ff5150001111000000000f77f800000f7cffffc7f0f7f00f77f80
00000660660600060006066666666600151eeee151eeee151eeee1515f51f5115f51f511115f15f51111111111111111f775800000f75000057f0f7f00f77f88
00006666666000600600666666666000151eeee151eeee151eeee1515151151151511511115115151ffefef5f5552521fc7c5ffff0f7f0000f7f0f7fffc77f48
00666660600000000006666666600000151eeee151eeee151eeee1515151151151511511115115151fefff5555f55251f5c77777f0fcf0000f7f0fc77777f088
06666666000006006066666666000000e51111115111111511111151dedeedeededeedeeeedeeded1efefe5f555525210ffffffff01ff00001ff01ffffff0088
66666660000060600666666660000000e511e1115f5555f51e11e1516161161161611611116116161fffff555525552100000000000000000000000000000088
06666666600006666666600000000000151e11e151111115111e1151d1d11d11d1d11d1111d11d1d1ef1f555555552215ffffff5005ff05fffff0005fffffff8
0006666606006066666606000000000015111e115111111511e111515151151151511511115115151ff1f55555525521f777777750f7f0f7777c500f777777f8
000000006006666666606000000000001511e111dddddddd1e1111515151151151511511115115151ef1f54885555221f7ffff57f0f7f0f7fff5cf0f75fffff8
6666000000066666666000000000000015111111dddddddd111111515f51f5115f51f511115f15f51ff1f55555555521f7f880f7f0f7f0f7f00f7f0f7f000088
66600000006666666660000000000000d5888888822222288888885ddddff511dddff511115ffddd1ff1f54885555521f7fffff7f0f7f0f7f00f7f0f7ff50884
60000000066666666666060000000006658999998244442899999856d66dddffd66dddffffddd66d1ff1f5c777777c21f777777588f7f8f7f88f7f8f777f8840
00000000066606060006600000000066658999998244442899999856d66666ddd66666dddd66666d1ef1f55555552521f7fff577f4f7f4f7f44f7f4f75ff4400
00000000666060000000660000000666d5899999824444289999985dddd66666ddd6666666666ddd15f1f55555555521f7f88fc7f0f7f0f7f00f7f0f7f000000
00000666660600000000666000066666f5888888824444288888885f555ddd66555ddd6666ddd5551ef1f5e335555221f7f44057f0f7f0f7ffff7f0f75fffff0
00006666600000000006066600666666fffffffffffffffffffffffffff555ddfff555dddd555fff1ff1f55555555521f7f000f7f0f7f0fc77777f0fc77777f0
00066666000006060000606666666666ff11f55f1ffffff1f55f111ffffff555fffff555555fffff1ef1f5e3355255211ff0001ff01f501ffffff001fffffff0
66666600666660600006060606666666ff1155551f1111f15555111f11fffff511fffff55fffff111ff1f55555555521111155dd2dd55dd20001f2d600cccc00
66666000666666600000006000066666fff155551f1111f1555511f10011ffff0011ffffffff110015f1f5e335555221ce5ddddddd5895dd0000000d0c7f76c0
66660000666666600000000000006666fff1f55f1ffffff1f55f1ff10001111f0001111ff111100015f1f55555555521ce52dddddd5245dd0000000ec77f776c
6660000000006660000000000000066601ff1111111111111111ff100000111100001111111100001ff1f5e3355f5221cef22ddddd5c75dd0000000fc77f776c
666000000000006600000000000006660011ff11ffffffff1fff11000000ff110000001111ff00001ef1f55555555521ce5fdddddd53b5dd007984f15777f77c
6660000000000066000000000000066600000ff1111111111ff0000000000ff1000000011ff0000015fff5e3355f2221cefd2ddddd5e35dd0000000e5c777f7c
6666600000000006000000000006666600000ff1000000001ff0000000000ff1000000001ff000001ffeff5555fe5e215cc89dddddd5cddd6c5e1003057777c0
66666660000000000000000006666666000000f0000000000f000000000000100000000001000000111111111111111155555eee2ee5cee20000007b005ccc00
__map__
c0c1c2c3c0c1c2c3c3f100c0c3c100c0e0d2d2d2e0d2d1d2f00000f3f00000f300d2e30000d20000f100000000e20000d09f000000000000c0c1c2c3f0f2f2f3f00000f3c0c1c2c3c3d3f3bcbcbcbcbcd3f3bcbcbcbcbcbcbcc3f0f3000000000000000000000000000000000000000000000000000000000000000000000000
d2d1d2d3d2d1c3d300d2e2d200d2e2d2d1d2d1e0d1d2d1d1c3e2e3c3bcc1c2c3d08ff000d0d30000000000f100d0c1f20000d09f00d0c29fd2d1c3d3c3f2f2f3bcc1c2c3d2d1c3d3f0f2c0bcbcd1d2bce3bcbcd3bcd1c0bcc3d3c0bc000000000000000000000000000000000000000000000000000000000000000000000000
e0e1f1e3e0e1f1e3d2e2f2e2d2f39fe2e3e0e1d1e3c3e1d1f000d28fbcc3bcc3c0c1c0c1c0c1c0c100d2f1000000c0f100d0c19f00000000e0e1f1e3bcc1c2bcbcc3bcc3e0e1f1e3c3f2f2f3bce18ff3bcbcf0e3f0f2f2f3f0d09ff3000000000000000000000000000000000000000000000000000000000000000000000000
f0f2f2f3f0f1f2f3f0d2e2e3f0d2e2e3c3d300e1c3d3c2e1c3e2d2c1c3e2d2c19fc09fc0d0f1d2c000f10000e200000000000000d0c39f00f0f1f2f3bcd3c0bcc3e2d2c1f0f1f2f3bcc1c2bcbcbcbcbcbcbcbcbcbcc1c2bcbcc1c2bc000000000000000000000000000000000000000000000000000000000000000000000000
