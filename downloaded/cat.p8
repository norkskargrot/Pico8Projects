pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- caped feline arena
-- by @powersaurus
-- based heavily on http://lodev.org/cgtutor/raycasting.html
-- and http://lodev.org/cgtutor/raycasting2.html
-- and inspired by the work of @matthughson
-- thanks for advice from @kometbomb and @doyousketch2

maps={
--name,x,y,xlimit,ylimit,numplayers)
 {"port",0,0,31,23,7},
 --{"the crossing",32,0,56,31,8},
 {"the pump room",56,0,72,16,4},
 --{"the mine",56,16,72,32,2},
 {"the stone circle",72,0,96,23,7},
 {"the great hall",96,0,127,24,8},
 {"the tower of confusion",72,24,119,31,5},
 
-- {"new map",0,20,16,31,2},
--[[ {"the rotten borough",
  48,16,71,31,0},]]
   {"single player test 1",32,24,39,31,-1},
    {"single player test 2",40,24,47,31,-1}
}


diagonals={
--*/
--[[
xt=1
yt=2

stx=3
sty=4
dx=5
dy=6
t=7
--]]
[72]={-1,0,
0,1,
1,-1,-1},
--\*
[73]={0,-1,
0,0,
1,1,1},
--*\
[74]={-1,0,
0,0,
1,1,-1},
--/*
[75]={0,1,
0,1,
1,-1,1}
}

 names={
  "marlin",
  "balthozar",
  "sabrini",
  "gendilf",
  "wellow",
  "mergona",
  "praspero"
 }


function _init()
 init_gfx()
 
 world=make_world({"intro",0,0,31,31})
 player=make_player(11,6)
 
 instructions=false
 map_pick=2
 
 _draw=draw_title
 _update=update_title
 
 -- skip title
 --init_game()
end

function update_title()
 if btnp(5) then
  init_game()
 elseif btnp(4) then
  sfx(9)
  instructions=not instructions
 elseif btnp(➡️) then
  map_pick=(map_pick+1)%#maps
 elseif btnp(⬅️) then
  map_pick=(map_pick-1)%#maps
 end
 
 turn_player(player,0.0027)
end

function draw_title()
 draw_perspective(world,
  player,dist_table)
 if instructions then
  print("  ❎ toggle strafe\n  🅾️ fire\n  ⬆️\n⬅️⬇️➡️ move - l/r turn",20,48,7)
 else
  print("caped feline arena",28,32,7)
  local name=maps[map_pick+1][1]
  print("play map: "..name,44-#name*2,64,7)
  print("⬅️ and ➡️ to select",26,72,7)
 end
 print("    press ❎ to start\npress 🅾️ for instructions",
  14,96,7)
end

function init_game()

 respawn_timer=0
 scoreboard_timer=0
 timer=0
 level_time_limit=5400
 
 id=1
 start_idx=flr(rnd(#world.starts))
 
 strafe=false
 draw_map=false
 ai=true

 hvy=0 -- move hand
 
 frog_msg=""
 frog_msg_timer=0

 init_gfx()
 
 cats={}
 players={}
 projectiles={}
 w_items={}
 
 world=make_world(
  maps[map_pick+1]
 )
 
 if(sp)level_time_limit=32000
  --92,13
 player=make_player(14,3)
 --24,11)-- --14,3
 -- if selecting maps
 respawn_pl(player)
-- turn_player(player,0.333)

--[[ local cat=make_cat(
  {11.5,5.5,1,0,0})
 add(sprites,cat)
 add(cats,cat)
 add(players,cat)--]]
 
 for i=1,maps[map_pick+1][6]-1 do
  spawn_cat() 
 end
 add(players,player)
 
 _draw=draw
 _update=update
 menuitem(1,"toggle map",toggle_map)
 menuitem(2,"toggle ai",function()
  ai=not ai
 end)

end

function next_level()
 map_pick=(map_pick+1)%#maps
 init_game()
end

function init_gfx()
 create_palettes()
 
 dist_table={}
 cam_t={}
 for y=0,128 do
  dist_table[y]=128/(2*y-128)
  cam_t[y]=2*y/128-1
 end
 
 sprites={} 
 particles={}
end

function toggle_map()
 draw_map=not draw_map
end

function update()
 if timer>=level_time_limit then
  scoreboard_timer+=1
  respawn_timer=0
  
  if scoreboard_timer==300
  or btnp(4) then
   _init()
  end
  return
 else
  timer+=1
  hy=clamp(hvy,0,20)
  hvy=max(hvy-4,-3)
  update_doors(doors)
 
  if(frog_msg_timer>0)frog_msg_timer-=1
  if respawn_timer>0 then
   if respawn_timer==1 
   or (respawn_timer<60 and btnp(4))
   then
    if sp then
     init_game()
    else
     respawn_pl(player)  
    end
    respawn_timer=0
    return
   end
   respawn_timer-=1
  else
   do_input()
   player:update()
  end
 
  if ai then
   for _,s in pairs(cats) do
    s:update()
   end
  end
 
  for _,p in pairs(projectiles) do
   p:update(players)
   if p.health==0 then
    del(projectiles,p)
    del(sprites,p)
   end
  end
  
  for _,s in pairs(particles) do
   s.z+=s.vz
   s.x+=s.vx
   s.y+=s.vy
   s.health-=1
   if(s.z>30 or s.health==0)del(particles,s)
  end
 end
end

function do_input()
 strafe=false
 if(btn(5))strafe=true
 
 if btn(4) then
  if player.shoot_timer<=0 then
   if player.wand==3 then
    hvy+=5
   else
    hvy+=20
   end
   fire(player)
  end
 end
 if btn(0) then
  if strafe then
   strafe_in_current_dir(player,-0.1)
  else
   turn_player2(player,-0.0065)
  end
 end
 if btn(1) then
  if strafe then
   strafe_in_current_dir(player,0.1)
  else
   turn_player2(player,.0065)   
  end
 end

 if btn(2) then
  move_in_current_dir(player,0.08)
 end
 if btn(3) then
  move_in_current_dir(player,-0.08)
 end
end

function pick_spawn_pt(e)
 start_idx=(start_idx+1)%#world.starts
 return world.starts[start_idx+1]
end

hy=0
function draw()
 reset_palette()

 if draw_map then
  draw_map_view(world,player)
 else
  draw_perspective(world,
  player,dist_table)
  
  if timer>=level_time_limit
  or respawn_timer>0
  then
   draw_scoreboard(player,cats)
  else
   --hand  
   local spd=0
   if(abs(player.v)>0.1)spd=sin(timer/20)*3
   sspr(96,112,32,16,72+hy+spd,96+hy/2,64,32)
   sspr(64+player.wand*8,104,8,24,88+hy+spd,56+hy/2,16,48)

   draw_hud(player)
  end  
 end
end

function draw_scoreboard(p,cats)
 local scores={}
 add(scores,{
  name=p.name,
  frogs=p.frogs})
 foreach(cats,function(c)add(scores,{name=c.name,frogs=c.frogs})end)
 
 for i=1,#scores do
  for j=i+1,#scores do
   if(scores[i].frogs<scores[j].frogs)scores[i],scores[j]=scores[j],scores[i]
  end
 end
 
 clock()
 if not sp then
  for i,c in pairs(scores) do
   local y=16+i*10
   print(c.name,28,y,7)
   print(c.frogs,96,y,7)
  end
 end
 local r_o_r="restart"
 local m="final score"
 if sp then
  m="you were frogged!"
 elseif timer<level_time_limit then 
   r_o_r="respawn"
   m="scores"
 end
 
 print(m,64-#m*2,16,7)
 print("press 🅾️ to "..r_o_r,26,112,7)
end

function set_frog_msg(msg)
 frog_msg=msg
 frog_msg_timer=30  
end

function draw_hud(player)
 reset_palette()
 --health
 local hc=7
 if player.hurt_timer>0 then
  hc=8
  local h,hx,hy,hw,hh=
   player.h_angle,
   0,0,
   128,128
  
  if h>0.35 and h<0.65 then
   hh=4
  elseif h>0.85 or h<0.15 then
   hy=124
  elseif h>0.15 and h<0.35 then
   hx=124
  else
   hw=4
  end 
  rectfill(hx,hy,hw,hh,8)
 end
 
 local ps=223
 if(player.quad_timer>0)ps=191
 spr(ps,1,119)
 print(player.health,10,121,hc)
 spr(220,23,120)
 if player.wand>0 then
  print(player.ammo,33,121,7)
 else
  spr(221,33,120)
 end
 if player.hat>0 then
  spr(222,1,111)
  print(player.hat,10,113)
 end
 clock()
 
 if(frog_msg_timer>0)print(frog_msg,2,10,7)

-- print("cpu: "..stat(1),2,2,7)
end

function clock()
 if(sp)return
 
 local countdown=level_time_limit-timer
 local seconds=flr(countdown/30)%60
 if(seconds<10)seconds="0"..seconds
 print(flr(countdown/1800)
  ..":"..seconds,57,2,7)
end
-->8
-- raycasting
-- draw the 3d view
 
function draw_perspective(
 world,
 player,
 dist_table)

 local 
  posx,posy,drx,dry,
  camx,camy,ang,
  floors,zbuf,dr_buf=
  player.x,
  player.y,
  player.drx,
  player.dry,
  player.camx,
  player.camy,
  player.a,
  {},{},{}
 local invdet=1/(camx*dry-camy*drx)
 
  -- sky
 rectfill(0,64,128,76,0)
 rectfill(0,28,128,64,1)
 
 floor_cast(
  world,
  posx,posy,drx,dry,camx,camy,
  dist_table)
     
 -- first raycast pass
 ray_cast(
   world,   
   posx,posy,drx,dry,camx,camy,
   diagonals,
   cam_t,
   0,
   127,
   nil,
   false,
   floors,
   zbuf,
   dr_buf)

 -- pass for walls over doors 
 for i=1,#dr_buf,3 do
  ray_cast(
  world,
  posx,posy,drx,dry,camx,camy,
  diagonals,
  cam_t,
  dr_buf[i],
  dr_buf[i+1],
  dr_buf[i+2],
  true)
 end
 ceiling_cast(
  floors,
  world.ceiling,
  posx,posy,
  dist_table)

 -- draw sprites
 ce_heap_sort(sprites,posx,posy)

 for _,s in pairs(sprites) do
  s:draw(posx,posy,drx,dry,
   camx,camy,ang,invdet,zbuf)
 end--]]
  
 reset_palette()

 for _,s in pairs(particles) do
  local s_x,s_y=
   s.x-posx,
   s.y-posy
  
  local tfx,tfy=
   invdet*(dry*s_x-drx*s_y),
   invdet*(-camy*s_x+camx*s_y)
  local scr_x,scr_y=
   64*(1+tfx/tfy),
   64-(s.z/tfy)

  if tfy>0 and tfy<128 then
   local s_dist=sqrt(s_x*s_x+s_y*s_y)
   if zbuf[flr(i)]>s_dist then
    local sz=
     flr(clamp(5-s_dist,0,3))
    rectfill(
     scr_x,
     scr_y,
     scr_x+sz,
     scr_y+sz,
     s.c)
   end
  end
 end

end

oh_tex={
[-1]=6,
[-2]=2,
[-4]=3,
[-5]=13,
[-7]=13
}

function ray_cast(
 world,
 posx,posy,drx,dry,camx1,camy,
 diagonals,
 cam_t,
 s_x,e_x,
 dr_tex,
 bad_wall_hack,
 floors,
 zbuf,
 dr_buf)

 local rayx,rayy,
  perpwalldist,
  wallx,
  raydirx,raydiry,
  mapx,mapy,
  dr_ptr,dr_seg, -- dr originally meant 'door'
  old_p,old_h,old_side,
  dond,dend,half_height,
  side,stepx,stepy,
  sidedistx,sidedisty,stack_tex
  =
  posx,posy,
  0,
  0,
  0,0,
  0,0,
  -2,false,
  0,0,0,
  0,0,0,
  0,0,0,
  0,0,{}
  
 for x=s_x,e_x do 
  rayx,rayy=posx,posy

  local camx=cam_t[x]
  
  raydirx,raydiry
  =
   drx+camx1*camx,
   dry+camy*camx
   
  mapx,mapy
  =
   flr(rayx),
   flr(rayy)
  
  local ddx,ddy=
   abs(1/raydirx),abs(1/raydiry)

  if abs(raydirx)<0.01 then
   if raydirx<0 then
    raydirx=-0.01
   else
    raydirx=0.01   
   end
   ddx=100
  end
  if abs(raydiry)<0.01 then
   if raydiry<0 then
    raydiry=-0.01
   else
    raydiry=0.01   
   end
   ddy=100
  end
  
  local hit,texidx,
   d_open,dr_ray,
   tele_dist--backwards,weird
   =
   0,world[mapy][mapx],
   nil,false,
   0
  local last_texidx=texidx

  if raydirx<0 then
   stepx=-1 
   sidedistx=(rayx-mapx)*ddx 
  elseif raydirx>0 then
   stepx=1
   sidedistx=(mapx+1-rayx)*ddx 
  end
   -- perpendicular so 'infinite'
  -- sidedistx=20000
  --end
  
  if raydiry<0 then
   stepy=-1
   sidedisty=(rayy-mapy)*ddy
  elseif raydiry>0 then
   stepy=1  
   sidedisty=(mapy+1-rayy)*ddy
  end
  -- sidedisty=20000
  --end
  
  while hit==0 do
   if sidedistx<sidedisty then
    sidedistx+=ddx
    mapx+=stepx
    side=0
   else
	   sidedisty+=ddy
    mapy+=stepy
    side=1
   end
   last_texidx=texidx
   texidx=world[mapy][mapx]
   
   -- check moving from outside->inside overhang
   -- >=-6 lo wall indoors tiles
   -- <=-7 hi wall indoors+outdoors
   -- <=-8 hi wall outdoors
   if (texidx<=-1 and texidx>=-6) --inside
   and last_texidx<=-7 --outside
   and (sidedistx>2.3
    or sidedisty>2.3) then
    if bad_wall_hack then
     hit=1
     texidx=dr_tex
    
    elseif last_texidx<=-7 --outside
    and not dr_seg then
     dr_ptr+=3
     dr_buf[dr_ptr]=x
    
     dr_buf[dr_ptr+2]=
      oh_tex[texidx]
     -- todo remove!
     if not oh_tex[texidx] then
      printh("need t for "..texidx)
     end
     dr_seg=true
    end
    dr_ray=true
   elseif texidx==-67 then
    texidx=last_wall(mapx,mapy,world)
    hit=1 
   -- check for wall texture tiles 
   elseif texidx>=0 then
    -- wall over door
    if texidx<=1
    and last_texidx<=-7
    and bad_wall_hack then
     hit=1
     texidx=dr_tex or 14
    elseif texidx<=1 then
     -- door handling
     if last_texidx<=-7
     and not dr_seg then
      dr_ptr+=3
      dr_buf[dr_ptr]=x 
      dr_buf[dr_ptr+2]=last_wall(mapx,mapy,world)
      dr_seg=true
     end
     
     dr_ray=true
     
     -- do a load of extra calculations
     -- for the offset door
     local map_x2,map_y2=mapx,mapy
     if (rayx<map_x2) map_x2-=1
     if (rayy>map_y2) map_y2+=1
      
     if(texidx==0)d_open=door_for(mapx,mapy).open_pcnt/100

     local rdy2,rdx2=
      raydiry*raydiry,raydirx*raydirx
     if side==0 then
      local ray_mult=((map_x2-rayx)+1)/raydirx
      local rye=rayy+raydiry*ray_mult   
      local ddx2=sqrt(1+rdy2/rdx2)
      local y_step=sqrt(ddx2*ddx2-1)

      local plus_half_step=rye+(stepy*y_step)/2
      if flr(plus_half_step)==mapy then
       if (texidx==1
        and flr((plus_half_step-mapy)*16)%4<3)
       or (texidx==0 
        and plus_half_step-mapy>d_open)
       then
        hit=1
        mapx+=stepx/2
       end
      end
     else
      local ray_mult=(map_y2-rayy)/raydiry
      local rxe=rayx+raydirx*ray_mult

      local ddy2=sqrt(1+rdx2/rdy2)
      local x_step=sqrt(ddy2*ddy2-1)
      local plus_half_step=rxe+(stepx*x_step)/2
      if flr(plus_half_step)==mapx then
       if (texidx==1 
        and flr(((plus_half_step)-mapx)*16)%4<3) 
       or (texidx==0 
        and plus_half_step-mapx>d_open)
       then
        hit=1
        mapy+=stepy/2
       end
      end
     end
    elseif texidx==99 then
     if tele_dist==0 then
      if side==0 then
       tele_dist=64+64/((mapx-rayx+
        (1-stepx)/2)/raydirx)
      else
       tele_dist=64+64/((mapy-rayy+
       (1-stepy)/2)/raydiry)
      end
     end
     local tele=tele_for(mapx,mapy,world)
     mapx-=tele.x
     rayx-=tele.x
     mapy-=tele.y
     rayy-=tele.y
    elseif texidx>=72 then--diagonal
     local s=diagonals[texidx]
     local dx,dy=sub_v2(
        posx,posy,
        mapx+s[3],
        mapy+s[4])
     local int=
      cross(
       dx,dy,raydirx,raydiry)
        /cross(raydirx,raydiry,s[5],s[6])

     if int<1 and int>=0 then
      texidx=world[mapy][mapx+s[7]]
      if side==0 then
       mapx+=s[1]+s[5]*int
      else
       mapy+=s[2]+s[6]*int
      end
      hit=1
     end
    else
     if not dr_ray 
     and dr_seg 
     and dr_ptr>0 then
      dr_buf[dr_ptr+1]=x
      dr_seg=false
     end
     hit=1
    end
   end
  end

  if side==0 then
   perpwalldist=(mapx-rayx+
    (1-stepx)/2)/raydirx
   wallx=rayy+perpwalldist*raydiry
  else   
   perpwalldist=(mapy-rayy+
    (1-stepy)/2)/raydiry
   wallx=rayx+perpwalldist*raydirx
  end

  wallx-=flr(wallx)
  local texx,
  stacks,
  stack_start
  =
   flr(wallx*16),
   0,
   0
   
  stack_tex[0],
  stack_tex[1]
  =
   texidx,
   min(texidx%8,texidx)

  -- hi-wall tiles or water
  if ((last_texidx<-6 and last_texidx>=-13)
  or last_texidx==-16)
  and texidx>1 then
   stacks=1
  end
  
  -- this is terrible, but i am trying to avoid an extra check
  if bad_wall_hack then
   stack_start=1
  else
   zbuf[x]=perpwalldist
  end
  
  if texidx==0 then
   if d_open>0 then--whuuuuuut
    texx+=1
   end
   texx-=d_open*16
  end
  
  local lheight=flr(128/perpwalldist)
  
  if lheight~=old_h
  or side~=old_side then
  
   half_height=lheight/2
   local dstart=-(half_height)+64
   dend=half_height+64

   local dcol=
    min(15,flr((dend-dstart)/2))
   if (side==1) dcol=max(dcol-3,0)
   local p=clamp(15-dcol,0,6)
   if p~=old_p then
    palette_no_t(p)
    old_p=p
   end
   dond=dend-dstart+1
  end

  -- teleport
  if tele_dist~=0 then
   palette_no_t(7)
   line(x,tele_dist,x,dend,1)
   old_p=p
  end 
  -- no walls for water tile
  if not(last_texidx<=-15
  and texidx==15) then
   for i=stack_start,stacks do
    local dstart2=
     -half_height*(max(1,i*3))+64
    
    sspr(
    stack_tex[i]%8*16+texx,
    flr(stack_tex[i]/8)*16,
    1,16,
    x,dstart2,
    1,dond)
    if last_texidx==-7
    or last_texidx==-8 then
     pal(1,1)
     line(x,0,x,dstart2,1)
    end
   end
  end
  old_h=lheight
  old_side=side

  -- draw every other vertical line
  if x%2==0
  and not bad_wall_hack then
   add(floors,
    {
     x,
     raydirx,
     raydiry,
     flr(max(max(
      80,
      dend),tele_dist))})
  end
 end
 reset_palette()
 
 if dr_seg or (not bad_wall_hack 
 and #dr_buf%3>0) then
  dr_buf[dr_ptr+1]=127
 end
end

function last_wall(mapx,mapy,world)
 local t=world[mapy-1][mapx]
 if(t>1)return t
 return world[mapy][mapx-1] 
end

skx=0
function floor_cast(
 world,
 posx,posy,drx,dry,camx,camy,
 dist_table)
 local px,py=
  posx-1,posy-1
 
  -- player direction
 local stx,sty=
  -camx+drx,-camy+dry
 
 -- do not loop floor textures
 poke(0x5f38,0)
	poke(0x5f39,0)
	poke(0x5f3a,0)
	poke(0x5f3b,0)
 for y=77,127 do
  palette_no_t(
   clamp(82-y,0,15)
  )
  local curdist=dist_table[y]

  local d16,j=
   curdist/64,
   y%2*.025
  
  tline(0,y,127,y,
   j+px+stx*curdist,
   j+py+sty*curdist,
   d16*camx,d16*camy)
 end
 
 poke(0x5f38,4)
	poke(0x5f39,4)
	poke(0x5f3a,28)
	poke(0x5f3b,28)
	--
 for y=0,32 do
  local curdist=dist_table[y]

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

function ceiling_cast(
 floors,
 ceiling,
 px,py,
 dist_table)

 palette(3)
 for i,f in pairs(floors) do
  local x,
   raydirx,raydiry,
   start_dither=
   f[1],f[2],f[3],f[4]
  local x_width=x+3

  for y=128-i%2,start_dither,-2 do
   local curdist=dist_table[y]
  
   local cfloorx,cfloory=
    curdist*raydirx+px,
    curdist*raydiry+py

   local floortex=
    ceiling[flr(cfloory)][flr(cfloorx)]

--.767->.775
   if floortex<999 then 
    rectfill(x,128-y,x_width,128-y,
     sget(cfloorx*8%8+floortex,
          cfloory*8%8+48)
    )
   end
  end
 end
end

-->8
-- cats/sprites

function spawn_cat(cat,pt)
 local spawn_pt=pt or pick_spawn_pt(cat)
 
 if cat then
  respawn(cat,spawn_pt,true)
 else
  cat=make_cat(spawn_pt)
  add(sprites,cat)
  add(cats,cat)
  add(players,cat)
 end
  
 cat.target_p,
 cat.think_timer,
 cat.strafe_accel
 =
  nil,1,0
 return cat
end

function make_cat(spawn_pt)
 local c=make_sprite(
  spawn_pt,
  0,
  spawn_pt[3],
  spawn_pt[4],
  24,32,
  0,64,
  0.75,1,
  spawn_pt[5],true)
 respawn(c,spawn_pt,false)
 
 c.id,
 c.think_timer,
 c.shoot_timer,
 c.strafe_timer,
 c.target,
 c.target_timer,
 c.name,
 c.frogs,
 c.aware
 =
  id,
  1,
  0,
  0,
  vec(-100,-100),
  0,
  names[id]or"bob",
  0,
  true
 
 id+=1 --each cat needs their own id

 c.kill=function(self,pj)
 
  hurt(self,pj)
  self.aware=true
  --50% chance they will
  --target you
  if rnd(1)<0.5 
  and self.id~=pj.src.id then
   self.target_p=pj.src
  end
  if self.health<=0 then
   drop_wand(self)
   add_frog(self)
   if not sp then
    spawn_cat(self)
   else
    del(cats,self)
    del(players,self)
    del(sprites,self)
   end
   
   return true
  end

  return false
 end
 
 c.do_plan=function(self,has_los)
  local accelr,rot,dist=
   0.08,
   pick_rotation(self.a,self.target_r),
   dist_sq(self,self.target_p)

		if not c.search
		and dist<11
		and c.strafe_timer<=0 then
		 c.strafe_accel=(flr(rnd(2))*2-1)*0.1
		 c.strafe_timer=15
		end
	 	if rot>0 then
		  self.vr+=0.0027
		 else
		  self.vr-=0.0027		
		 end
		--end
		
  --[[if dist_sq(self,self.target_p)
  >8 then
   -- far from player
   -- so accel stays 0.08==]]
  if has_los
  and not c.search 
  and dist<10
  and c.target_p.health>0
  then
  -- close, so slow
 	 accelr=-0.08   
  elseif c.search then
   c.strafe_accel=0
  end

 	if abs(rot)<0.043
  and has_los then
   self.shoot=true
 	end
 	
  move_in_current_dir(self,accelr)  
  strafe_in_current_dir(self,c.strafe_accel)
  update_p(self)

  if self.shoot_timer<=0
  and self.shoot then
   fire(self)
   self.shoot=false
  end
 end

 c.update=function(c)
  c.think_timer-=1
  c.target_timer-=1
		c.strafe_timer-=1
 
  if not c.target_p 
  or c.target_timer<0 then
   c.target_p=pick_target(c,cats,player)
   c.target_timer=30
  end
  local target=c.target_p
  local has_los=has_los_to_target(
   c,
   target)
  
  local near_item=pick_target(
   c,w_items,target)

  if not sp
  and c.wand==0 
  and has_los_to_target(
   c,
   near_item) 
  and dist_sq(c,near_item)
   <dist_sq(c,target)then
   c.target=copy(near_item)
   c.think_timer=30
   --yuck
   c.search=true
   c.last=copy(c)
  elseif has_los then
   --printh("can see")
   -- try to track, instantly
   c.target=copy(target)
   c.last_seen=c.target
   c.target_timer+=1
   c.search=false
   c.aware=true
  elseif c.last_seen 
  and c.think_timer>0 then
   c.target=c.last_seen
   c.last_seen=nil
   c.think_timer=120
  elseif c.search 
  and c.think_timer>0
  and (dist_sq(c,c.target)<3
   or (c.think_timer<95 
   and dist_sq(c,c.last)<2)) then
   
   search(c)
  elseif c.think_timer<=0 then
   search(c)
  end
  
  if c.aware then
   turn_to_target(c)
   
   c:do_plan(has_los)
  end
 end 
-- printh(c.name.." joined the game")
 return c
end

function search(c)
 c.think_timer,
 c.last,
 c.search
 =
  160,
  copy(c),
  true
 
 local try=c.last_seen
 if(not try)try=c
 c.target=vec(
  try.x+rnd(4)-2,
  try.y+rnd(4)-2
 )
 c.last_seen=nil
end

function pick_rotation(a,t_a)
 local cw,ccw=
  (a+(1.0-t_a))%1.0,
  ((1.0-a)+t_a)%1.0
  
 if cw>ccw then
  return ccw
 else
  return -cw
 end
end

function pick_target(
 c,things,
 was_closest)
 if(sp)return player
 local closest=was_closest
 local c_dist=dist_sq(c,closest)
 for a in all(things) do
 	if a.respawn_timer==0 
  or a.id~=c.id then
   local d=dist_sq(c,a)
   if d<c_dist
   and a.health>0 then
    c_dist=d
    closest=a
   end
  end
 end
 
 return closest
end

function has_los_to_target(
 c,
 target)
 local rxe,rye=single_ray_cast(
  c,
  normalize(sub_v(c,target)),
  world
 )

 return is_between_v(
  target,
  c,
  {x=rxe,y=rye})
end

function turn_to_target(c)
 local t=sub_v(c,c.target)
 local new_r=
  loop_angle(atan2(-t.y,-t.x)-0.25)
 
 rotate_to(c,new_r)
end

function add_frog(s)
 local sp=make_sprite(
  s,
  50,
  s.drx,
  s.dry,
  16,16,
  48,112,
  0.3,0.3,
  0,false)

 sp.health,
 sp.vy,
 sp.update=
  20,
 -20,
  function(s)
   s.health-=1
   s.vy+=2
   s.z+=s.vy
  end
 add(sprites,sp)
 add(projectiles,sp)
end

function make_sprite(pos,z,drx,dry,
 width,height,
 tex_x,tex_y,
 w_scale,v_scale,
 a,rotate)
 local s={
  a=a,
  target_r=0,
  drx=drx,
  dry=dry,
  z=z,
  health=100,
  rotate=rotate,
  width=width,
  height=height,
  tex_x=tex_x,
  tex_y=tex_y,
  scale=v_scale,
  w_scale=w_scale,
  draw=draw_billboard_sprite
 }
 copy2(s,pos)
 return s
end

function draw_billboard_sprite(
 s,
 posx,
 posy,
 drx,
 dry,
 camx,
 camy,
 ang,
 invdet,
 zbuf)
 
 local 
  tex_x,tex_y,
  t_w,t_h,
  s_x,s_y,
  shade,
  rotate_s,
  s_scale,
  s_w_scale
  =
  s.tex_x,s.tex_y,
  s.width,s.height,
  s.x-posx,
  s.y-posy,
  not s.fullbright,
  s.rotate,
  s.scale,
  s.w_scale
 
 local
  s_dist, 
  t_x,t_y
  =
  sqrt(s_x*s_x+s_y*s_y),
  invdet*(
   dry*s_x-
   drx*s_y
  ),
  invdet*(
   -camy*s_x+
   camx*s_y
  )
--  if t_y>0 and t_y<128 then
 
 local sscr_x,sc_y=
  flr(64*(1+t_x/t_y)),
  flr(abs(128/t_y))
 local s_height,s_width=
  sc_y*s_scale,
  sc_y*s_w_scale
 local s_width2=s_width/2

 local ds_y,ds_x,de_x=
  -s_height/2+64+(s.z/t_y),
  -s_width2+sscr_x,
  s_width2+sscr_x
 if(ds_x<0) ds_x=0
 if (de_x>=128) de_x=127
 
 if t_y>0 and t_y<128 then
  local a_to_spr=loop_angle(s.a-ang)
  
  local rot_tex_idx=tex_x
  if rotate_s then
   local h=s.hurt_timer>0
   if a_to_spr<.125
   or a_to_spr>.875 then
    rot_tex_idx+=t_w*2
   elseif a_to_spr>=.125 
   and a_to_spr<.347 then
    rot_tex_idx+=t_w
    if(h)rot_tex_idx=t_w*3 
   elseif a_to_spr>.625 then
    rot_tex_idx+=t_w*2
    if(h)rot_tex_idx=t_w*4
    t_w*=-1
   elseif h then
    rot_tex_idx+=t_w*4
   end
  end
  
  if shade then 
   palette(clamp(flr(s_dist-2),0,6))
  else
   reset_palette()
  end
 
  for i=ds_x,de_x do
-- this is broken
   if zbuf[flr(i)]>s_dist then
    local texx=(
     i-(-s_width2+sscr_x))*t_w/s_width
    
    sspr(rot_tex_idx+texx,tex_y,1,t_h,i,ds_y,1,s_height)
   end
  end
 end
end

-->8
-- utils

function is_between(e,a,b)
 -- mega bad hack booooo fix fix fix
 -- fix fix fix
 if(a==b) return true
 local tmp=a
 if b<a then
  a=b
  b=tmp
 end
 
 if e>=a and e<=b then
  return true
 end
 return false
end

-- if a cardinal direction
-- it will not work, because
-- the x or y value will be the same

function is_between_v(e,a,b)
 if is_between(e.x,a.x,b.x)
 and is_between(e.y,a.y,b.y)
 then
  return true
 end
 
 return false
end

function loop_angle(a)
 if (a>=1) return a-1
 if (a<0) return a+1
 
 return a
end

function clamp(val,mi,ma)
 return max(mi,min(ma,val))
end

function vec(x,y)
 return {x=x,y=y}
end

function sub_v(a,b)
 return {x=b.x-a.x,y=b.y-a.y}
end

function sub_v2(ax,ay,bx,by)
 return bx-ax,by-ay
end

function cross(ax,ay,bx,by)
 return ax*by-ay*bx
end

function v_len(x,y)
 return sqrt(x*x+y*y)
end

function normalize(a)
 local len=v_len(a.x,a.y)
 
 return {x=a.x/len,y=a.y/len}
end

function dist_sq(a,b)
 local dx,dy
 =
  a.x-b.x,
  a.y-b.y
 return dx*dx+dy*dy
end

function dist_sq2(a,b)
 if flr(a.x)~=flr(b.x)
 or flr(a.y)~=flr(b.y) then
  return 100
 end
 return 0
end

function dist_sq3(ax,ay,bx,by)
 local dx,dy=
  ax-bx,
  ay-by
 return dx*dx+dy*dy
end

function copy(a)
 if(not a)return nil
 return {x=a.x,y=a.y}
end

function copy2(a,b)
 a.x,a.y=b.x,b.y
end

-- adapted from heap sort
-- originally by @casualeffects
function ce_heap_sort(data,x,y)
 if (#data==0) return
 local n = #data
 
 for d in all(data) do
  local dx,dy=
   (d.x-x)/10,
   (d.y-y)/10
  d.key=dx*dx+dy*dy
 end

 -- form a max heap
 for i = flr(n / 2) + 1, 1, -1 do
  -- m is the index of the max child
  local parent, value, m = i, data[i], i + i
  local key = value.key 
  
  while m <= n do
   -- find the max child
   if ((m < n) and (data[m + 1].key < data[m].key)) m += 1
   local mval = data[m]
 
   if (key < mval.key) break
   data[parent] = mval
   parent = m
   m += m
  end
  data[parent] = value
 end 

 -- read out the values,
 -- restoring the heap property
 -- after each step
 for i = n, 2, -1 do
  -- swap root with last
  local value = data[i]
  data[i], data[1] = data[1], value

  -- restore the heap
  local parent, terminate, m = 1, i - 1, 2
  local key = value.key 
  
  while m <= terminate do
   local mval = data[m]
   local mkey = mval.key
   if (m < terminate) and (data[m + 1].key < mkey) then
    m += 1
    mval = data[m]
    mkey = mval.key
   end
   if (key < mkey) break
   data[parent] = mval
   parent = m
   m += m
  end  
  
  data[parent] = value
 end
end


-->8
-- player

function make_player(x,y)
 local p={
  id=0,
  vr=0,
  name="playero",
  frogs=0,
  update=update_p,
  kill=function(s,pj)
  
   if s.health>0 then
    hurt(s,pj)
    s.h_angle=loop_angle(s.a-pj.a)

    if s.health<1 then
     drop_wand(s)
     respawn_timer=90
     
     return true
    end
   end
   return false
  end
 }
 respawn(p,
  {x,y,1,0,0},
  false)
 return p
end

--929
function drop_wand(s)
 if s.wand>0 then
  local i=items[s.wand]
  local w=
   add_item(
    s.x,s.y,
    i[1],
    get_wand,
    i[4])
    
  w.typ,
  w.ammo,
  w.no_respawn
  =
   i[2],
   min(s.ammo,200),
   true
 end
 if s.quad_timer>0 then
  local q=add_item(
   s.x,s.y,
   56,
   get_quad,
   "got medal of quard d' mage")
  q.time=s.quad_timer
  q.no_respawn=true
 end
end

function respawn(self,spawn_pt,announce)
 self.x,
 self.y,
 self.drx,
 self.dry,
 self.a,
 self.v,
 self.vr,
 self.sv,
 self.hat,
 self.wand,
 self.ammo,
 self.hurt_timer,
 self.shoot_timer,
 self.quad_timer,
 self.invul_timer,
 self.health,
 self.keys
 =
  spawn_pt[1],
  spawn_pt[2],
  spawn_pt[3],
  spawn_pt[4],
  spawn_pt[5],
  0,0,0,
  0,0,0,
  0,0,0,
  30,	--invulnerability
  100,
  {}
 
 self.camx,
 self.camy
 =
 (self.dry)/3*2,
 (self.drx)/3*2
 
 if announce then
  f_smoke(self,12)
  near_sfx(0,self,player)
 end
end

function hurt(s,pj)
if(s.invul_timer>0)return
 local dmg=pj.dmg
 
 local less=
  min(s.hat,flr(dmg*0.5))

 s.hat=max(s.hat-less,0)

 dmg-=less
 s.health-=dmg
 s.hurt_timer=4
 
 if(s.health<1)set_frog_msg(pj.src.name.." frogged "..s.name)

end

function move_in_current_dir(s,amount)
 s.v=clamp(s.v+amount,-0.3,0.3)
end

function strafe_in_current_dir(s,amount)
 s.sv=clamp(s.sv+amount,-0.2,0.2)
end

function calc_rot(player,ar)
 local r,oldplanex=
  player.a,
  player.camx

 player.drx,
 player.dry
 =
  cos(r),-sin(r)
 
 player.camx,
 player.camy
 =
  oldplanex*cos(ar)+
   player.camy*sin(ar),
  -oldplanex*sin(ar)+
   player.camy*cos(ar)
end

function turn_player(player,ar)
 player.a=loop_angle(player.a+ar)
 
 calc_rot(player,ar)
end

function turn_player2(player,ar)
 player.vr+=ar
end

function update_p(s)
 s.shoot_timer-=1
 
 if(s.hurt_timer>0)s.hurt_timer-=1
 if(s.quad_timer>0)s.quad_timer-=1
 if(s.invul_timer>0)s.invul_timer-=1

	s.vr*=0.75
	s.a=loop_angle(s.a+s.vr)
 
 calc_rot(s,s.vr)
  
 s.v*=0.6
 s.sv*=0.95
 local mvx,mvy,px,py=
  player.camx*s.sv
   +s.drx*s.v,
  player.camy*s.sv
   +s.dry*s.v,
  s.x,
  s.y

 local movex,movey,mvx_a,mvy_a=
  px+mvx,
  py+mvy,
  (mvx/abs(mvx))*0.3,
  (mvy/abs(mvy))*0.3
 
 if(mvx==0)mvx_a=0
 if(mvy==0)mvy_a=0
 
 local mmx,mmy=
  flr(movex+mvx_a),
  flr(py)
 local move_sq=world
  [mmy][mmx]
 
 if move_sq<0
 and move_sq~=-15
 and move_sq~=-16
 or open_door_for(
  mmx,mmy,move_sq)
 or check_diag(
 px,py,
 mvx,0,
 mmx,mmy,
 move_sq,0.55)
 then
  s.x=movex
  px=movex
 elseif move_sq==99 then
  teleport(s,mmx,mmy,world)
  return
 end
 
 if move_sq==-66
 and s.id==0 then
  next_level()
  return
 end

 mmx,mmy
 =
  flr(px),
  flr(movey+mvy_a)
 move_sq=world
  [mmy][mmx]
 
 if move_sq<0
 and move_sq~=-15
 and move_sq~=-16
 or open_door_for(
  mmx,mmy,move_sq)
 or check_diag(
  px,py,
  0,mvy,
  mmx,mmy,
  move_sq,0.55)
 then
  s.y=movey
 elseif move_sq==99 then
  teleport(s,mmx,mmy,world)
 end
 if(move_sq==-67)set_frog_msg("you found a secret!")
 if move_sq==-66
 and s.id==0 then
  next_level()
  return
 end
end

function check_diag(
 px,py,
 raydirx,raydiry,
 mapx,mapy,
 move_sq,di)

 if move_sq>=72 and move_sq<=75 then
 
  local s=diagonals[move_sq]
  local dx,dy=sub_v2(
   px,py,
   mapx+s[3],
   mapy+s[4])
  local int=
   cross(
    dx,dy,raydirx,raydiry)
    /cross(raydirx,raydiry,s[5],s[6])
  
  if int<1 then
 --[[  if raydirx==0 then
    -- correct intersection for y in both dirs
    local ti=mapy+abs(s.sty-int)
    --py<ti and raydiry+y>ti
    
    local i=int+mapy
    local m=raydiry+py
    printh(move_sq.." int="..
     ti.."  newpos="..m.." "..
     abs(ti-m))]]
   --end--]]
   if raydiry==0 then 
    local ti=mapx+abs(s[3]-int)
     
    if abs(ti-(raydirx+px))>di then
     return true
    end
   end
   if raydirx==0 then
    local ti=mapy+abs(s[4]-int)
      
    if abs(ti-(raydiry+py))>di then
     return true
    end
   end
  end
 end
 return false
end
 
function rotate_to(s,targetrotation)
	s.target_r = targetrotation
end

function teleport(s,mmx,mmy,world)
 copy2(s,sub_v(
  tele_for(
   mmx,
   mmy,
   world),
  s))
 near_sfx(0,s,player)
 f_smoke(s,12)
end

function respawn_pl(s) 
 respawn(s,pick_spawn_pt(s),true)
end

function near_sfx(snd,s,ppos)
 if dist_sq(s,ppos)<25 then
  sfx(snd)
 end
end
-->8
-- map utils/doors

map_dr={
{0,1,0.75},
{0,-1,0.25},
{-1,0,0.5},
{1,0,0}
}
saved_ents={}

tele_entries={92,93,94,95}
tele_exits={76,77,78,79}

function save_ent(x,y,map_tile,last_floor_tile)
 add(saved_ents,{x,y,map_tile})
 mset(x,y,last_floor_tile)
end

function make_world(mp)
 set_frog_msg("you enter "..mp[1])
 map_to_tex={}
-- printh("loading map")
 
 -- check single player map flag
 sp=false
 if(mp[6]==-1)sp=true
 
 -- setup tile mapping
 -- i am sorry
 for i=1,16 do
  local i4=i%4
  map_to_tex[95+i],
  map_to_tex[112+i-1],  
  map_to_tex[72+i4],
  map_to_tex[92+i4],
  map_to_tex[68+i4],
  map_to_tex[64],
  map_to_tex[65],
  map_to_tex[66],
  map_to_tex[67]  
  =
   -i, -- floor
   i-1, --wall
   72+i4, --diagonal
   99, --tele
   -68-i4, --sp enemies
   0,--key door
   0,--key door
   -66,--level end
   -67--secret wall
 end
 
 -- restore map
 for e in all(saved_ents) do
  mset(e[1],e[2],e[3])
 end
 saved_ents={}
 
 local new_world,tele,
 last_floor_tile
 =
  {
   starts={},ceiling={}
  },
  {{},{},{},{}},
  96

 doors={}

 for y=mp[3],mp[5] do
  local ry=y+1
  new_world[ry],
  new_world.ceiling[ry]
  =
   {},{}
  for x=mp[2],mp[4] do
   local rx=x+1

   local cx,cy,map_tile
   =
    rx+.5,
    ry+.5,
    mget(x,y)
   -- is it a floor tile
   if map_tile>=96 and map_tile<=109 then
    last_floor_tile=map_tile
   end

   -- level end
   if map_tile==66 then
    save_ent(x,y,map_tile,last_floor_tile)
    map_tile=66

   -- sp cat
   elseif map_tile>=68 and map_tile<=71 then
    local c=spawn_cat(nil,{cx,cy,0,1,0.75})
    c.ammo,
    c.wand,
    c.aware,
    c.health
    =
     999,
     map_tile-68,
     false,
     50
    save_ent(x,y,map_tile,last_floor_tile)
    map_tile=last_floor_tile
   -- is it a player start
   elseif map_tile>=80 and map_tile<=83 then
    local dr=map_dr[map_tile-79]    -- set floor tex

    -- add p start
    --x,y,drx,dry,ang
    add(new_world.starts,
     {
      cx,cy,
      dr[1],dr[2],
      dr[3]
     })
   -- keys
   elseif map_tile==84
   or map_tile==85 then
    local k=map_tile-84
    add_item(
     cx,cy,
     64+k*8,
     get_key,
     "got a key")
     .k=k
   elseif map_tile==91 then
    add_item(
     cx,cy,
     48,
     get_health,
     "got health")
   elseif map_tile==86 then
    add_item(
     cx,cy,
     56,
     get_quad,
     "got medal of quard d' mage")
     .time=300
   elseif map_tile>=87
   and map_tile<=89 then
    items={
     {96,1,5,"got the double barreled wand"},
     {104,2,5,"got the bombnd"},
     {112,3,100,"got the chainwand"}
    }
    local i=items[map_tile-86]
    
    local w=add_item(
     cx,cy,
     i[1],
     get_wand,
     i[4])
    w.typ,w.ammo
    =
     i[2],
     i[3]
   elseif map_tile==90 then
    add_item(
     cx,cy,
     120,
     get_hat,
     "got the hat of hardiness")
   elseif map_tile==68 then
    save_ent(x,y,map_tile,last_floor_tile)
    map_tile=68
   end

   for p=1,4 do
    if tele_entries[p]==map_tile then
     tele[p].entry=vec(rx,ry)
     save_ent(x,y,map_tile,last_floor_tile)
    elseif tele_exits[p]==map_tile then
     tele[p].exit=vec(rx,ry)
    end
   end

   if map_tile>=76 
   and map_tile<=91 then
    save_ent(x,y,map_tile,last_floor_tile)
    map_tile=last_floor_tile
   end
   
   local t=map_to_tex[map_tile]
   new_world[ry][rx],
   new_world.ceiling[ry][rx]
   =
    t,
    to_ceiling(t)
   
   if map_tile==112
   or map_tile==64
   or map_tile==65
   then--door
    local door={x=rx,y=ry,open_pcnt=0,open_vel=0}
    add(doors,door)
    local ft=last_floor_tile
    if map_tile<66 then
     ft=map_tile
     door.key=64-map_tile
    end
    save_ent(x,y,map_tile,ft)
   elseif map_tile==113 then--bars
    save_ent(x,y,map_tile,last_floor_tile)
   elseif (map_tile>=72 and map_tile<=75)--diag
   then
    local ft=mget(
     x-diagonals[map_tile][7],y
    )
    
    save_ent(x,y,map_tile,ft)
    new_world.ceiling[ry][rx]=
     to_ceiling(map_to_tex[ft])
   end
  end
 end
 for t in all(tele) do
  if t.entry then
   t.d=
    sub_v(
     t.exit,
     t.entry)
  end
 end
 new_world.tele=tele
 
 return new_world
end

function to_ceiling(t)
 if t and t<=1 and t>=-6 then
  return max(abs(t*8)-8,0)
 end
 return 9999
end

function door_for(x,y)
 for _,d in pairs(doors) do
  if d.x==x and d.y==y then
   return d
  end
 end
 return nil
end

function open_door_for(x,y,s)
 return s==0 and door_for(
  x,y
 ).open_pcnt>70
end

function tele_for(x,y,world)
 for _,d in pairs(world.tele) do
  if d.entry and d.entry.x==x and d.entry.y==y then
   return d.d
  end
 end
 return nil
end

function update_doors(doors)
 for _,d in pairs(doors) do
  local near_door=false
  local near_p=nil

  for _,p in pairs(players) do
   local is_near=dist_sq3(
     p.x,p.y,
     d.x+0.5,d.y+0.5)<2
   
   near_door=near_door or is_near
   if(is_near)near_p=p
  end
  
  if near_door then
   if not d.key or near_p.keys[d.key] then
    if d.open_pcnt==100 then
     near_sfx(6,{x=d.x,y=d.y},player)
    end
    if d.open_pcnt<100 then
     d.open_vel=5
    
     if d.open_pcnt==0 then
      sfx(-1)
     end
    end
   else
    set_frog_msg("you need a key") 
   end
  else
   if d.open_pcnt>0 then
    d.open_vel=-5
    if(stat(17)~=7) then
     near_sfx(7,{x=d.x,y=d.y},player) 
    end
   elseif d.open_pcnt==100 then
    sfx(-1)
   end
  end
  d.open_pcnt=clamp(d.open_pcnt+d.open_vel,0,100)
 end  
end

--185 tokens

function draw_map_view(world,player)
 cls(5)
 reset_palette()

 local px=8*(player.x-1)
 local py=8*(player.y-1)
 
 camera(px-64,py-64)
 
 reset_palette()

 map(
  0,0,
  0,0,
  128,32)

 local pxe,pye,
 cpxe,cpxe2,cpye,cpye2
 =
  px+player.drx*5,
  py+player.dry*5,
  px+player.camx*5,
  px-player.camx*5,
  py+player.camy*5,
  py-player.camy*5
 
 line(
  px,py,
  pxe,pye,
  10)
  
 line(
  cpxe2,cpye2,
  cpxe,cpye,
  8)
 pset(px,py,9)

 for _,s in pairs(sprites) do
  local px,py
  =
   8*(s.x-1),
   8*(s.y-1)

  if s.drx then
   local pxe=px+s.drx*5
   local pye=py+s.dry*5
 
   line(
    px,py,
    pxe,pye,
    10)
  end
  if s.src then
   line(
    px,py,
    8*(s.src.x-1),8*(s.src.y-1),
    8)
  end
  
  --[[circfill(px,py,1,8)
  if s.target then
   circfill(8*(s.target.x-1),8*(s.target.y-1),3,14)
  end
  if s.target_p then
   circfill(8*(s.target_p.x-1),8*(s.target_p.y-1),2,11)
  end
  --]]
 end
 
 --[[for _,p in pairs(particles) do
  pset(8*(p.x-1),8*(p.y-1),11)
 end]]
 camera()
 print(player.x..","..player.y,2,120,7)
 
end
--]]
--[[
function pad(x)
 if(x<10)return "0"..x
 return x
end

function write_map(mx,my,mw,mh,num_p)
 for e in all(saved_ents) do
  mset(e[1],e[2],e[3])
 end
 
 local map_str=pad(mx)..pad(my)..mw..mh..pad(num_p)
 for y=my,mh do
  for x=mx,mw do
   map_str=map_str..chr(mget(x,y))
  end
 end
 printh(#map_str)
 printh(map_str)
 return map_str
end

function read_map(m,maps)
 local mx=tonum(sub(m,1,2))
 local my=tonum(sub(m,3,4))
 local mw=tonum(sub(m,5,6))
 local mh=tonum(sub(m,7,8))
 local num_p=tonum(sub(m,9,10))

 printh(mx)
 printh(my)
 printh(mw)
 printh(mh)
 printh(num_p)
 local i=11
 for y=my,mh do
  for x=mx,mw do
   mset(x,y,ord(sub(m,i,i)))
   i+=1
  end
 end
 printh("wrote "..(i-9).." tiles")
 maps[99]={"user map",mx,my,mw,mh,num_p}
 map_pick=98
end
--]]
-->8
--projectiles

function check_hit_fireball(self,e)
 if dist_sq(self,e)<self.scale then
  self.hit=true
  smoke(e.x,e.y,0.5,10,10,self.id)
  if e:kill(self) then
   self.src.frogs+=1
   self.src.target_p=nil
   near_sfx(5,e,player)
  else
   near_sfx(2,e,player)
  end
 end
end

function fire(s)
 s.shoot_timer=13
 
 if s.wand==1 then
  local l,r,spx,spy
  =
   add_fireball(
    s,
    28,0.25,0.5),
   add_fireball(
    s,
    28,0.25,0.5),
   s.camx*.3,
   s.camy*.3
   
  l.x+=spx
  l.y+=spy
  r.x-=spx
  r.y-=spy
 elseif s.wand==2 then
  local p=add_fireball(
   s,
   80,0.5,0.3)
  p.typ,
  p.tex_x,
  p.tex_y
  =
   2,32,112
 elseif s.wand==3 then
  local f=add_fireball(
   s,
   6,0.125,0.6)
  local z=sin((timer*20)/360)*0.3+0.2
  f.x+=s.camx*z
  f.y+=s.camy*z
  f.z+=rnd(30)-15
  s.shoot_timer=3
 else
  add_fireball(
   s,
   24,0.3,0.5)
 end
  
 if s.wand>0 then
  s.ammo-=1
  if s.ammo==0 then
   s.wand=0
   f_smoke(s,12)
  end
 end
 if s.quad_timer>0 then
  f_smoke(s,11)
  near_sfx(13,s,player)
 end
end

function add_fireball(
 s,
 dmg,
 sc,v)
 local pj=make_sprite(
  s,
  30,
  s.drx,
  s.dry,
  16,16,
  32,96,
  sc,sc,
  s.a,
  false)
 
 pj.id,
 pj.src,
 pj.health,
 pj.dmg,
 pj.update,
 pj.v,
 pj.fullbright
 =
  s.id,
  s,
  4,
  dmg,
  update_projectile,
  v,
  true
 
 if(s.quad_timer>0)pj.dmg*=4
 
 add(projectiles,pj)
 add(sprites,pj)
 near_sfx(1,s,player)

 return pj
end

function get_health(i,c)
 c.health=min(c.health+25,125)
end

function get_quad(i,c)
 c.quad_timer=i.time
 sfx(14,1)
end

function get_key(i,c)
 c.keys[i.k]=true
end

function get_hat(i,c)
 c.hat=min(c.hat+50,100)
end

function get_wand(i,c)
 if i.typ==c.wand then
  c.ammo+=i.ammo
 else
  c.wand,c.ammo
  =
   i.typ,
   i.ammo
 end
 
 if(c.id==0)hvy=30
end

-- tables is not fewer tokens atm

function add_item(
 x,y,
 tex_x,
 get_item,
 get_msg)
 
 local h=make_sprite(
  vec(x,y),
  30+rnd(20),
  0,0,
  8,8,
  tex_x,96,
  0.33,0.33,
  0,false)
  
  h.vz,
  h.fullbright,
  h.respawn_timer,
  h.get_item,
  h.get_msg,
  h.ammo,
  h.no_respawn,-- if singleplayer
  h.update,
  h.draw
  =
   0,
   true,
   0,
   get_item,
   get_msg,
   5,
   sp,
  function(s,players)
   s.z+=s.vz
   s.vz+=0.4
   if(s.z>50)s.vz=-3
   if s.respawn_timer>0 then
    s.respawn_timer-=1
   else
    for _,c in pairs(players)do
     if dist_sq2(s,c)<2
     and s.respawn_timer==0
     and c.health>0 
     and (not sp or c.id==0) then
      s.respawn_timer=300
      s:get_item(c)
      f_smoke(c,10)
      if c.id==0 then
       set_frog_msg(s.get_msg)
       sfx(10,0)
      end
      if s.no_respawn then
       s.health=0
       del(items,s)
      end
     end
    end
   end
  end,
 function(
  s,px,py,dx,dy,cx,cy,a,i,z)
   if s.respawn_timer==0 then
    draw_billboard_sprite(
     s,
     px,
     py,
     dx,
     dy,
     cx,
     cy,
     a,
     i,
     z)
   end
  end
 
 add(projectiles,h)
 add(w_items,h)
 add(sprites,h)
 return h
end

function update_exp(s)
 check_hits(s)
 s.health-=1
 s.z=-30
 s.scale+=0.5
 s.w_scale+=0.5
end

function update_projectile(s)
 local px,py,
  mvx,mvy
  =
   s.x,s.y,
   s.drx*s.v,s.dry*s.v

 local movex,movey=
  px+mvx,py+mvy
 
 local mmx,mmy=
  flr(movex),flr(py)
 local move_sq=world
  [mmy][mmx]
  
 if move_sq<0
 or open_door_for(
  mmx,mmy,move_sq)
 or (check_diag(
  px,py,
  mvx,0,
  mmx,mmy,
  move_sq,0.1))
 then
  s.x=movex
  px=movex
 else
  s.hit=true
 end
 
 if not s.hit then
  mmx,mmy
  =
   flr(px),
   flr(movey)
  move_sq=world
   [mmy]
   [mmx]
 
  if move_sq<0
  or open_door_for(
   mmx,mmy,move_sq)
  or (check_diag(
   px,py,
   0,mvy,
   mmx,mmy,
   move_sq,0.1))
  then
   s.y,py
   =
    movey,
    movey
  else
   s.hit=true
  end
 end

 if s.hit then
  s.health=0
  smoke(px,py+0.25,0.1,10,10,s.id)
  near_sfx(4,s,player)
 end
 
 if not s.hit then
  check_hits(s)  
 end
 
 if s.hit and s.typ==2 then
  smoke(px,py+0.25,
    0.4,10,10,s.id)
  s.health=0
  
  local pj=add_fireball(s.src,6,0.2,0.2)
  near_sfx(15,s,player)
  pj.update,
  pj.height,
  pj.health,
  pj.id
  =
   update_exp,
   10,
   6,
   -99
  copy2(pj,s)
 end
end

function check_hits(s)
 for _,e in pairs(players) do
  if e.id~=s.id then
   check_hit_fireball(s,e)
  end 
 end
end

function f_smoke(s,c)
 smoke(s.x+s.drx,s.y+s.dry,0.5,1,c,0,0,0)
end

function smoke(
 x,y,d,s,c,id,vx,vy)
 -- dont make far away particles
 if(id~=0 and dist_sq3(x,y,player.x,player.y)>25)return

  for i=0,1,0.1 do
   local dx,dy=
    -d*sin(i)-rnd(0.2),
    d*cos(i)-rnd(0.2)
   local nvx,nvy=
    vx or dx,
    vy or dy
   
   add(particles,{
    x=x+dx,
    y=y+dy,
    z=rnd(100)-70,
    vx=nvx/3,
    vy=nvy/3,
    vz=rnd(1.0)+s,
    health=10+rnd(5),
    c=c	})
  end
end
   
function single_ray_cast(p,ray,world)
 local px,py=p.x,p.y
 local map_x,map_y,
  rayx,rayy
  =
  flr(px),flr(py),
  ray.x,ray.y
 
 local side,step_x,step_y,
  dx,dy,
  hit,rxe,rye
  =
  0,0,0,
  abs(1/rayx),abs(1/rayy),
  0,0,0
 
 if rayx<0 then
  step_x=-1
  side_x=(px-map_x)*dx
 else
  step_x=1
  side_x=(map_x+1-px)*dx 
 end
 if rayy<0 then
  step_y=-1
  side_y=(py-map_y)*dy
 else
  step_y=1
  side_y=(map_y+1-py)*dy
 end
 
 while hit==0 do
  if side_x<side_y then
   side_x+=dx
   map_x+=step_x
   side=0
  else
   side_y+=dy
   map_y+=step_y
   side=1
  end
  local t=world[map_y][map_x]

  if t>1 then
   hit=1
   
   if (px<map_x) map_x-=1
   if (py>map_y) map_y+=1
   
   local adj,ray_mult=1,1
   if side==1 then
    adj=map_y-py
    ray_mult=adj/rayy
   else
    adj=(map_x-px)+1
    ray_mult=adj/rayx
   end
   rxe,rye
   =
    px+rayx*ray_mult,
    py+rayy*ray_mult
  end
 end
 return rxe,rye
end

-->8
--palette stuff

function reset_palette()
 palette(0)
end

function palette(z)
 memcpy(0x5f00,0x5000+16*z,16)
 palt(12,true)
end

function palette_no_t(z)
 memcpy(0x5f00,0x5000+16*z,16)
 palt(12,false)
end

function create_palettes()
 for z=0,7 do
  for i=0,15 do
   poke(0x5000+16*z+i,
    sget(48+i,z+104))
  end
 end

end

__gfx__
11111111111111111510151015101510112221111112221111111111515113331224212224912449999144949991449911111111111111111155511111115551
19f29f59f29f29f115101510151015104111114422115114155111b3bb65111112449124249124494491122444411124d66d61d6661d6661155d511155155dd1
14954944954954f11d101d101d101d102211142222211142bb15133b3bbb5111124491244291244422211112224111125555d1555d1555d1156d5115d5156dd5
14424424454424911d101d101d101d10222112222222112255113335bb6b353312449124429124241111111211111111111111111111111111565115651156d5
14944944944944411d101d101d101d1025211222555211223300133355533513124491244291242400000010000000100000000000000000111d5111d5111dd5
14424424425424411d101d101d101d105511155551111112115111313333151112449124429144441111111011111110001001001001001015dd515dd515ddd5
12222222222222211d101d101d101d101111111111442111111551101111111112249124429144492224499144429991111111111111111115555155551555d5
14245242542442411d101d101d101d101144221114422111b5b3331510151533122421244291444215222221242245411565155115667771156d5156d5156dd5
14444444444dd1411d101d101d101d1014222214422221113333115155566b1312249124429144421552222155524551155551100555556111565115651156d5
12222222222211211d101d101d101d101222251222222144110115333535b651124491244291444911111221111222515d5d511005ddd551111d5111d5111dd5
11111111111111111d101d101d101d10112551122222114210001133335533151244912442912449111111111111111115d5d11005dddd5115dd515dd515ddd5
12212212212212211d101d101d101d1021111122525114225111511333333111124491244291244922212222222122221d5d51100511d55115555155551555d5
1242452552441441151015101510151051111125551112221566510113311101124491244291244222411442442111241111115001111111156d5156d5156dd5
121144144145114115101510151015101144211251141152b635b6100111016b12449124429124422241141124211114d55155100165155511565115651156d5
11112111211211111110111011101110142222111142211153335b6510005b35124491224291242912211111112111116d51151111dd155d111551115511155d
111111111111111111101110111011101222221111222211333333351155333312249124429124291111111111111111d6d11111111111110111111111111111
12421111112444211524444515124451112221111112221153333b3505333333222222224524422214444444144444441111111111111111666d6ddd666d66d6
241111111111114211122222115112214111114422115114b553b355153333bb222245224422425219999944124449925d6771111d677715dddddddddddddddd
4111159422221114151151111111111122221122222111423b33351111533b35245244222422224214444222112454425dddd155ddddd6151111111111111111
2111942211112114111114420942111122222122222211221133511531113511545242222222522211522222112224425d5d51555d5d55150000000000000000
11194251115152124591199409941122222521155222112255111105351111154442424452255225111115221111111211155111111511510101010010001010
115421511151121144411aa90aa911225555111155521112dd511100051111554452222444244424111111111111111111511111111111111111111111111111
119421511151152111211000000011121111111111111111ddd511010011155d44222222242444222999122244991444551155d6677715561111111111111111
11921111111111215111199409941111114421111442211166d521010011255d24255242242242222454115222221242551155555556155551151155d111d1d1
119211211121112111211aaa0aaa1221142122144222211166d521011011255d22245244241222212455115522221555d51ddddddd5515d555d5d51555155555
114211211121114111110aaa0aaa1221121215121212214466d521011012235d222442442222441222251111112211115d11ddddddd5115d5555155d55555555
11421121112111411111094409441111112111112111114266b5210113b235b412144222212144221111111111111111d51111111d5511d55d555d555dddd5d5
1142112111211121551100001111122521111112125114226335130110312235222442144112422412222222122222221111111151111111555dd55ddddd5ddd
1152115111511151445111111111122451111121111112123343b1001013153542122112441221441112422411442442555d666711555d555d5ddddddddddddd
1155115111511151222111122551111111d51111111111513633113b0013b545422442214422424411114224114112425555d5d61155d6d5555dddd5555dd555
115511511151115111111111211111111d511d51115111114555255033123525121441122224412411111122111111121111111511111d6d5155d555d55551d5
11111111111111112255555511225551155155111d5511d55155151000115151211121111414111211111111111111115d5d515d5d5d5d5d1111151511151111
122222281111111d222222282222222855b00025550b00255500b02555000b25d66666d11d66666d125555555555552122222224111111131111111e1111111d
282888121d5ddd5128eeee8e288eee8e2522555525225555252255552522555566666d1221d66666d125ddd55ddd521d299999971bbbbbb71222222f1dddddd7
288888821dddddd128e8888e28e888e92555d5dd2555d5dd2555d5dd2555d5dd6666d125521d66666d125dd55dd521d6222221241333313b1111e11e1111111d
289999821dccccd128eee88e2e8888e95885588d5885588d5885588d5885588d666d12555521d66666d125d55d521d66222221241333313b1111e11e1111111d
1299928215ccc5d128e8888e2888ee8e5985598559855985598559855985598566d125d55d521d66666d12555521d666292292271b33b3371211211f1d11d117
288998821ddccdd128eeee8e2889888e255225552552255525522555255225556d125dd55dd521d66666d125521d6666292292271b33b337121121171d11d117
288888821dddddd12888888e288ee88e12525d5112525d5112525d5112525d51d125ddd55ddd521d66666d1221d66666299999971bbbbbb7122222271dddddd7
122222281111111d8eeeeeee8ee99eee0225ddd00225ddd00225ddd00225ddd01255555555555521d66666d11d66666d4777777737777777ef777777d7777777
11111115111111151111111511111115d000098dd00006d05500002500000000d510000000000d50000110000000000022222224111111131111111e1111111d
1dddddd61dddddd61dddddd61dddddd6000000980000006d252255550a944420dd511110011155150101501005555550299999971bbbbbb71222222f1dddddd7
1ddd2dd61d2222261ddd2dd61dd2ddd600000982000006d12555d5dd0a9442216d5518111111d15d1015d50155666675292222971b3333b7121111271d1111d7
1dd222d61dd222d61dd22dd61dd22dd600080820000d0d105885588d0011111116d552211d5d65d11015d501b5555551292222971b3333b7121111271d1111d7
1d2222261ddd2dd61d222dd61dd222d60082820000d1d100598559850a944420116d5191551511110115dd50b3666631299229971bb33bb7122112271dd11dd7
1dddddd61dddddd61dd22dd61dd22dd6082098000d106d00255225550a944221118217a1515d11110115dd50bb536631299229971bb33bb7122112271dd11dd7
1dddddd61dddddd61ddd2dd61dd2ddd60089820000d6d10012525d510011111101129a7a55d111101111511d0b333330299999971bbbbbb7122222271dddddd7
56666666566666665666666656666666d008200dd00d100d0225ddd000000000000000aa0000000000111150000000004777777737777777ef777777d7777777
5555555d44244494111111115351113111111224cccccccc222222294424449411b1151514414414ddddddd6444f944413b3b511442444940101010111d1dd11
5d5ddd5554452444151555111113511112222222cccccccc2424442254452444b135315114914424d6d666dd54994594d53533515445244410101010d5dd115d
5dddddd544522442155555511115311112244442cccccccc24499442444244421153113514914924d666666d444444453353113344522442010101011d1001d1
5d6666d52422194415dddd513113111512444942cccccccc249f9942242414441531b11324914924d677776d42f994945335135324221944101010101d1000d1
556665d54444444211ddd5511111515512449942cccccccc249f9242444444443135135124924929dd777d6d4494449935135b354444444201010101d5d1015d
5dd66dd542245442155dd5511131113122499942cccccccc24999442442454421511151314914924d667766d454449443111111342245442101010101d511dd1
5dddddd521424444155555511135111124444442cccccccc24494442244244445111513524414914d666666d44499429535351352142444401010101015dd510
5555555d42144124111111111351135112222224cccccccc22222229421441241111153124424914ddddddd64924444211313531421441241010101000d01d00
11111111111111110011110051115113144144142222222211111111111111111111111111000011499004495111511311111111111111111111111100000000
19a29a5110011001115254911311131b14914424222245221dddddd515d115d112211412122a4a1242924a921311131b12211412122494121d1d1dd100000000
1495494150055005129554211331111b1491492424524422111111111565156111111111114a2411044999901131111b11111111111111111d6761d100000000
1442442160066006124152211b31511b24914924545242221dd005511565156121442214244a4a14049a49a951155115215dd514244412441dddd15100000000
14944941d00dd00d1521122113b3111b24924929444242441d50055115d5156111444211104a4a119994049451155115111dd111111111111d5d515100000000
1442442150055005152154511b33131314914924445222241115511115d515d11144421210000025044909925115511511511512111111221115511100000000
1222222110011001151155111b3b1113244149144422222211511d6115d115d1119442111111111120299a995115511511d11d111111111111511d6100000000
1111111111111111011011101b331511244249142425524211111111111211124194421444512451924249041111111141d11d14444124441111111100000000
c1111ccccccccccccc11111ccccc111ccccc155cccccccccccc11111cccccccccc11111ccccc111ccccc155cccccccccc1111ccccccccccccc11111ccccccccc
c155511cc111111c115f551ccccc15f55cc155fcccccccccccc1555511c1111c1155551ccccc15f55cc155fcccccccccc155511cc111111c115f551ccccccccc
c155ff9115555551555f51cccccc15ff5551559ccccccccccccc155555155551555551cccccc15ff555151111cccccccc155ff9115555551555f51cccccccccc
cc15ff9155555555519f51cccccc159ff5555555cccccccccccc151155555555551151cccccc159ff5551aaaa1cccccccc15ff9155555555519f51cccccccccc
cc15f99155555555551951cccccc1599555551155ccccccccccc151155555555551151cccccc159955551aa0a1cccccccc15f99111111555551951cccccccccc
cc15011511115555511151cccccc155555551aa155cccccccccc111555555555555111cccccc155555551aa0a1cccccccc15011aaaaaa155111111cccccccccc
ccc11151aaaa15551aaa1ccccccc115555551a0155ccccccccccc5555555555555555ccccccc115555551aaaa15cccccccc1111a00aaa151aaaaa1cccccccccc
ccc11151aa0a15551a0a1ccccccc115555551a015555ccccccccc5555555555555555ccccccc1155555551aaa155ccccccc1111a00aaa151aa00a1cccccccccc
cccc1151aa0a15551a0a1ccccccc115555551aa155500cccccccc5555555555555555ccccccc11555555551115500ccccccc1151aaaaa151aa00a1cc55cccc25
cccc1151aaaa15551aaa15cccccc115555551aa155000ccccccc555555555555555555cccccc11555555555555000ccccccc1151aaaaa151aaaaa1cc25225555
cccc115511115115511155cccccc11555555511555050ccccccc155555555555555551cccccc11555555555555050ccccccc11551aaa11151aaa15cc2555d5dd
cccc111555555005555555cccccc11155555555555055cccccc11155555555555555111ccccc11155555500000055ccc4ccc111551115005511155cc5335533d
cccc91100555000055505ccccccc11155555555550555cccccccc1155551111555511ccccccc11155555507770555cccc4cc11100000000055505ccc5b355b35
cccc41110000055000015ccccccc11115555555005515ccccccc111111111111111111cccccc11115555500005515cccc29c11107777770000015ccc25522555
cccc2911111555555115ccccccccc1111155555555119ccccccccc11111111111111ccccccccc111115555555511cccccc4cc110777700555115cccc22525d5d
cccc241111111155555ccccccccc1111111111115ccc4cccccccccc111111111111cc4cccccc1111111111115ccccccccc24111111111155555cccccc225dddc
cccc121111115555551ccccccccc1111111111155cc24ccccccccc1111111555551c44cccccc111111111115ccccccccccc2411111115551111ccccccccccccc
ccc11291551111111111ccccccc115511111115555c4cccccccc111155555d5ddd664cccccc1155111111155ccccccc4ccc22111555551111dd6cccccccccccc
cc1d12455555511155516ccccc111ddddd5551155554ccccccc1111d55dddd5ddddd6ccccc111ddddd5551155cccc24ccc11555111111111dd6d6ccccccccccc
cc1d1245555515151551d6cccc111dddd5d6d1111522ccccccc1111d5ddddd55d1dd6ccccc111dddd5ddd11555cc24cccc1155515511551dd66d6ccccccccccc
cc1d1111555511515511dd6ccc111dddd5d6d15551111cccccc1111ddd5dddd5d11d6ccccc111dddd5ddd11115c24ccccc11155151111515d6dd34cccccccccc
c11d1551155555555111dd6cc1111dd1d5d6d15555551ccccc11111dd51dddddd51dd6ccc1111dd1d5ddd15511111cccc11d11111155111ddddd6ccccccccccc
c1dd15551555555551515d6cc1111d51dd55615555551cccc111111d551dddddd51dd6ccc1111d51dd55d15555551cccc11ddd111555515dddd666cccccccccc
c1d515551555555551515d6cc1111d51dddd511111551cccc111111551ddddddd551d6ccc1111d51dddd515555551cccc1dddd15555551ddddd6d6cccccccccc
c1d511111555555551115dd6c1111151dd1d51555111ccccc111111551dddd1ddd51d6c1c1111151dd1d511115551cccc1dddd15555115ddddd6d6cc55cccc25
1dd511115555555555515dd611111151d51d5155555ccccc1111111111ddd51ddd551dd111111151d51d51555111cccc1ddddd1155115ddd556dd6cc25225555
1dddd1115555555555511ddd11111111d5115155555ccccc1111111115ddd51dddd51dd111111111d5155155555ccccc1ddddd11551155d55dddd6cc2555d5dd
1dddd1115555555555551ddd1111111115115115555ccccc1111111115555551ddd551d11111111111155155555ccccc155dddd155551155ddddd6cc5885588d
155dd11155555555555515ddc111111115115511555ccccc11555111111111111dd55111c111111111151151555cccccc1155dd155555115ddddd6cc59855985
111551111111115555551555c111111111111111115ccccc115555555511111111111cccc111111111111551115ccccccc11155511111111555dd6cc25522555
cc11111111111111111115ccccc11111111111111111cccccc11155555511111111cccccccc11111111115111111cccccc11111111111111111111cc22525d5d
cccc1111111111111111cccccccccc11111111111111cccccccc111111111111111ccccccccccc11111111111111cccccccc11111111111111111cccc225dddc
d555511115555555111155ddddd5555dcccccccccccccccccccccccc55cccc25ccccc98cccccc6dccccccccccccccccccccccccccccccccccccccd5cccc11ccc
d55511111555555511115555555555ddccccc111111cccccc6dddddc25225555cccccc98cccccc6dccccccccccccccccc9cc9ccccc1221cccccc5515ccc15ccc
d55511115555555111115555555555ddccc1112222221ccc55dd55152555d5ddccccc982ccccc6d1ccccccccccccccccc94c94ccc128821cc111d15dcc15d5cc
55551111515555551111555555555dd5cc11999aa99921cc3dbddd355885588dccc8c82ccccdcd1ccccccccccccccccccc4cc4ccc289982c15d675d1cc15d5cc
55551111111155555d1155555555ddddc1129a777aa921cc36dd66d359855985cc8282ccccd1d1ccccccccccccccccccc144141cc287782c5d151111c105dd5c
d5551111111115dddddd55555555ddddc129aa7777aa921c3db5ddb325522555c82c98cccd1c6dcccccccccccccccccc11142021c128821c515d11115005dd51
d555511111155dddd1115555555dddddc129a777777a921c13bbbb3112525d51cc8982ccccd6d1ccccccccccccccccccc110202c1122221155d1111c0001511d
555555515555dddd1111155555dddd55c129a777777a921cc111111cc225dddcccc82ccccccd1cccccccccccccccccccccccccccc111111ccccccccccc00015c
155555555ddddddd1111155555dd55d1c129a777777a921c0123456789abcdefcc4ccccc4cc4ccccc51cccccc111cccccc1111ccccccccccccc11ccc55cccc15
1115555555dddddd1111555555d55111c129a777777a921c0123456789abcdefcc9ccccc9cc9ccccc51ccccc12421cccc124991cccccccccccc15ccc15115555
11115555555ddddd11111555555d1111c129a77777aa921c0123556624abdd89cc42cccc42c4ccccc35ccccc24141ccc12497791c77c776ccc15d5cc1555d5dd
11111555555555dd1111115555511111c129aaaaaaa921cc012311dd12a35524cc42cccc42c42ccccd5ccccc24c91ccc0249aa917cc75cc6cc15d5cc5aa55aad
11111115555555555111115555ddd111cc129999999911cc0015105d11a51112cc42cccc42c42cccc155cccc22141ccc014499417ccd7ccdc105dd5c59a559a5
1dd111111155555551115555dddddd11ccc1222222211ccc1101001511a11011cc944ccc94492cccc135cccc21211ccc01444441c6d5c6dcc005dd5c15511555
dddd11111115555551111111111dddddccccc111111ccccc1000111111a11011ccc94cccc9412cccc1c35cccc21911ccc011221ccccccccc0001511d11515d5d
dddd11111111555551111111151111ddcccccccccccccccc01ddcdccdcccccccccc42cccc4211cccc5cd5cccc219111ccc0000cccccccccccc00015cc115dddc
11111dd111115555511111ddd5551111cccc2ccccccccccccccccccc17ccccccccc422ccc42212ccc5cd5ccc2114121ccccccccccccccccccccccccccccccccc
11111dd55111555511111dddd5555111ccccc111111c2cccccc8cccc17ccccccccc422ccc42212ccc15d5ccc24c1541ccccccccccccccccccccccccccccccccc
11111dd5551555551111dddddd55d111cc2c11222222cc2ccc888cbbddc17cccccc422ccc42212ccc1135ccc2211141ccccc111111111111cccccccccccccccc
1111ddd5555555551111ddddddddd111c2c18888988821ccc3cc883355c17cccccc922ccc92211ccc1d55ccc212121ccccc15515555111111111111ccccccccc
1111ddd55555555511dddddddd555551cc128999f99821ccc33cc853333ddccccccc92cccc9211ccc1351cccc2411cccccc155525511111111555511cccccccc
d555dd55111555551ddddddddd5dd55dcc1899ff7f99821c3b33c2253335cccccccc422ccc42212cc15511ccc291ccccccc155f911111111115555511ccccccc
dd55d55115115551dddddddddddd555dcc189ff77ff9821cccc33cc55351cccccccc422ccc42212cc35111ccc19111ccccc155f9155555551111115551cccccc
dd55555555111511dddddddddddd555dcc289f7777f921cccccc3333551ccccccccc422ccc42212cd55151cc2142111cccc115f91555555111115ddddd666ccc
d55555555111111dddddddddddddddddcc289f7777f921ccccccbb33351cccbccccc422ccc42212cd5c151cc2211121cccc1111155555511115dddddddddd666
555555551155511dddddddddddddddddcc189ff77ff9821ccabbbab335533333cccc422ccc42211c35c115cc241c221ccccc11155555111115dddddddddddddd
555555551555111dddddd5555dddddddc12899ffff99821ccb33bbb355cccc5ccccc422ccc4221115511555c29cc241cccc1551555511101111ddddddddddddd
dd555555555511dddddddd555dddddddc1288999999821cccb335bb355cccccccccc922ccc922111c513551c29cc241cccc15f155551100111111ddddddddddd
ddddd555555511ddddddddd55dddddddcc12888888881c2cccb35115b3333cccccccc92cccc92111c1d5511c24c2121cccc1591155510011111111dddddddddd
ddddd555555511dddddddddddd55ddddc2c1222222212ccc33355ccca3553cccccccc422ccc42211cd35111c2221211cccc159111511001111111111dddddddd
ddddd555555511dd555dddddddd55dddccccc112111cccccb3351cccccb33b3cccccc422ccc42211d351c1152222411cccc119111111000011111111111ddddd
555555555511555511555dddddddd555ccc2cccccccc2cccab5cccccccb3511cccccc422ccc42211335cc155c222211ccccc1111111100000011111111111ddd
__label__
55555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddd55555555555ddddddddddddddddddddddddddddddddddddddddddddddddddddd
55555555555ddddddddddddddddddddddddddddddddddddddddddddddddddd555555555555555ddddddddddddddddddddddddddddddddddddddddddddddddddd
5555555dddddddddddddddddddddddddddddddddddddddddddddddddd777ddddd7775757dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
5555555555ddddddddddddddddddddddddddddddddddddddddddddddddd7dd7ddd57575755dddddddddddddddddddddddddddddddddddddddddddddddddddddd
555555ddddddddddddddddddddddddddddddddddddddddddddddddddd777ddddd777d777dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
555555555dddddddddddddddddddddddddddddddddddddddddddddddd7dddd7dd7ddddd7dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
5555ddddddddddddddddddddddddddddddddddddddddddddddddddddd777ddddd777ddd7dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
55555555dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
111111111ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11111111111111111ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11d111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11d1111111111111111111111ddddddd11111ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
115d6666611111111111111111ddddddd11111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
115d6666611d66111111111111111111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1115555dd11d6611111111111111111111111111111111dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1115555dd115556dd61111111111111111111111111111111111dddddd11111ddddddddddddddddddddddddddddddddddddd11111ddddddddddddddddddddddd
000111111115556dd611d66661111111111111111111111111111ddddd111111ddddddddddddddddddddddddddddddddddd111111ddddddddddddddddddddddd
00011111111111555d11d6666111111111115551111111111111111111111111111111dddd111111dddd111111dddd1111111111111111dddd1111111ddd1111
001000000111111111115555d11d661111111111111111111111111111111111111111111111111111d11111111dd11111111111111111dd11111111dd111111
001000000000001111111111111555dd111111111111111111555555511555555551155111111111111111111111111111111111111111111111111111111111
1111000110000000000111111115551511555555511110111111111111111111551111155ff55555111111111111111111111111111111111111111111110000
1111000110000000000000000111111511555555511110111111111111111111551111155ff55555115511111111111111111111111111111111111111110000
6661111111111110001000000111111111555555511111000011111111111111551111155ff55555115551111111111111111111111111111111110000000100
666111111111111000110001000000111155555ffff991111155555555555555115555555ff55111555555555551111111111111111111110000000011000000
555677777111551111110001000100001155555ffff991111155555555555555115555555ff55111111111111111111111111111111111110110000011000000
555677777111551111111111100100010011555ffff991115555555555555555555511199ff55111111111111111111111111111100000000110000000100000
ddd555566111556551555111511111010011555ffff991115555555555555555555511199ff55111111001101111111111100000010010000001000000000001
dddddd555111556551555111511111111111555ff999911155555555555555555555555119955111101001101111111111110000110010000000000000000001
dddddd555115dd5555111000566666dd1111555ff999911155555555555555555555555119955111101001100011100000010000101000000000000100000000
ddddddd55115dd5dd5111000566666dd111155500111155511111111155555555555111111155111101001101010000000101000000000001000000110000011
111dddd55111555dd51110005555551d111155500111155511111111155555555555111111155111111001100010110000000000000000111111000110000011
1111dd55511155d55d1110005dddd51d111155500111155511111111155555555555111111155111100000100010010000000001000000110000000000000001
1111dd555111ddd55d1110005dddd5111151111111155111aaaaaaaaa11555555511aaaaaaa11111100000111010000000011001100000000000001000000000
111111111111dd5dd51110005ddddd511115111111155111aaaaaaaaa11555555511aaaaaaa11101100000110000000011011001100001100000011000000000
665111111111115dd51110005ddddd511115111111155111aaaa000aa11555555511aaa00aa11101111001110000000000100000000000111100000100000000
66551155555d5511111150001111d5111151111111155111aaaa000aa11555555511aaa00aa11111101001111010000110000010000000110001000001100000
ddd51155555d551111115000111111111151551111155111aaaa000aa11555555511aaa00aa11110111001100010000011000001000000000001000000100000
dddd11555dd6dd5115551000111111111111551111155111aaaa000aa11555555511aaa00aa11110100000100010000011001000011000000000110000101001
111d11555dd6dd5111551000166515111511111111155111aaaa000aa11555555511aaa00aa11110100000101010000000101000001000001000000000010000
11111111111d665111551111166515111511111111155111aaaaaaaaa11555555511aaaaaaa11555100000110000110000000110000100101000000010000000
11111111111d66d1111111111ddd15115d51111111155111aaaaaaaaa11555555511aaaaaaa11555111001110000010000000000000100101100000010000010
66711111111111d1111111111111111115d511111115555511111111155111115555111111155555101001111010001010000000100000011000011000100001
6677777115511111111111111111111115d511111115555511111111155111115555111111155555111001100010000001100010001001000000000100000001
ddd77771155111111111111111110000011111111111155555555555555000005555555555555555111001101010010100000010000000100000000100000000
dddddd61155111111111111111110000115d11111111155555555555555000005555555555555555110000101010010100000001000000100000000000000000
55dddd611551111151111511111110011155ddd99111100000555555500000000055555550055100000110001001000010000000000000000000000001000100
55dd5551155111115111151111510100115555599111100000555555500000000055555550055000101001100000000000010000110001101101111101000000
115d5551155111115111151111510100115155599111100000555555500000000055555550055100101044101010100000110000110011101101111100100000
11551115511111115111151111511100115155144111111100000000000555550000000001155110101044100010010000001000000101111111111110000000
11151115511111115111151111510001011111144111111100000000000555550000000001155110111099100010010000000000000001101111101100000001
11111111111111115111151111510001011111122991111111111115555555555555111115510110100099101010000000000001000001111111111110000001
77711111166111115111151111510000011111122991111111111115555555555555111115500101100044220000000011011001110101101101111110000000
77771155566111115111151111511110111111122441111111111111111115555555555551000101100044220000000000111001110111101101101100000011
55671155555111115111151111511110111111122441111111111111111115555555555551010111111044221010000110000000000000000000000000000011
55661155555111115111151111511110111111122441111111111111111115555555555551010111101044220010000011000010001001011011010110000001
55561155555111115111151111511010051111111221111111111111155555555555555111010110111044220010000011000001000001000111010110000000
5555115dd55110115100151001511000051155511221111111111111155555555555555111010110100044221010100000101000000110000000111110000000
dd5511155dd110115100151001510000115111111229911155551111111111111111111111100100100099444400010000001000000100000000000001100000
dd5511155dd110115100151201511000051111111229911155551111111111111111111111100101100099444400010000000110000000000000000000100000
5555111dd551101151001511015110000511ddd11224455555555555555111111155555551166111111001994410001010000000000000000000000000100000
5555111dd551101151001510015100000111ddd11224455555555555555111111155555551166111101001994410000001100000110011101101000000011001
111111111111101151001510015111000111ddd112244555555555555115511155115555511dd666111001442210010100000010001001001101101100000000
111111111111101111001110011111101111ddd112244555555555555115511155115555511dd666111001442210010100000010001001001101101100000000
555555d55551101111001110011111111111ddd112244555555555555115511155115555511dd666110000442222000010000001000000000000000000100010
555555d55551101111001110011101111111ddd111111111555555555111155511555551111ddddd660110442222000000000000000000000000000000000001
5555dd6dd551101111001110011101000111ddd111111111555555555111155511555551111ddddd660000442222000000000000000000000000000000000001
5555dd6dddd1101111001110011110001111ddd115555111115555555555555555551111111ddddd660000442222000000000000000000000000000000000000
111111d66dd1101111001110011100001111ddd115555111115555555555555555551111111ddddd660000442222000000000000000000000000000000000000
111111d66dd11111111111110000001111ddddd11555555511555555555555555555111551155ddd661001442222000000110000000001100000001001111111
55dd55d55dd50000000055500000000011ddddd11555555511555555555555555555111551155ddd661111992222111111111111111111111111111111111110
55dd55d551111111111111333311111111dd55511555555511555555555555555555111551155ddd661112992222112221111211111111111111121111111122
1311131115511111115333551155113311dd55511555555511555555555555555555111551155ddd665555559922555525555133313331555155555555555555
35111111111111111111bbbb5555311111dd55511555555511555555555555555555111551155ddd664411229922455445533311553355511551111111222444
5333155511555111115511555111111111dd55511111111111555555555555555555111111155ddddd66111244222255515555111111bbb15555311115111111
1133111335553333335555513333533311dd55511111111111555555555555555555111111155ddddd6644444422223333355555333333333333333111111111
3115551155551155511111111bb33111dddd55511111111155555555555555555555555551155ddddd6631114422225511155111111111b33333111111111131
15333331111151111111111b11111111dddd55511111111155555555555555555555555551155ddddd66331144222235511155511111111bbb111111bb111555
bbb15555511111111111111111114111ddddddddd111111155555555555555555555555551111ddddddd3331442222bb11555511111111111111111111555111
11153333315555515555514444444111ddddddddd111111155555555555555555555555551111ddddddd1111442222bb1111553333111555111555111ddd5551
33555511333311122244444442221111ddddddddd111111155555555555555555555555551111ddddddd5111442222333355333335111113311111111111d555
55511333332222224444444441111111ddddddddd111111155555555555555555555555555511ddddddd111144222255555555515555553333333111111ddddd
11444444244444444444444444444111ddddddddd111111155555555555555555555555555511ddddddd1111442222bbb33111111111111111111ddd5555ddd1
444444444444444444455544442221115555ddddd111111155555555555555555555555555511555dddd1111442222bbbb1111111bb111111111111115555551
444499999944444445544444424441115555ddddd111111155555555555555555555555555511555dddd1111442222111111111111bbb111111111111111dddd
4499999111444444444444422444411111115555511111111111111111111555555555555551155555551111442222111111111111111111111111111111dddd
2222211122224444444422222222111111115555511111111111111111111555555555555551155555551111992222115551111111111111ddd11111555ddddd
2222222222224444444422222222122222111111111111111111111111111111111111111111155533333115992222115555511111111111dddddd11555555dd
2222222222222244444444444444444244111111111111111111111111111111111111111111155533311111119922111115555555511333333ddddddddd55dd
2225522222244444444444444444422444111111111111111111111111111111111111111111155533511111119922111111355555555333333335dddddddd1d
55555444444444222444444222222222444444411111111111111111111111111111111111155515555555513344222213333333313333333315555555511111
55444444444222224444422222222244444444411111111111111111111111111111111111155111155555111144222211133333311133333311155555551111
44444444442222444442222244444444444444444444444444444444411111bbbb33333311111111111111111144222211111555111111155511111155511111
4444444442224444442222444444444444444444444444444444444441111bbbbbb3333111111111111111111144222211111555551111155555111115555111
5444442222244444444444444444444444445555544444222224444441111bbbbbb1111155551155555555111144222211111111111111355555551115555555
4442222222444444444444444444444444455555544442222224444411111bbbbb11111155551155555555111144222211111111111111333555551111155555
44422222444444444499999944444444445555554444422222244441111112222211111155555522555511111111111111115555555511113331111111111111
42222244444444444999999444444444455555544444222222444441111112222211111155555522555511111111111111115555555511113333111111111111
4444444444444449999999111144444444444444444442224444444411122222222444115555ff99111111111111111111115555555555111111111111155111
4444444444444499999991111444444444444444444422244444444111122222222444115555ff991111111111111111111155555555551111b1111111111551
4444444444444442211111111112444444444444222222222221111111111124444444115555ff99115555555555555511111111111155555511bbbbb5555555
4444444444444421111111111124444444444442222222222221111111111144444444115555ff99115555555555555511111111111155555511bbbbbb555555
4444444422222222221122222222222444444444444222222222222112222222222444111155ff9911555555555555111111111155dddddddddd666666111115
4444444222222222211122222222244444444444442222222222221112222222224444111155ff9911555555555555111111111155dddddddddd666666111111
422222222222222222222222222222222444444444444222222244444422222224444411111111115555555555551111111155dddddddddddddddddddd666666
222222222222222222222222222222244444444444442222222224444222222222444411111111115555555555551111111155dddddddddddddddddddd666666
2222222552222222222225222222222222444444444444444444444444444444444444441111115555555555111111111155dddddddddddddddddddddddddddd
2222222222222222222222222222222222444444444444424444444444442444444444441111115555555555111111111155dddddddddddddddddddddddddddd
255555555522222555555555222224444444444444444444444444444222222224444411555511555555551111110011111111dddddddddddddddddddddddddd
255555552222222555555522222224444444444444444444444444444222222244444411555511555555551111110011111111dddddddddddddddddddddddddd
55555555544555555555555444444444444444224444444444442222222222222224441155ff115555555511110000111111111111dddddddddddddddddddddd
55555551555555555555555244444444444444444444444444444222222222222224441155ff115555555511110000111111111111dddddddddddddddddddddd
515115555444555555444444411114444222222222444444222222222222222444444411559911115555551100001111111111111111dddddddddddddddddddd
51555d5dd475557575444444124991444422222244444444422222222222222244444411559911115555551100001111111111111111dddddddddddddddddddd
45aa55aad4744474744444412497791222772776222222222222222222244444444444115599111111551111000011111111111111111111dddddddddddddddd
459a559a5477747774444440249aa91227227522624442222222222222224444444444115599111111551111000011111111111111111111dddddddddddddddd
415511555474744474444440144994122722d724d44444222222222444444444444444111199111111111111000000001111111111111111111111dddddddddd
411515d5d47774447444444014444412226d526d444422222222222224444444444444111199111111111111000000001111111111111111111111dddddddddd
44115ddd444444444444444401122144222444444444444442244444444444444444444411111111111111110000000000001111111111111111111111dddddd
44444444444444444444444440000422222244444444442222222444444444444444444411111111111111110000000000001111111111111111111111dddddd

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000002020000020200000000000000000000020200000
__map__
727f7f7f727272727272727e7e7e7e7e7e7e7e72727272727272727272727272727272727272727272727272727272727272727272727272727272727272727272727e7e7e7e7272687272727272727272727272727b7b7b72727272727272727272727d7d7d7d7d7d7d7d727e7e7e7e7e7e7e7e7e7e7e7272727272727272c2
726f6f6f7272727268516868686868686868687e72727272727272727272727272727272727272727272727272727272727272727272727272726868686868686868606060497e6172687248517b7b7b727272727b4d68497b7272727272727272727d7d4866666666497d607e7e6a6a6a497e7e7e7e7e727272727272727272
72727172727272726868686860607e7e7e68687e727272727272727272727272727272727272486161614972727272727272727272727272725368686869696868687e626060497e727248686863636868684972726868687b7272727272727272727d48666666596666497d7d7e6a6a6a6a497e7e7e7e7e7272727272727272
726060605d72727268686868686860607e68687e727272727272727272727272727272727248614b724a61497272727272727272727272727268686f6f69586f6f687e627762627e7272686868636368686868686168684b7b727272727272727d7d6466666677776666666464706a6a776a6a497e7e7e727272727272727272
72606a6072625b72686868686868605a7e68687e7e72727272727272727272727272727272614b72727261616149727272727272727272727272686868696968686860606060607e7248687b7b635b7b7b68684b7272727251727272727272727d7d7d66666677776666667d7d7e4a6a6a596a6a497e7e727272727272727272
72606a607262607068686868686860607e686860497e72727272727f7f7f7f7272727272486172726b6b6b72616172727272727272727272727268686868686868687e6262775b7e7268687b7b63637b7b6868727248686868497272727272727d53646666665b666666667d6f497e4a6a6a5b6a6a497e727272727272727272
72606a60726060726868686868607e7e7e68686060497e7e72726d6f6f6f6f7f7272727261616b6b6b4b7248614b7261727272727272727272517d707d7d7d7d707d7e4a6262627e7268686868686868686868706868686859686868497272727d7d7d4a6666666666664b7d6f6f497e4a6a6a776a6a7e7e7272727272727272
72606055726060726868686868686868686868606060497e72726d6f6f6f6f7f727272724a616172727248614b72616172727272727272727d6262606060576060627d7e4a62627e7b685768684b7270727272726868686868686868687b72727272727d647d7d7d7d647d7d6f6f6f497e6a6a6a6a6a527e7272727272727272
726272766260606072727271726872717272727e4a60607e7e726d6f6f6f6f7f72727272724a61616161614b7272617272727272727272727d626060605b60606062527e7e707e7e7b687b686872486149724868684b7e7e7e7e4a6868497b7272647d7d707d7d7d7d707d7d686f6f6969606a6a6a4b7e7e7272727272727272
726272626262606072776868686868686868777e7e6a6a6a516d6f6f6f6f6f7f7272727272724a6161514b727261727272727272727272727860606f6f6f777777627d536060607d7b635b6368726158617068684b7e486868497e4a68687b72727d66666666665b7d647d7d6868696969697e6a4b7e7e727272727272727272
726272627760776072686d6d6d6d6d6d6d68687e6f6d6d68686d6f6f6f6f7f60727272727272724a616172726161727272727272727272727d60606f6f6f777777627d62626060787b63636368726161617268687e4868685b68497e6868497b727d6666666666667d647d4868686869696f497e7e7e72727272727272727272
725370606060606071686d68684c68686d6868716f6d6d6d6d6d6f6f6f6f6f7f7272727272727272616161496161727272727272727272727860566f6f6f6f6f5b607d7d7d62627d7b687b6868724a614b7268686868687e7e6868686868687b727d647d66667d647164646868684b7b4a6f6f49726472727272727272727272
726272606a576a6072686d686f6f6f686d68527e6f6f6d6d6d686d6f6f6f6f7f7272727272727272724a61614961727272727272727272727d6277776f6f6f6f60607d606262627d7b6868684b7272707248685768686d5c5e6d6868575a687b727d6666666666667d647d4a6868497b486f6f6f726472727272727272727272
727272606060606071686d68685968686d6868716f6f6f6d6d58686d6f6f6f7f7272727272727272727272727261616172727272727272727d62777760596060606070606062627872686868725b6868725b68686868687e7e6868686868687b7d536666586666667064527d6868686868686f6f727272727272727272727272
727272627760776072686d6d6d6d6d6d6d68687e6f6d6d6d6d6d686d6f6f6f7f7272727272727272727272727272727272727272727272727d6262626060606060627d606262627d7272617248686868724a68687e4a686868684b7e6868687b727d6666666666667d647d486856686868686868727272727272727272727272
727272626250626072776868686868686868777e6868686a68686d6f6f6f6f7f7272727272727272727272727272727272727272727272727d7d7d7d7d7d7d7d7d7d7d7d7d787d7d726868686868686849726868497e4a68684b7e4868684b7b727d647d66667d64716464686868687b7b7b6368497272727272727272727272
727272727272727272727272727272727072727272727e707e72726d6d6f6f7f72727272727272727272727272727272727272727272727272727272727272727272727272727272727b68686d586d686870686868497e7e7e7e4868684b7b72727d6666666666667d647d4a68686363527b636858615c727272727272727272
72727272727272727272727272727272624972724d77606060775b726d6f6f7f72727272727272727272727272727272727272726a6a6a6a6a6a6a6a6a6a6a6a6a7d727272727272725368686f6f6f6d6872686868686858686868684b7b7272727d66666666665b7d647d7d68687b7b7b7b63684b7272727272727272727272
727272727272727272727272727272724a6249726277606a607762726d6f6f7f72727272727272727272727272727272727272726a7d717d7d7d6a7d717d717d6a7d727272727272727b636363636368687b7b4a686868686868684b7b727272727d7d7d64647d7d7d647d486868497b7b486868727272727272727272727272
72727272727272727272727272727272724a62706262606a606262726d6f6f7f72727272727272727272727272727272727272726a7d606060706070626262706a7d727272727272727b637b7b7b7b7b7b72687b4a68686868684b7b7b7b7b727d5364666666666664647d686868685b6868684b727272727272727272727272
727272727272727272727272727272727272727262626057606252727f7f7f7f72727272727272727272727272727272727272726a7d6060607d6a7d7d627d7d6a497d7d72727272727b687b48686868497b72687b7b7b507b7b7b486868687b7d7d7d66666666577d7d486868684b7272727272727272727272727272727272
727272727272727272727272727272727272727272727270727272727272727272727272727272727272727272727272727272486a7d707d717d6a497d567d486a6a6a497d7d7d7d727b68685b5868684e7b72727272727b68724c685b58685d7d4c64666666666664646868684b727272727272727272727272727272727272
72686868687d6868687d666666666672727272727272725c727272727272727272727272727272727272727272727272726a536a6a6a6a6a6a6a6a6a497d486a6a6a6a6a6a6a6a7d72727b7b4a6868684b7b72727272727272687b4a6868687b7d7d7d66666666667d7d4a684b72727272727272727272727272727272727272
72686868687d68684b7d6666666666727272727272727272727272727272727272727272727272727272727272727272726a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a7d7d7d6a7d727272727b7b7b7b72727272727272727272727b7b7b7b727d7d7d7d7d7d7d7d7d7d7d727272727272727272727272727272727272727272
72687272687d68687d7d6666666666727272727272727272c0c1c2c3c0c1c2c372727272727272727272727272727272726a6a4b7d7d707d717d6a7d717d4a6a6d6d6a7d7d7d6a7d7b7b7b7373737e7e7e7e7e7e7272727e7e7e775d777e7e727272727e7e7e7e7e7e7272727373737373737373737f7f7f7272727272727272
7268686868646857497d666666666672727272727272727dd0d1d2d3d0d1d2d372685455687768777268686868686872726a6a7d60606060607d6a7d60607d6a6d6d6a7d7d7d6a727b4868684b7e486060497e7e6e7f6e7e4860605960497e6e7f6e7e4860516060497e6e7f6e6e6a516a6a6a6e6e7f7f7f7272727272727272
72685b555364686868706666587752727272727272727272e0e1e2e3e0e1e2e3726868687d77687772686d6d68427772726a6a716060606060716a706060706a6d6d6a7d7d7d6a727b684f687e4860777760497e6e7f6e7e606077775b60716e7f6e71606060606060716e7f6e6a6a6a6a6a6a6a6e7f7f7f7272727272727272
72686868686468684b7d6666667766727272727272727272f0f1f2f3f0f1f2f3726853684042687772686d6d68686872726a6a7d60606060607d6a7d60607d6a6d6d6a7d7d7d6a727b6853687060575c776060716e7f774c60606a6a605a7e6e7f6e7e5777774d77607e6e7f6e6a6a6a6a556a6a6e7f7f7f7272727272727272
72685768687d68687d7d6666666666727272727272727272c0c1c2c3c0c1c2c372707272727777777268536868466872726a6a7d60606060607d6a497d717d6a6d6d6a7d7d7d6a72724a68687e6060777760527e6e7f6e7e60606a6a60607e6e7f6e7e60775e77775b7e6e7f6e6a6a6a6a586a6a6e7f7f7f7272727272727272
72686868687d6868497d666666666672727272727272727dd0d1d2d3d0d1d2d372686868476868727268686872727272726a6a497d7d707d7d486a6a6a6a6a6a6a6a6a6a6a6a6a72727268687e4a606060604b7e6e7f6e71606077775b60716e7f6e71606060606060716e7f6e774e776a6a6a6a6e7f7f7f7272727272727272
727272727272727272727272727272727272727272727272e0e1e2e3e0e1e2e372686868686868727268686843685972724a6a6a6a6a6a6a6a6a6a6a4b7d507d4a6a6a6a6a4b727272724a68497e4a60604b7e7e6e7f6e7e4a606052604b7e6e7f6e7e4a605060604b7e6e7f6e6e77776a6a6a6e6e7f7f7f7272727272727272
727272727272727272727272727272727272737373727272f0f1f2f3f0f1f2f3727272727272727272727272727272727272727272727272727272727272727272727272727272727272727272727e7e7e7e7e7e7272727e7e7e7e7e7e7e7e727272727e7e7e7e7e7e72727273737373775f7773737f7f7f7272727272727272
__sfx__
011000001155411557115571155527503085000a5000c500115001450016500165001650017500175001750016500000000000000000000000000000000000000000000000000000000000000000000000000000
000400000e5541255312300095000a5030a50311603136020b0050000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900000e6140f612003120031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000062403020010200002002600026000260001600016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000333103333215010233100331003210032100323003010030100301003010050100501005010050100501000010000100001000010000100000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000305403070030700000000000000000805408070080700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000065400050056540005400004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000631706327063270633706357063520635206352063520635206340063300632006310063100631000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000631206312063120632206332063420635206352063520635206352063520635206352063520635300000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000032400652006520064200632006220060000600006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
