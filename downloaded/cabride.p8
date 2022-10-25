pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- cab ride
-- by ben jones/@powersaurus
-- music by stephen 'rych-t' jones/@rych-t
--
-- project based on code from 
-- tom mulgrew's/@mot tutorial
-- https://www.lexaloffle.com/bbs/?tid=35767
-- used under cc4-by-nc-sa
-- see https://creativecommons.org/licenses/by-nc-sa/4.0/
-- for more

local building_c,building_c2,
 building_h,
 offset=
 {5,6,2}, --{4,15,5,12}
 {4,15,5,12},
 {
  21.5,16.1,10.7,
  12.5,19.7,12.5,16.1,
  10.7
 },
 {
  0.1,1.5,0.25,0.4,
  0.2,0.8,0.25,0.7,
  2,0.6,1.1,0.8,3,0.3,
  0.25,2.5,1.75
 }

s_sfx,s_music,nil_func=
 sfx,music,function()end

function _init()
 o_rnd_vals,
 o_rnd_ptr=
  {},1

 s_o_rnd()
 
 show_title,
 sound_on,
 only_slightly_chill,
 infinite,
 auto,
 seed=
  true,true,true,true,false,
  frnd(300)--snake eats itself
 
 music(0,1000)
 init_palette_2()
 init_everything()
 
-- _update=update_foo
-- _draw=d_building
 menuitem(1,"toggle sound",function()
  -- yuck
  sound_on=not sound_on
  music(-1)
  music,sfx=nil_func,nil_func
  if sound_on then
   music,sfx=s_music,s_sfx
  end
 end)
end


--126 tokens

 scale=5
 px,py=64,96
 widthb,height=2.3*2,12
 cs={5,6,2}
 colour=13
 
function update_foo()
 time_of_day=2
 srand(time())
 if btnp(❎) then
  scale=2+rnd(6)
  widthb,height=
  --2.3 works nicely for one window
   2.3*(3+frnd(4)),--1.95*(6+frnd(2)),
   3.5+1.8*(3+frnd(6))
--  px,py=64-width/2,64+height/2
  px,py=32,96+height/2
  colour=13--building_c[1+frnd(3)]
 end
end

function d_building()
 cur_clip={0,0,128,128}

-- colour=12
 sprites={}
 
 cls(1)
 building(
  px,py,
  widthb,scale,
  colour,
  height,
  cur_clip,sprites,true)
 
 passenger(
   1,
   px-10,py,0,scale,
   cur_clip,false,sprites)
   
 foreach(sprites,function(s) 
 s()
 end)
end
--]]
function building(
 px,py,
 width,scale,
 colour,
 height,
 cur_clip,sprites,w)
 local s4=scale/8
 
 add(sprites,function()
  set_clip(cur_clip)
  set_palette(time_of_day,5)
  rectfill(
   px,
   py-height*scale,
   px+width*scale,
   py,colour)

  if w then
   local hscale=scale
   if(width<0)hscale=-scale
  
   local wx=px+.8*hscale

   for y=0,flr(height/1.8)-2 do
    for x=0,flr(abs(width)/2.4) do
     if x==0 or x%3~=0 then
     local w_c,win_width=5,.7
     for i=0,0.3,0.3 do
      rectfill(
       wx+(x*2.3)*hscale,
       py-(i+y*2+3)*scale,
       wx+(x*2.3+win_width)*hscale,
       py-(i+y*2+2.2)*scale,
       w_c)
      if time_of_day>=2 then
       w_c=4+((height+y%x)%3)*5
      else
       w_c=12
      end
     end
     end
    end
   end--]]
  end
 end)
end


function init_everything()

 srand(seed)

 -- camz never more than 1
 -- corrupts state if so
 -- update_camera moves along
 -- track when camz>1
 -- use camslice to move within a seg

 camcnr,camslice,
 camx,camy,camz,
 world_ang,
 vel,
 throttle,
 throttle_vis_timer,
 stops_in_seg,
 doors_open,
 passengers,
 boarding,
 disembarking,
 passenger_x,
 last_stop,
 journey_over,
 journey_over_timer,
 auto_timer,
 stops,
 total_score,
 accelerate_tutorial,
 brake_tutorial,
 doors_tutorial,
 journeys_completed,
 signals_obeyed,
 total_signals,
 timer,time_in_seg,
 hours,minutes,seconds,
 ot_seg,ot_end_seg,
 ot_slice,ot_end_slice,ot_z,ot_vel,
 current_note,
 note_len,
 area,
 skx,
 active_palette,last_i,
 build_tracks,
 goal_msg,status_msg=
  1,9,
  0,0,0.3,0,0.0,0,0,0,
  false,{},{},{},
  0,--passenger_x
  false,false,0,0,0,0,0,0,0,0,0,0,0,0,
  o_rnd(24),0,0,--time
  -1,-1,-1,-1,0,0.04,
  -1,0,
  frnd(2),
  0,
  nil,nil,--sky
  frnd(2)+1,--build_tracks
  new_message(64,64,true),
  new_message(19,115,false)

 build_area=area
 
 set_weather()
 
 --hours=12
 set_time_of_day()
 
 init_palette()
 poke(0x5f2e,1)

 track,stations=generate_track()

 generate_terrain(40)
 generate_city(40)

 curseg=track[camcnr]
 
 status_msg.cy=-16
 
 status_msg.set_message_with_cat=function(s,m,t,f)
  
  local not_already_there=true
  foreach(s.msgs,function(i)
   if(i.m==m)not_already_there=false
  end)
  if f
  or not_already_there then
   s:set_message(m,t,f)
   sfx(63,0)
   s.cy=s.y+12
  end
 end
 
 status_msg.draw_with_cat=function(s)
  s:draw()
  if #s.msgs>0 then
   spr(174,s.x-19,s.cy,2,2)
  end
 end
 
 status_msg.update_with_cat=function(s)
  s:update()
  if #s.msgs==0 then
   s.cy+=4
  elseif s.cy>s.y-2 then
   s.cy-=4
  end
 end
 
end

function advance(cnr,slice)
 slice+=1
 if slice>track[cnr].len then
  slice=1
  cnr+=1
  -- this will break
  -- if you go past the 
  -- end of the line, should
  -- never happen 
 end
 return cnr,slice
end

function _update()
 tick(8)

 update_controls()
 
 update_camera()
 
 status_msg:update_with_cat()
 goal_msg:update()
 
 update_train()
 update_music()
end

function tunnel_rect(px,py,scale,tracks)
 local w,h=6*scale,4*scale
 local x1,y1=
  ceil(px-w/2),
  ceil(py-h)
 if(tracks==2)w+=4*scale
 local x2,y2=
  ceil(px+w/2),
  ceil(py-1)
 return x1,y1,x2,y2
end

function clip_to_tunnel(px,py,scale,tracks,clp)
 local x1,y1,x2,y2=tunnel_rect(px,py,scale,tracks)
 clp[1],clp[2],clp[3]=
  max(clp[1],x1),
  max(clp[2],y1),
  min(clp[3],x2)
 -- don't think i need this with no slopes
-- clp[4]=min(clp[4],y2)
 return {clp[1],clp[2],clp[3],clp[4]}
end

--[[
 1=x start
 2=y start
 3=x end
 4=y end
]]
function set_clip(clp)
 clip(
  clp[1],
  clp[2],
  clp[3]-clp[1],
  clp[4]-clp[2])
end

--[[t_rectfill=rectfill
rectfill=function(a,b,c,d,e)

 t_rectfill(a,b,c,d,e)
  flip()
end

t_line=line
line=function(a,b,c,d,e)
 t_line(a,b,c,d,e)
 flip()
end

t_sspr=sspr
sspr=function(sx,sy,sw,sh,dx,dy,dw,dh,flx,fly)
 t_sspr(sx,sy,sw,sh,dx,dy,dw,dh,flx,fly)
 flip()
end--]]

function _draw()

 clip()


 set_palette(time_of_day,7)
 
 --sky
 background()

 local camang=camz*curseg.tu
 local x,y,z=-(camx+camz*-camang),-camy+2,-camz+2
 local cnr,slice=camcnr,camslice
 local ppx,ppy,pscale=project(x,y,z)
 local prev_typ,typ,prev_underground,
  prev_pcnt_in_seg,
  cliprect,col,last_ground,
  sprites,
  cur_tnl_clip,ot_start,ot_end=
  -1,-1,false,(slice-1)/track[cnr].len,
  {0,0,128,128},
  {2,12},
  128,
  {},
  nil,
  ot_seg+ot_slice/100,
  ot_end_seg+ot_end_slice/100

 for i=1,30 do
  local r=track[cnr]
  local tx,ty,
  c,tracks,pcnt_in_seg,typ,
  pal_index
  =
   r.tx or 0,
   r.ty or 0,
   col[(slice*1)%2+1],
   r.tracks,
   slice/r.len,
   r.typ,
   time_of_day
  
  x-=camang
  z+=1
  
  local px,py,scale=project(x,y,z)
 
  local width,r_width,pwidth,pr_width,s4=
   3*scale,3*scale,3*pscale,3*pscale,scale/4
  if tracks==2 then
   r_width,pr_width=
    5*scale,5*pscale
  end
  
  if typ~=prev_typ then
   if typ==3 then
    local face_colour=nil
    if(prev_underground)face_colour=1
    draw_tunnel_face(ppx,ppy,r.start_h,pscale,face_colour,r.tracks)
    cur_tnl_clip=clip_to_tunnel(ppx,ppy,pscale,tracks,cliprect)
    set_clip(cliprect)
   end
   if typ==8 then
    last_ground=ppy
   end
  end

  if typ==3 then
   pal_index=99
  end
  set_palette(pal_index,i)
  draw_ground(py,ppy,px,slice,r,scale)
   
  if (r.station and r.underground)
  or typ==3 then--tunnel
   draw_tunnel(px,py,ppx,ppy,scale,pscale,i,slice,typ,tracks)
  end

  -- track
  if (typ<98 and typ~=8)
  or (typ==98 and slice<3) then    
   --7858 to beat
   draw_track(px,py,
    width,
    ppx,ppy,pwidth,
    scale,pscale,
    tx,ty,tracks,
    pcnt_in_seg,prev_pcnt_in_seg,
    r.points)
  end

  local cur_clip={
    cliprect[1],
    cliprect[2],
    cliprect[3],
    cliprect[4]
   }
  -- scenery
  if typ==0 or typ==5 then
   trackside(
    r,slice,
    px,py,
    c,width,r_width,
    scale,
    cur_clip,sprites)
  elseif r.station then   

   --7095 to beat	, 7082 now,6984 now
   station_stuff(
    px,py,ppx,ppy,width,r_width,
    scale,pscale,
    typ==1,r,slice,
    c,
    cur_clip,sprites
   )
  elseif typ==4 then--level crossing
   local sgn_width,sgn_pwidth=
    width*1.2,pwidth*1.2
   if slice==r.len-1 then
    thing(32,64,
     px,py,sgn_width,scale,
     cur_clip,sprites,true)
    
    --r
    thing(32,64,
     px,py,r_width*-0.47*tracks,scale,
     cur_clip,sprites,true)
   end
   if slice==1 then
    thing(32,64,
     ppx,ppy,sgn_pwidth,pscale,
     cur_clip,sprites,true)
    --r
    thing(32,64,
     ppx,ppy,pr_width*-0.47*tracks,pscale,
     cur_clip,sprites,true)--]]
   end
  elseif typ==8 then--bridge
   -- dup, this probably needs
   -- to live somewhere at the top of the loop
   local px2,
    ppx2,
    py2,
    ppy2,
    pscale2,
    pwidth2,
    scale2,
    tx2,
    ty2,
    t_slice,
    len,
    start_h,
    cur_last_ground,
    density=
     px,
     ppx,
     py,
     ppy,
     pscale,
     pwidth,
     scale,
     tx,
     ty,
     slice,
     r.len,
     r.base_h,
     last_ground+1,
     r.density

   trackside(
    r,slice,
    px,py+10*scale,
    c,width+scale,r_width+scale,
    scale,
    cur_clip,sprites)
    
   add(sprites,function()
    cur_clip[4]=cur_last_ground
    set_clip(cur_clip)
    set_palette(time_of_day,i)
    -- todo - either arched or flat
    local height=(start_h-abs(t_slice-len/2))/2
    if t_slice%density==0 then
    local bys=py2-pscale2*height
    for z=-1,1,2 do
     local drs=pscale2*z
     local bxs,zps2=
      px2+drs*2,z*pscale2
     if z==1 and tracks==2 then
      bxs+=pscale2*2.5
     end
     local bxe=bxs+zps2*0.75
   
      -- uprights
      rectfill(
       bxs,bys,
       bxs+zps2*0.5,
       py2+pscale2*4,
       2+t_slice%2*3)
      rectfill(
       bxe,bys,
       bxe+zps2*0.5,py2+pscale2*4)
       -- horizontals
      rectfill(
       bxs,bys,
       bxe,py2-pscale2*(height-.3))
     end
    end
    draw_track(px2,py2,
     width,
     ppx2,ppy2,
     pwidth2,
     scale2,pscale2,
     tx2,ty2,tracks)
   end)
  elseif typ==9 then
   building_with_wall(px,py,width,scale,r,1,slice,cur_clip,sprites)
   building_with_wall(px,py,r_width,scale,r,-1,slice,cur_clip,sprites)
  elseif typ==10 then
   local x1,y1,x2,y2=
    tunnel_rect(px,py,scale,tracks)
   local c_slice=slice
   add(sprites,function()
    y1-=scale/2
    local cl,w=1,scale
    rectfill(x1-w,y1-w,x2+w,y1,cl)
    if c_slice%3==0 then
     cl=15
     w*=2
     rectfill(x1-w,y1,x1,y2)
     rectfill(x2,y1,x2+w,y2)
    end
   end)
  elseif typ==98 then
   if slice==1 then
    buffers(
     ppx,ppy,width,scale,
     cur_clip,sprites)
    if r.tracks>1 then
     buffers(
      ppx+3.8*scale,ppy,width,scale,
      cur_clip,sprites)
    end
   elseif slice==4
   or slice==3 then
    -- draw some passengers
    for z=0,30 do
     local dr=1-(4-slice)*2
     local pax=
      24*dr+((z*3.5+timer/z/1.5)%50)*-dr
     passenger(
      (z+slice)%8,
      px,py-o_rnd(2),
      0-pax*scale,scale,
      cur_clip,true,sprites)
    end
   elseif slice==5 then
    add(sprites,function()
     set_clip(cur_clip)
     set_palette(min(time_of_day,2),5)
     rectfill(0,py-6.6*scale,127,py,14)
     
     for z=-8,8 do
      local zx=z*3*scale+px
      rectfill(
       zx,py-5.6*scale,
       zx+2*scale,py,15)
     end
    end)
    
   end
  end
  
  --train
  local draw_idx=cnr+slice/100
  if draw_idx>=ot_start
  and draw_idx<=ot_end
  then
   local ot_x,ot_y,ot_scale=
    project(x,y,z+ot_z)

   local t_slice,ot_s4,
    x1,x2,front_of_train=slice,
    ot_scale/4,
    32,12,
    draw_idx==ot_start

   add(sprites,function()
    set_clip(cur_clip)

    if not front_of_train then
     x1,x2=56,6
    end
    sspr(x1,96,x2*2,32,
     ot_x+2.3*ot_scale,
     ot_y-14*ot_s4,
     x2*ot_s4,16*ot_s4)
    if front_of_train
    and (time_of_day>=2 or raining) then
     local lx,ly=
      ot_x+2.9*ot_scale,
      ot_y-5*ot_s4
     light(lx,ly,7)
     light(lx+1.7*ot_scale,ly,7)
    end
   end)
  end
  
  if (typ~=3 and typ<98)
  and slice%4==0 
  and not r.underground then
   mast(
     px,py,
     width*1.15,scale,s4,
     cur_clip,r.flip_mast 
     and tracks<2 and not r.points,sprites)
   
   if tracks>1 or r.points then
    mast(
     px,py,
     width*3,scale,s4,
     cur_clip,true,sprites)  

   end--]]
   
  end
  
  if typ<98 then
  
   for i=0,tracks-1 do
    cable(
     px+i*2.7*scale,py,
     ppx+i*2.7*pscale,ppy,
     scale,pscale,
     cur_clip,sprites)
   end
  end
  
  if r.has_signal then
   local last=r.len-1
   if slice==last then
    signal(
     px,py,width,scale,r,
     cur_clip,sprites)
   end
  end
  
  --rain
  if typ~=3 
  and i<15 
  and raining then
   local rain_y=timer+slice*4
   for z=0,4 do
    local x1,y1=
     32*z+slice%8*6,
     (z*4+rain_y)*6%128

    add(sprites,function()
     rectfill(
      x1,min(y1-s4,py),
      x1,min(y1,py),
      12)
    end)
   end
  end--]]--endrain
  
  if typ==3 then
   cur_tnl_clip=clip_to_tunnel(px,py,scale,tracks,cliprect)
  elseif r.underground then
   -- yuck yuck yuck yuck
   
   -- you gotta fix those walls!
   
   local x1,y1,x2,y2=tunnel_rect(px,py,scale,tracks)
   cur_tnl_clip={
    max(cliprect[1],x1),
    max(cliprect[2],y1),
    min(cliprect[3],x2),
    128
   }
   if r.typ==1 then
    cliprect[1],cliprect[2]=
     cur_tnl_clip[1],
     cur_tnl_clip[2]
   elseif r.typ==2 then
    cliprect[2],cliprect[3]=
     cur_tnl_clip[2],
     cur_tnl_clip[3]
   end
  else
   cliprect[4]=min(cliprect[4],ceil(py))
  end
  
  set_clip(cliprect)
     
  -- turn
  camang-=track[cnr].tu  
  
  -- move along the track
  cnr,slice=advance(cnr,slice)
  
  -- save last pos
  ppx,ppy,pscale,prev_typ,prev_underground,
  prev_pcnt_in_seg=
   px,py,scale,typ,r.underground,
   pcnt_in_seg
  
  if (prev_pcnt_in_seg>0.99)prev_pcnt_in_seg=0
 end
 
 -- todo bring back if weirdness happens
 --init_palette()
 
 clip()
 
 for i=#sprites,1,-1 do
  sprites[i]()
 end
 clip()
 
 pal()
 init_palette()
 
 if(stopped_at_station and doors_open)draw_passengers(curseg)
 
 status_msg:draw_with_cat()

 if show_title then
  title()
 else

	  
	  -- gamey bits
	  if only_slightly_chill then  
	   goal_msg:draw()
	   spr(255,86,1)
	   draw_clock(96,2)
	   --252
	   local to_next,spr_id=to_next_landmark()
	   nice_print(""..to_next,10,2,7,1)
	   spr(spr_id,1,1)
	   
    if throttle_vis_timer>0 then
     spr(218,110,103,2,3)
     spr(202,110,107+throttle*2,2,1)
    end
	   
	   if journey_over then
  	  nice_print("   you finished line no."..
  	   seed.."!\n\noverall station stop rating "..
  	   score_to_string(total_score/stops)..
  	   "\n\n       stations visited "..
  	   stops.."\n\n          signals "..
  	   (signals_obeyed/max(total_signals,1)*100).."%\n\n     passenger journeys "..journeys_completed+#disembarking,
  	   4,44,7,1)
	   end--journey_over
	  end
	  if journey_over then
	   nice_print("press ❎ to start a new journey",
  	  2,104,7,1)
  	end
	 end 
	
	--nice_print(stat(1),0,10,7,1)
	 --print("cpu: "..time_in_slice,0,0,7)
	
end
	
function title()
	-- palt(11,true)
	 if show_credits then
	  nice_print(--looooong line
	   "            credits\n\n\n    programming and art by\n\n    ben jones/@powersaurus\n\n\n            music by\n\n stephen 'rych-t' jones/@rych_t\n\n\n  code based on original work\n      by tom mulgrew/@mot\n\n      for more details see\n\n  https://powersaurus.itch.io",2,6,7,1)
  return
 end
 if(not show_route)sspr(96,96,32,24,2,2,128,96)
 
 local c_msg="very chilled mode"
 if(only_slightly_chill)c_msg="chilled mode     "
 
 nice_print("⬅️ ride on line no."..seed.." ➡️",17,100,7,15)
 nice_print("❎ to depart, 🅾️ to view",17,110,7,15)
 nice_print("⬆️ "..c_msg.." ⬇️ credits",2,120,7,15)
end

function percent_in_seg(camz,camslice,seg)
 return (camz+camslice-1)/
  seg.len
end

function signal(
 px,py,width,scale,r,
 cur_clip,sprites)
    
 local s4,light_col,light_pos=
  scale/8,8,0

 if r.signal_wait<=0
 and not in_last_seg then
  light_pos,light_col=
   -.4*scale,11
 end
 local lx,ly=
  px-width+scale*0.9,
  light_pos+py-10*s4
  
 add(sprites,function()
  set_clip(cur_clip)



  sspr(16,64,8,16,
   px-width+scale*0.5,py-16*s4,
   8*s4,16*s4)

  light(lx,ly,light_col)
 end)
end

function light(lx,ly,light_col)
 pal(0,light_col)
 fillp(0xa5a5.8)
 circfill(lx,ly,7,0)
 fillp(0)
 circfill(lx,ly,4,0)
 pal(0,0)
end
--6327
function thing(sx,sy,
 px,py,width,scale,
 cur_clip,sprites,unlit)
    
 add(sprites,function()
  set_clip(cur_clip)
  if(unlit)set_palette(1,5)
  local s4=scale/8
  
  sspr(sx,sy,8,16,
   px-width+scale*0.5,py-16*s4,
   8*s4,16*s4)
 end)
end

function passenger(
 s,px,py,
 width,scale,
 cur_clip,flip_h,sprites)
 
 if(flip_h)width*=-0.4
 
 thing(s*8,80,px,py,
  width,scale,
  cur_clip,sprites,true)
end

function buffers(
 px,py,width,scale,
 cur_clip,sprites)
    
 local s4=scale/7.5
 add(sprites,function()
  set_clip(cur_clip)
  sspr(96,64,24,16,
   px-12*s4,py-16*s4,
   24*s4,16*s4)
 end)
end

function cable(
 px,py,ppx,ppy,
 scale,pscale,
 cur_clip,sprites)
 
 add(sprites,function()
  set_clip(cur_clip)
  
  draw_trapezium(
   px-scale*.25,py,0,
   ppx-pscale*.25,ppy,0,
   5,true)
 end)
end

function mast(
 px,py,
 width,scale,s4,
 cur_clip,fliph,sprites)

 -- i am sorry
 local h_offx,flip_off=
  width-scale*0.5,0

 if fliph then
  h_offx*=-0.55
  flip_off=scale*2
 end
 add(sprites,function()
  set_clip(cur_clip)
  
  local x1,y1=
   px-h_offx,py-20*s4
  -- top
  sspr(64,64,24,8,
   x1-flip_off,y1,
   12*s4,scale,fliph)
  rectfill(
   x1+s4*1.5,y1,
   x1+s4*2.3,py,5)
  rectfill(
   x1+s4*1.5,y1,
   x1+s4*1.8,py,15)
 end)
end

function tree(
 px,py,s4,off,
 dr,slice,tree_tex,
 cur_clip,sprites)
 add(sprites,function()
  set_clip(cur_clip)
  set_palette(time_of_day,5)
  sspr(80+16*tree_tex,32,16,32,
   px+dr*offset[1+(slice+off)%#offset]*s4*20,py-31*s4,
   dr*16*s4,32*s4)
  end)
end

function building_with_wall(
 px,py,width,scale,r,
 dr,slice,cur_clip,sprites)
 
 --wall
 
 -- fix maybe? the numbers make
 -- no sense any more
 local wall_w,wall_h,wall_s,wall_c=
  dr*2,5,dr*width*2,r.col[slice%2+1]
 if slice==1 then
  wall_w,wall_h,wall_s,wall_c=
   -dr*25,3,
   dr*width*1.6,
   12
 end
 
 building(px-wall_s,py,
  wall_w,scale,
  wall_c,
  wall_h,
  cur_clip,sprites)--]]
 
 if slice%3==0 then
  -- dup?
   local off=flr(slice/3)
   building(px-dr*width*6,py,
    dr*11.5,scale,
    building_c[1+off%#building_c],
    building_h[1+(dr-off)%#building_h],
    cur_clip,sprites,true)
 end
end

--make cutting only one function plz

function cutting(
 px,py,width,height,
 scale,c,dr,slice,r,
 cur_clip,sprites)
 local s4,d_width=
  scale/4,
  dr*width
 if area==0 then
  add(sprites,function()
   set_clip(cur_clip)
   set_palette(time_of_day,5)
   sspr(32,32,32,32,
    px+d_width*1.3,
    py-(height+1.5)*scale,
    dr*32*s4,
    32*s4*0.5)
   end)
  tree(
   px+d_width+dr*2*scale,
   py-height*scale,
   s4,0,dr,slice,r.tree_tex,
   cur_clip,sprites)
 else
  if slice%3==0 then
   -- dup
   local off=flr(slice/3)
   building(
    px+dr*width*5,py,
    dr*11.5,scale,
    building_c2[1+off%#building_c2],
    building_h[1+off%#building_h],
    cur_clip,sprites,true)
  end
 end
 
 building(px+d_width*1.35,py,
  dr*25,scale,
  c,
  height,
  cur_clip,sprites)
end

function trackside(
 r,slice,
 px,py,c,l_width,r_width,scale,cur_clip,sprites)

   local r_typ,l_typ,pcnt_in_seg,s4=
    r.r_typ,r.l_typ,
    slice/r.len,
    scale/4
   
   if(r.typ==1)r_width*=2.1
   if(r.typ==2)l_width*=2.1
   
   if r_typ==0 then
    tree(px+r_width*r.r_dist,py,
     s4,0,1,slice,r.tree_tex,
     cur_clip,sprites)
   elseif r_typ==5 then
   
    -- dup duuuup
    cutting(
     px,py,
     r_width+lerp(r.start_w_r,r.end_w_r,pcnt_in_seg),
     lerp(r.start_h,r.end_h,pcnt_in_seg),
     scale,c,1,slice,r,
     cur_clip,sprites)
   elseif r_typ==9 then
    building_with_wall(
     px,py,r_width,scale,r,
     -1,slice,cur_clip,sprites)
   end
   
   if l_typ==0 then
    tree(px-l_width*2*r.l_dist,py,
     s4,3,-1,slice,r.tree_tex,
     cur_clip,sprites)
   elseif l_typ==5 then   

    -- dup duuuup
    cutting(
     px,py,
     l_width+lerp(r.start_w_l,r.end_w_l,pcnt_in_seg),
     lerp(r.start_h,r.end_h,pcnt_in_seg),
     scale,c,-1,slice,r,
     cur_clip,sprites)
   elseif l_typ==9 then
    building_with_wall(
     px,py,l_width,scale,r,
     1,slice,cur_clip,sprites)
   end
end
   
-->8
-- drawing

function station_stuff(
 px,py,ppx,ppy,width,r_width,
 scale,pscale,lhs,r,slice,
 c,cur_clip,sprites
 )
 local s4=scale/4
 if not r.underground then
  trackside(
   r,slice,
   px,py,
   c,width,r_width*1.2,--todo fiiiix betterrrrrr
   scale,
   cur_clip,sprites)
 end

 local dr=-1
 if(lhs)dr=1
 add(sprites,function()
  set_clip(cur_clip)
  set_palette(time_of_day,-1)

  local stx,stx2=
   px+dr*scale*2.2,
   ppx+dr*pscale*2.2 
  
  rectfill(
   stx+dr*scale,py-scale*5,
   ppx+dr*pscale*3.7,ppy,5+9*(slice%2))
 -- draw_clip(cur_clip)
  local s_tex=32
  if(slice==9)s_tex=48
  
  draw_trapezium2(
   stx,py,scale,
   stx2,ppy,pscale,
   0,s_tex,16,16)
   
  draw_trapezium2(
   stx2,128-ppy,pscale,
   stx,128-py,scale,
   16,48,16,16,true)
  if slice==1 
  and not r.underground then
   local x1,x2=
    ppx+dr*pscale*2.2,
    px+dr*pscale*6
   --wall
   rectfill(
    x1+dr*scale,
    128-ppy,
    x2,ppy,6)
   rectfill(
    x1+dr*scale,
    128-ppy,
    x2,128-ppy+scale*0.2,5)
    --roof
   rectfill(
    x1-dr*pscale,
    128-ppy-0.55*pscale,
    x2,128-ppy,1)
  end
  
 end)
    
 local last=r.len-1
 if slice==last then
  signal(
   px,py,width,scale,r,
   cur_clip,sprites)
 elseif r.busy[slice] then
  passenger(
   r.busy[slice],
   px,py,width,scale,
   cur_clip,lhs,sprites)
 end
end

function draw_trapezium(
 x1,y1,w1,x2,y2,w2,c,rev)
 local h=y2-y1
 
 local xd,wd,x,y,w=
  (x2-x1)/h,(w2-w1)/h,
  x1,y1,w1

 local yadj=ceil(y)-y
 x+=yadj*xd
 y+=yadj
 w+=yadj*wd
 
 while y<y2 do
  local scy=y
  if(rev)scy=128-y
  rectfill(x-w,scy,x+w,scy,c)
  x+=xd
  y+=1
  w+=wd
 end
end	

function draw_trapezium2(
 x1,y1,w1,x2,y2,w2,
 texx,texy,txw,txh,roof)
 
 local h=y2-y1
 
 local xd,wd,x,y,w=
  (x2-x1)/h,(w2-w1)/h,
  x1,y1,w1

 local yadj=ceil(y)-y
 x+=yadj*xd
 y+=yadj
 w+=yadj*wd

 while y<y2 do
  local pcnt=(y-y1)/h
  local ty=
   txh*pcnt%txh+texy
  sspr(
   texx,ty,txw,1,
   x-w,y,w*2,1)
  
  -- station roof
  if roof then 
   local roof_x,roof_y=
    x+w,y-flr(.6*w)
    
   if(x>64)roof_x=x-w
   line(
    roof_x,y,roof_x,
    roof_y,
    1
   )
  end
  x+=xd
  y+=1
  w+=wd
 end
 
end

function draw_tunnel_face(px,py,
 cutting_h,scale,first_slice_col,tracks)
 local x1,y1,x2,y2=tunnel_rect(px,py,scale,tracks)
 first_slice_col=first_slice_col or 6
 
 local wh=4.5*scale
 local wy=ceil(py-wh)

 rectfill(0,min(wy-2*scale,py-(cutting_h)*scale),128,y1-1,2)
 rectfill(0,wy,128,y1-1,6)

 rectfill(0,y1,x1-1,y2-1,first_slice_col)
 rectfill(x2,y1,127,y2-1)
 
end

function draw_ground(py,ppy,cx,slice,typ,scale)
 local lcol,rcol=
  typ.lcol or typ.col,
  typ.rcol or typ.col

 rectfill(0,ppy,cx,py,lcol[slice%#lcol+1])
 rectfill(cx,ppy,127,py,rcol[slice%#rcol+1])
end

--[[function draw_clip(clp)
 rect(clp[1],clp[2],clp[3]-1,clp[4]-1,8)
end]]

function pad_zero(c)
 if(c<10)return "0"..c
 return c
end

function draw_clock(x,y)
 nice_print(pad_zero(hours)..
  ":"..pad_zero(minutes)..
  ":"..pad_zero(seconds),x,y,7,1)
end

function draw_rails(px,py,ppx,ppy,scale,pscale)
 local lt,plt,rw,prw,hrw,phrw=
  scale*0.7,
  pscale*0.7,
  scale*.05,
  pscale*.05,
  scale*.0125,
  pscale*.0125
  
 --7955
 for i=0,1 do
  local dr=i*2-1
  local x1,x2=
   px+dr*lt,
   ppx+dr*plt
   
  draw_trapezium(
   x1,py,rw,
   x2,ppy,prw,
   6)
  draw_trapezium(
   x1+rw,py,hrw,
   x2+prw,ppy,phrw,
   7) 
 end
end

function draw_track(
 px,py,width,
 ppx,ppy,pwidth,
 scale,pscale,
 tx,ty,tracks,pcnt_in_seg,
 prev_pcnt_in_seg,points)
 
 draw_trapezium2(
  px,py,width,
  ppx,ppy,pwidth,
  tx,ty,64,16)

 local x_off,x_off2,
  draw_g,second_track=
  4,4,true,
  tracks==2 or points
 if points then
  local pp,ppp=
   1-pcnt_in_seg,
   1-prev_pcnt_in_seg
  if points==2 then
   pp,ppp=
    pcnt_in_seg,
    prev_pcnt_in_seg
  end
  
  x_off,x_off2,draw_g=
   lerp(0,4,pp),
   lerp(0,4,ppp),
   not(points and pp<0.2)
  if pp>0.16 and pp<0.9
  then
   ty+=16
  end
 end
 x_off*=scale
 x_off2*=pscale
   
 if second_track
 and draw_g then
  draw_trapezium2(
   px+x_off,py,2.25*scale,
   ppx+x_off2,ppy,
   2.25*pscale,
   tx+16,ty,48,16)--]]
 end
 draw_rails(px,py,
  ppx,ppy,
  scale,pscale
 )
 
 -- second track
 if second_track then
  draw_rails(px+x_off*0.8125,py,
   ppx+x_off2*0.8125,ppy,
   scale,pscale
  )
 end
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

function background()
 if raining and time_of_day<2 then
  sky_c,cloud_c=14,5
 end
 cls(sky_c)

 rectfill(0,58,127,62,6)
 rectfill(0,63,127,68,7)

 sky_cast(world_ang/360)

 local bg=terrain
 if area==1 then
  bg=city
 end
 local sl,o_bg_c,o_h=
  0,bg_c,0
 for i=0,127 do
  local w=(flr(world_ang)+i)%120
  local h=bg[w+1]
  
  line(i,127,i,h,bg_c)-- 0 for night
  if i>0
  and flr(bg[w])<flr(h) then
   sl+=1
  else
   sl=0
  end
  
  if sl>1 then
   line(i,h+
    (68-h)*0.3,
    i-1.5,h,bg_hic)-- 1 for night
  end
  if area==1
  then
   if time_of_day>=2 then
    pset(i,
     h+25*offset[1+w%#offset],
     4+5*(w%2))
   elseif abs(o_h-h)>5 then
    bg_c=5+9*(h%2)
   end
  end
  
  o_h=h
 end
end

function draw_tunnel(px,py,ppx,ppy,scale,pscale,i,slice,typ,tracks)
 local x1,y1,x2,y2=
  tunnel_rect(px,py,scale,tracks)
 local px1,py1,px2,py2=
  tunnel_rect(ppx,ppy,pscale,tracks)
 if i==29 then
  -- dark in the distance
  rectfill(px1,py1,px2-1,py2,0)
 end
 local cl=slice%2
 --ceiling
 rectfill(px1,py1,px2,y1-1,cl)
 --left
 -- the typ~=s are to deal
 -- with regular tunnels having no type
--[[ if(x1>px1 and typ~=2)]]rectfill(px1,y1,x1,py2,cl)
 --right
--[[ if(x2<px2 and typ~=1)]]rectfill(x2,y1,px2,py2,cl)
end
-->8
-- track building

function station(prev)
 local len,busy=10,{}
  --+o_rnd(10)
 for i=1,len-2 do
  if o_rnd(2)==0 then
   busy[i]=o_rnd(8)
  end
 end
 
 if(frnd(8)==0)build_tracks=2
 
 local typ=1+frnd(2)
 if(build_tracks==2)typ=2
 if(tracks==2)typ=2
 
 local new_station={
  len=len,
  tu=(rnd(20)-10)/150,
  typ=typ,
  station=true,
  nm=station_name(),
  col={12,6},
  busy=busy,
  flip_mast=typ==2,
  has_signal=true,
  tracks=build_tracks,
  signal_wait=230+frnd(80)-40
 }
 if(auto)new_station.signal_wait=0
 
 add_trackside_to(new_station,prev)
 set_height_of(new_station,prev)
 
 new_station.underground=
  (not prev or prev.typ==3)
  and build_area==1
  and frnd(2)==0
  
 if not prev then
  new_station.start_h=7+rnd(6)-3
 end
 
 if new_station.underground then
  new_station.r_typ,
  new_station.l_typ=
   -1,-1
 end

 new_station.tree_tex=frnd(3)
 
 return new_station
end

-- 0 plain track
-- 1 station right
-- 2 station left
-- 3 * tunnel
-- 4 * level crossing
-- 5 * cutting
-- 6 left water
-- 7 low cutting
-- 8 * bridge
-- 9 tall buildings
-- 10 underpass
-- 98 end of line wall
-- 99 end of line field
-- 11 buildings

--single_sides={0,5,6,9}
next_up={
 [0]={mn=10,l=27,n={0,0,0,3,4,5,8,9}},
 [1]={l=10,n={0,3,4,5,8,9}},
 [2]={l=10,n={0,3,4,5,8,9}},
 [3]={l=27,n={0,3,3,5,8,9,10,10}},
 [4]={l=3,n={0,8,9}},
 [5]={l=27,n={0,3,5,5,7}},
 [7]={l=27,n={0,3,5,7,7}},
 [8]={mn=8,l=50,n={0,8,8}},
 [9]={mn=10,l=27,n={0,3,4,9}},
 [10]={mn=10,l=27,n={0,3}}
}
biomes={
 [0]={
  nm="country",
  ad={0,3,5},
  rm={9,10},
  single_sides={5,6,7,7},
  min_segs=8
 },
 {
  nm="city",
  ad={9,3,3},
  rm={},
  single_sides={0,5,6,9},
  min_segs=2
 }
}

function pick_typ(n,ad,rm)
 local typs={}

 addall(typs,n)
 addall(typs,ad)
 for _,i in pairs(rm) do
  del(typs,i)
 end
 
 return typs[1+frnd(#typs)]
end

function track_seg(prev)
 local template,biome=
  next_up[prev.typ],
  biomes[build_area]
 local typ=pick_typ(template.n,biome.ad,biome.rm)
 --printh("adding "..typ)

 local len=3+frnd(next_up[typ].l)+(next_up[typ].mn or 0)

 local turn=(frnd(40)-20)/
  (len*32)
 if(len<8)turn=0

 if(prev.underground and frnd(2)==0)typ=3
 local new_seg={
  len=len,
  tu=turn,
  typ=typ,
  tracks=build_tracks,
  col={11,3}
 }--]]

 if frnd(6)<2
 and not prev.has_signal then
  new_seg.has_signal,
  new_seg.signal_wait=
   true,
   frnd(120)
  if(auto)new_seg.signal_wait=0
 end

 -- todo generalize textures
 if typ==0 then
  add_trackside_to(new_seg,prev)
  
  -- switch num tracks?
  if frnd(5)==0 then
   local old_build_tracks=build_tracks
   build_tracks=frnd(2)+1
   if old_build_tracks~=build_tracks then
    new_seg.points,
    new_seg.tracks,
    new_seg.len=
     build_tracks,
     build_tracks,25
   end
  end
 elseif typ==3 then
  if new_seg.len>10
  and frnd(2)==0 then
   build_area=frnd(2)
   new_seg.next_area=build_area
   
  end
 elseif typ==4 then
  new_seg.tx,
  new_seg.col=
   64,
   {13}
 elseif typ==8 then
  new_seg.tx,new_seg.ty,
  new_seg.density,new_seg.col=
   64,16,1+frnd(3),
   {14}
  
  add_trackside_to(new_seg,prev)
 elseif typ==9 then
  -- could this live elsewhere?
  new_seg.col={12,13}
 end
 
 -- deal with cuttings
 set_height_of(new_seg,prev)
 -- finish cuttings
 
 new_seg.flip_mast,
 new_seg.tree_tex=
  frnd(2)==0 and build_tracks==1
  and not new_seg.points,
  frnd(3)

 return new_seg
end

function set_weather()
 sky_x1=o_rnd(21)*4   
 raining=sky_x1>=64 and o_rnd(2)==0
end

function add_trackside_to(new_seg,prev)
  new_seg.l_dist,
  new_seg.r_dist=
   1+frnd(2),
   1+frnd(2)
  
  if prev
  and prev.typ==0
  and frnd(2)==0 then
   new_seg.l_typ,
   new_seg.r_typ=
    prev.l_typ,
    prev.r_typ
  else
   local biome=biomes[build_area]
   local single_sides=biome.single_sides
   new_seg.l_typ,
   new_seg.r_typ=
    pick_typ(single_sides,{},biome.rm),
    pick_typ(single_sides,{},biome.rm)
  end
  
  if new_seg.l_typ==6 then
   new_seg.lcol={14}
  elseif new_seg.r_typ==6 then
   new_seg.rcol={14}
  end
  
  -- could this live elsewhere?
  if new_seg.r_typ==9
  or new_seg.l_typ==9 then
   new_seg.col={12,13}
  end
end

function set_height_of(new_seg,prev)
 new_seg.start_h,
 new_seg.start_w_l,
 new_seg.start_w_r,
 new_seg.end_h,
 new_seg.end_w_l,
 new_seg.end_w_r,
 new_seg.base_h=
  0,0,0,
  7+rnd(6)-3,
  rnd(2),
  rnd(2),
  7+rnd(6)-3
 -- there must be a better way
 -- to do this, i hate this
 -- but i am very tired
 local third_height=false
 if new_seg.typ==7 then
  new_seg.typ,third_height=
   5,true
 end
 if new_seg.r_typ==7 then
  new_seg.r_typ,third_height=
   5,true
 end
 if new_seg.l_typ==7 then
  new_seg.l_typ,third_height=
   5,true
 end
 if(third_height)new_seg.end_h/=3
 
 if new_seg.typ==5 then
  new_seg.r_typ,
  new_seg.l_typ=
   5,5
 end
 if prev and (prev.typ==5
 or prev.r_typ==5
 or prev.l_typ==5
 or prev.typ==3) then
  new_seg.start_h,
  new_seg.start_w_l,
  new_seg.start_w_r
  =
   prev.end_h,
   prev.end_w_l,
   prev.end_w_r
 end

 
 -- if new seg is not a cutting
 -- a tunnel, or a 1-side cutting
 -- set to zero
 if prev
 and new_seg.typ~=3 -- not a tunnel
 and new_seg.typ~=5 -- not a cutting
 and new_seg.r_typ~=5 -- not r cutting
 and new_seg.l_typ~=5 then -- not l cutting
  prev.end_h=rnd(3)
 end
end

function add_segs(station,track)
 local num_segs=
  biomes[build_area].min_segs+frnd(5)
 local prev=station
 for s=1,num_segs do
  local seg=track_seg(prev)
  add(track,seg)
  maybe_add_train_to(seg,#track)
  -- end adding trains
  prev=seg
 end
end

function generate_track()
 printh("\nnew track with seed "..seed)
 local track,stations,num_stations=
  {},{},5+frnd(5)

 if(infinite)num_stations=2

 for i=1,num_stations do
  local station=station(track[#track])
  
  add(track,station)
  add(stations,station)
  
  if i<num_stations
  or infinite then
   add_segs(station,track)
  else
   end_of_the_line(station,track)
  end
 end
 
 return track,stations
end

function end_of_the_line(station,track)
 add(track,{
  len=100,
  tu=0,
  typ=98,
  col={12,6},
  tracks=build_tracks
 })
 station.end_of_the_line=true
end

function add_more_track(oldseg,end_line)
 if end_line 
 or (track[oldseg].station and infinite)
 then
  -- dup
  local station=station(track[#track])
  add(track,station)
  if last_stop then
   end_of_the_line(station,track)
  else
   add_segs(station,track)
  end
  return station
 end
 return nil
end

function generate_height_at_midpoint(left,right,randomness)
 terrain[flr((left+right)/2)]=
  (terrain[left]+
   terrain[right])/2
    +(rnd(1)*randomness-(randomness/2))
end

function generate_city(randomness)
 width,initial_height,city=
  128,50,{}

 for i=1,width do
  if i%7==0 then
   initial_height+=frnd(25)-12
  end
  city[i]=initial_height
 end
end

function generate_terrain(randomness,initial_height)
 width,initial_height,terrain=
  128,40,{}

 for i=1,width do
  terrain[i]=initial_height
 end

 local step=flr(width/2)

 while(step>=1) do
  local segmentstart=1
  while(segmentstart<=width) do
   local left=segmentstart
   local right=left+step
   if right>width then
    right-=width
   end
   generate_height_at_midpoint(left,right,randomness)
   segmentstart+=step
  end
  randomness/=2
  step/=2
 end
end
-->8
-- palette stuff

--8010
function init_palette_2()
 for z=0,3 do
  for i=0,15 do
   poke(0x5000+16*z+i,
    sget(96+i,80+z))
  end
 end
end

function init_palette()
 --pal()

 pal(2,141,1)
 pal(7,135,1)
 pal(8,137,1)
 pal(10,140,1)
 pal(11,138,1)
 pal(12,134,1)
 pal(14,131,1)
 pal(15,133,1)--]]

 -- winter
--[[ pal(2,13,1)
 pal(3,13,1)
 pal(5,6,1)
 pal(7,135,1)
 pal(8,137,1)
 pal(10,7,1)
 pal(11,7,1)
 pal(12,7,1)
 pal(14,140,1)
 pal(15,7,1)--]]
end

function set_palette(time_of_day,i)
 if time_of_day==active_palette
 and last_i==i then
  return
 end

 if(time_of_day>=3)
 and i>=0 then
  --dark
  set_pal(3,0,1,1,15)

  if(hours>=5 and hours<8)sky_c=2
  -- headlights
  if i<4 then
   pal(7,7)
   pal(13,13)
  elseif i>7 then
   pal(7,5)
   pal(6,1)
  end
 elseif time_of_day==2 then
  --dusk
  set_pal(2,2,4,8,9)
 elseif time_of_day==0 then
  --dawn
  set_pal(0,12,6,7,6)
  if(raining)bg_c=14
 else
  --day
  set_pal(1,14,3,13,6)
 end
 active_palette,last_i=
  time_of_day,i
end

function set_pal(
 i,
 n_bg_c,n_bg_hic,
 n_sky_c,n_cloud_c)
 
 memcpy(0x5f00,0x5000+16*i,16)
 palt(0,true)
 
 bg_c,
 bg_hic,
 sky_c,
 cloud_c=
  n_bg_c,n_bg_hic,
  n_sky_c,n_cloud_c
end

-->8
-- update stuff

function update_controls()
 if show_title then
  if btnp(⬅️) then
   seed-=1
   init_everything()
  elseif btnp(➡️) then
   seed+=1
   init_everything()
  end
  
  if btnp(❎) then
   show_title=false
   music_for_time()
  end
  
  show_credits=false
  if(btn(⬇️))show_credits=true

  if(btnp(⬆️))only_slightly_chill=not only_slightly_chill
  
  show_route=false
  if(btn(🅾️))show_route=true
  return
 end
 
 local a_msg="express service"
 if(auto)a_msg="stopping service"
 if btn(➡️) then
  auto_timer+=1
  goal_msg:set_message(
   a_msg.." in "..60-auto_timer,2,true)
 else
  auto_timer=0
 end
 
 if auto_timer>60 then
  auto=not auto
  auto_timer=0

  status_msg:set_message_with_cat(a_msg.."!",45,true)
 end
 
 if btn(⬅️)
 and not last_stop then
  journey_over_timer+=1
  goal_msg:set_message(
   "announcing last stop in "..60-journey_over_timer,2,true)
 else
  journey_over_timer=0
 end
 
 if journey_over_timer>30
 and not last_stop then
  last_stop=true
  local last_station=add_more_track(-1,true)
  status_msg:set_message_with_cat("last stop is\n"..last_station.nm.."!",60,true)
 end
 
 if btnp(⬆️) then
  throttle,throttle_vis_timer=
   max(throttle-1,-2),30
 end
 if(btnp(⬇️) or auto)
 and not doors_open then
  throttle,throttle_vis_timer=
   min(throttle+1,5),30
 end
 
 if btn(❎) then
  if journey_over then
   show_title=true
   music(0,1000)
   init_everything()
  else
   sfx(59)
   honking=true
  end 
 elseif honking then
  honking=false
  status_msg:set_message_with_cat("honk honk!",15,true)
 end
 
 -- dup
 local r=curseg
 local pcnt_in_seg=percent_in_seg(camz,camslice,r)
 local arrived=in_station(r,vel,pcnt_in_seg)
 if btnp(🅾️)
 and vel==0 then
-- printh(passenger_x)
  if doors_open 
  and (not passenger_x or 
   abs(passenger_x)>=46)
  and not journey_over then
   status_msg:set_message_with_cat(
    "doors closing!",55)
   
   if #disembarking>0 then
    goal_msg:set_message(
     #disembarking.." completed their journey!",55)
    journeys_completed+=#disembarking
    disembarking={}
   end
   if accelerate_tutorial<3 then
    accelerate_tutorial+=1
    goal_msg:set_message(
     "press ⬇️ to accelerate",55)
   end
   addall(passengers,boarding)
   doors_open,boarding=
    false,{}

   sfx(58,1)
  elseif not doors_open
  and arrived then
   local arrive_msg="all aboard!"
   if r.end_of_the_line then
    arrive_msg="this train terminates here!"
    music(55)
   elseif doors_tutorial<3 then
    doors_tutorial+=1
    goal_msg:set_message(
     "press 🅾️ to close doors",45)
   end
   status_msg:set_message_with_cat(arrive_msg,90)
   sfx(62,0,11)
   doors_open=true

   if curseg.station then    
    boarding={}
    addall(boarding,r.busy)
    r.busy={}
   end
  elseif not arrived then
   goal_msg:set_message(
    "can't open doors here!",30)
  end
 end
end

function update_camera()
 camz+=vel
 if camz>1 then
  camz-=1
  local oldcnr=camcnr
  camcnr,camslice=advance(camcnr,camslice)
  if oldcnr~=camcnr then
   time_in_seg,stops_in_seg=
    0,0
   -- do not change this,
   -- things get weird if you do
   -- (area switch happens too late)
   local r=track[camcnr]
   if(r.has_signal)total_signals+=1
   announce_next_station(camcnr+1,camcnr)
   if(not last_stop)add_more_track(oldcnr)
   local next_area=r.next_area
   if next_area then
    area,build_area=
     next_area,next_area
    generate_terrain(40)
    generate_city(40)
    
    -- change weather
    if o_rnd(2)==0 then
     set_weather()
    end
   end
  end
 end
 curseg=track[camcnr]
 
 world_ang+=vel*curseg.tu*36
 if(world_ang>=360)world_ang-=360
 if(world_ang<0)world_ang+=360
end

function update_train()

 local ot_next=track[ot_seg-1]
 if ot_next
 and (ot_next.tracks==1 
 or ot_next.points)then
  ot_vel*=0.95
 end
 ot_z-=ot_vel
 if ot_z<0 then
  ot_z+=1
  ot_slice-=1
  if ot_slice<1 then
   ot_seg-=1
   if(ot_seg>0)ot_slice=ot_next.len
  end
  ot_end_slice-=1
  if ot_end_slice<1 then
   ot_end_seg-=1
   if(ot_end_seg>0)ot_end_slice=track[ot_end_seg].len
  end
 end

  -- add a train?
 maybe_add_train_to(track[#track],#track)

 if(show_title)return
 local r=curseg
 local pcnt_in_seg,typ=
  percent_in_seg(camz,camslice,curseg),
  r.typ
 
 --braking - vel*=0.98
 if throttle>=0 then
  --0.001
  vel+=(throttle*0.0003)
 else
  vel*=(1+throttle*0.01)--0.98 is max braking
 end
 vel=min(vel,0.2)
 vel*=0.999 -- friction
 -- slow at last station
 if r.end_of_the_line then
  auto=false
  if(vel>0.05)vel*=0.9825
  throttle,breaking=0,true
  if(pcnt_in_seg>0.8)vel*=0.85
 end
 -- snap to stop at slow speeds
 if throttle<0 and vel<0.005 then
  vel=0
  stops_in_seg+=1
 end
 
-- if(stat(20)<11)sfx(62,-1,0,1)
 
 if pcnt_in_seg>0.90 
 and r.station
 and not r.end_of_the_line then
  -- downgrade score for skipping stations
  if not auto and stops_in_seg==0 then
   stops+=1
   stops_in_seg=1
   total_score+=420
  end
  status_msg:set_message_with_cat("departing\n"..r.nm,90)
  status_msg:set_message_with_cat("next stop\n"..next_s().nm,90)
 end
 
 -- check stop at station
 if in_station(r,vel,pcnt_in_seg)
 and not stopped_at_station
 then
  stopped_at_station=true
  if not r.stopped_at then
   passenger_x,
   disembarking=
    0,{}
   -- who is getting off
   for p in all(passengers) do
    if r.end_of_the_line
    or o_rnd(4)==0 then
     add(disembarking,p)
     del(passengers,p)
    end
   end
  end
  r.stopped_at=true

  stops+=1
  if stops>1 then
   -- calculate score
   local score=time_in_seg --165 is optimal
    +stops_in_seg*10 -- 10 is optimal
    +abs(to_next_landmark())*100  -- 0 is optimal

   total_score+=score
  
   goal_msg:set_message(
    "station stop rating: "..score_to_string(score),20)
  end
  goal_msg:set_message(
   "press 🅾️ to open doors",30)
 elseif vel>0 then
  stopped_at_station=false
 end
 
 if stopped_at_station
 and doors_open then
  passenger_x+=(typ-1)*2-1
  if abs(passenger_x)>=46
  and r.end_of_the_line 
  and not journey_over then
   journey_over=true
   status_msg:set_message_with_cat("all change please!",32000,true)
   end
 end

 if r.has_signal then
  r.signal_wait-=1
  if r.signal_wait==0 then
   status_msg:set_message_with_cat("signal clear!",60,true)
   signals_obeyed+=1
  end 
 end
 throttle_vis_timer=max(throttle_vis_timer-1,0)
end

function maybe_add_train_to(end_seg,len)
 if end_seg.tracks==2
 and end_seg.typ<98
 and end_seg.len>=10
 and not end_seg.points
 and ot_end_seg<camcnr
 and o_rnd(4)==0 then
  ot_seg,ot_end_seg,
  ot_slice,ot_end_slice,
  ot_z,ot_vel=
   len,len,5,14,0,0.2
 end
end

function next_s()
 for i=camcnr+1,#track do
  if track[i].station then
   return track[i]
  end
 end
end

function in_station(r,vel,pcnt_in_seg)
 return r.station
 and vel==0 
 and pcnt_in_seg>=.80
 and pcnt_in_seg<.90
end
-- make a nice timed message
function new_message(x,y,centred)
 local align=0
 if(centred)align=2
 
 return {
--  t=0,
  x=x,
  y=y,
  msgs={},
  set_message=function(s,m,t,f)
   if(f and #s.msgs>0)foreach(s.msgs,function(f)del(s.msgs,f)end)
   add(s.msgs,{m=m,t=t})
  end,
  update=function(s)
   if #s.msgs>0 then
    local cur=s.msgs[1]
    if(cur.t>0)cur.t-=1
    if(cur.t==0)del(s.msgs,cur)
   end
  end,
  draw=function(s)
   if #s.msgs>0 then
    nice_print(s.msgs[1].m,s.x-#s.msgs[1].m*align,s.y,7,1)
   end
  end
 }
end

function to_next_landmark()
 local r=curseg
 local to_next=
  flr(((r.len-1.5)-
  (camz+camslice-1))*100)/100
 if not r.station
 and not r.has_signal then
  for i=camcnr+1,#track do
   r=track[i]
   to_next+=track[i].len
   if(r.station or r.has_signal)break
  end
 end
 if r.station then
  return to_next,252
 elseif r.has_signal then
  return to_next,253
 end
 return 0,0
end

function score_to_string(s)
 if s<188 then
  return "aaa"
 elseif s<197 then
  return "aa"
 elseif s<207 then
  return "a"
 elseif s<220 then
  return "b"
 elseif s<230 then
  return "c"
 elseif s<240 then
  return "d"
 end
 return "e"
end

function announce_next_station(next_t,cursegid)
 if track[next_t].station then
  status_msg:set_message_with_cat("approaching\n"..track[next_t].nm,120)
  if brake_tutorial<3 then
   brake_tutorial+=1
   goal_msg:set_message(
    "press ⬆️ to brake soon!",45)
  end
 elseif track[cursegid].station then
  status_msg:set_message_with_cat("welcome to\n"..track[cursegid].nm,30,true)
 end
end
-->8
-- stations
name_patterns={
 {1,2},
 {2,3},
 {2,3}
}
name_bits={
{
 "north ",
 "south ",
 "east ",
 "west ",
 "central ",
 "upper ",
 "lower "},
{
 "noodles",
 "cheese",
 "chips",
 "chilli",
 "hot chips",
 "crisps",
 "kebab",
 "curry",
 "beans",
 "fish",
},
{
 "borough",
 "bourne",
 "bridge",
 " bridge",
 " broadway",
 " central",
 " common",
 " cross",
 " east",
 " end",
 "ford",
 " green",
 "ham", 
 " hill", 
 " junction", 
 " north",
 " park",
 " parkway",
 " road",
 " south",
 " street",
 " town",
 " west",
 " wood",
 "wood"
}
}
--[[station_names={
 "noodles junction",
 "cheese hill",
 "kebab street",
 "beans cross",
 "beans gate",
 "beans street",
 "kebab junction",
 "cheese common",
 "fish park",
 "fishbourne",
 "fish junction",
 "kebab common",
 "kebab bridge",
 "cheese parkway",
 "kebab wood",
 "west cheese"
}--]]

function station_name()
 local pattern,name=
  name_patterns[frnd(#name_patterns)+1],""
 for p in all(pattern) do
  name=name..name_bits[p][frnd(#name_bits[p])+1]
 end
 return name
end

function draw_passengers(s)
 rectfill(32,16,96,40,1)
 clip(33,17,63,31)
 
 rectfill(32,16,96,39,12)
 rectfill(32,16,96,26,sky_c)
 rectfill(32,27,96,27,6)
 
 local fliph,shift,start,
 platform_x=
  s.typ==1,
  80,
  32,
  72

 if fliph then
  shift,
  start,
  platform_x=
   0,50,41
 end
 spr(153,platform_x,16,2,3,fliph)
 
 local boarding_x=passenger_x
 if(s.end_of_the_line)boarding_x=0
 for i,p in pairs(boarding) do
  spr(160+p,start+boarding_x+i*5,
   23-frnd(2),1,2)
 end
 
 for i,p in pairs(disembarking) do
  spr(160+p,(shift-passenger_x)+32-i*5,
   23-frnd(2),1,2)
 end
 platform_x=88
 if(fliph)platform_x=33
 spr(155,platform_x,16,1,3,fliph)

 clip()
end
	
-->8
-- util


-- pseudo random stuff 
function s_o_rnd()
 for i=1,300 do
  o_rnd_vals[i]=rnd()
 end
end

function o_rnd(n)
 o_rnd_ptr=1+o_rnd_ptr%300
 return flr(o_rnd_vals[o_rnd_ptr]*10000%n)
end

function frnd(n)
 return flr(rnd(n))
end

function addall(dst,src)
 for _,i in pairs(src) do
  add(dst,i)
 end
end

function lerp(a,b,pcnt)
 return a+(b-a)*pcnt
end

function project(x,y,z)
 local scale=64/z
 return x*scale+64,y*scale+64,scale
end

function nice_print(s,x,y,c,shadow)
 print(s,x-1,y,shadow)
 print(s,x+1,y)
 print(s,x,y-1)
 print(s,x,y+1)
 print(s,x,y,c)
end

function tick(t_speed)
 timer+=1
 time_in_seg+=1
 
-- if timer%30==0 then
  seconds+=t_speed
  if seconds>=60 then
   seconds=0
   minutes+=1
   if minutes>=60 then
    minutes=0
    hours+=1
    -- change time of day
    set_time_of_day()
    if hours==6 then
     cue_music(0)
    elseif hours==14 then
     cue_music(16)
    elseif hours==22 then
     cue_music(31)
    end
    
    if hours>=24 then
     hours=0
    end
   end
--  end
  
 end
  
end

function set_time_of_day()
 if hours>=20 
 or hours<6 then
  time_of_day=3
 elseif hours>=17 then
  time_of_day=2
 elseif hours>=10 then
  time_of_day=1
 elseif hours>=6 then
  time_of_day=0
 end
end

-- 
-- music stuff
-- 
function music_for_time()

 if hours>=6 and hours<=14 then
  music(0+(hours-6),7500)
 elseif hours>14 and hours<22 then
  music(16+(hours-14),7500)
 else
  music(31+(hours-22)%24,7500)
 end
end

function cue_music(song)
 next_song=song
end

function update_music()
 local note=stat(21)
 if current_note~=note then
  note_len,current_note=0,note
 else
  note_len+=1
 end
 if next_song 
 and stat(21)==31
 and note_len>=3 
 and not journey_over then
  music(next_song)
  next_song=nil
 end
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
00000660666600000000066666666600151eeee151eeee151eeee1515f51f5115f51f511115f15f51111111111111111f775800000f75000057f0f7f00f77f88
00006666666000000000666666666000151eeee151eeee151eeee1515151151151511511115115151ffefef5f5552521fc7c5ffff0f7f0000f7f0f7fffc77f48
00666666600000000006666666600000151eeee151eeee151eeee1515151151151511511115115151fefff5555f55251f5c77777f0fcf0000f7f0fc77777f088
06666666000000000066666666000000e51111115111111511111151dedeedeededeedeeeedeeded1efefe5f555525210ffffffff01ff00001ff01ffffff0088
66666666000000000666666660000000e511e1115f5555f51e11e1516161161161611611116116161fffff555525552100000000000000000000000000000088
06666666000006666666600000000000151e11e151111115111e1151d1d11d11d1d11d1111d11d1d1ef1f555555552215ffffff5005ff05fffff0005fffffff8
0006666600006666666600000000000015111e115111111511e111515151151151511511115115151ff1f55555525521f777777750f7f0f7777c500f777777f8
000000000006666666600000000000001511e111dddddddd1e1111515151151151511511115115151ef1f54885555221f7ffff57f0f7f0f7fff5cf0f75fffff8
6666000000066666666000000000000015111111dddddddd111111515f51f5115f51f511115f15f51ff1f55555555521f7f880f7f0f7f0f7f00f7f0f7f000088
66600000006666666660000000000000d5888888822222288888885ddddff511dddff511115ffddd1ff1f54885555521f7fffff7f0f7f0f7f00f7f0f7ff50884
60000000066666666666000000000006658999998244442899999856d66dddffd66dddffffddd66d1ff1f5c777777c21f777777588f7f8f7f88f7f8f777f8840
00000000066600000006600000000066658999998244442899999856d66666ddd66666dddd66666d1ef1f55555552521f7fff577f4f7f4f7f44f7f4f75ff4400
00000000660000000000660000000666d5899999824444289999985dddd66666ddd6666666666ddd15f1f55555555521f7f88fc7f0f7f0f7f00f7f0f7f000000
00000666660000000000666000066666f5888888824444288888885f555ddd66555ddd6666ddd5551ef1f5e335555221f7f44057f0f7f0f7ffff7f0f75fffff0
00006666600000000000066600666666fffffffffffffffffffffffffff555ddfff555dddd555fff1ff1f55555555521f7f000f7f0f7f0fc77777f0fc77777f0
00066666000000000000006666666666ff11f55f1ffffff1f55f111ffffff555fffff555555fffff1ef1f5e3355255211ff0001ff01f501ffffff001fffffff0
66666600666660000000000006666666ff1155551f1111f15555111f11fffff511fffff55fffff111ff1f55555555521111155dd2dd55dd20001f2d600cccc00
66666000666666000000000000066666fff155551f1111f1555511f10011ffff0011ffffffff110015f1f5e335555221ce5ddddddd5895dd0000000d0c7f76c0
66660000666666600000000000006666fff1f55f1ffffff1f55f1ff10001111f0001111ff111100015f1f55555555521ce52dddddd5245dd0000000ec77f776c
6660000000006660000000000000066601ff1111111111111111ff100000111100001111111100001ff1f5e3355f5221cef22ddddd5c75dd0000000fc77f776c
666000000000006600000000000006660011ff11ffffffff1fff11000000ff110000001111ff00001ef1f55555555521ce5fdddddd53b5dd007984f15777f77c
6660000000000066000000000000066600000ff1111111111ff0000000000ff1000000011ff0000015fff5e3355f2221cefd2ddddd5e35dd0000000e5c777f7c
6666600000000006000000000006666600000ff1000000001ff0000000000ff1000000001ff000001ffeff5555fe5e215cc89dddddd5cddd6c5e1003057777c0
66666660000000000000000006666666000000f0000000000f000000000000100000000001000000111111111111111155555eee2ee5cee20000007b005ccc00
__label__
jjjjjjjjjjjjjjjjjjjjjjjjj1111111116666666666666666666666566666666666666666666666666666666666666666666665666663jj3jj55jjjjjjjjj33
1111111111111111111111111111111111166666666666666666666656666666666666666666666666666666666666666666666355533311133jjjj11jj111jj
1111111111111111111111111111111111116666666666666666666656666666666666666666666666666666666666666666666j55333311133jjjj11jj111jj
mmmmmmmmmmmmmmmmjjjjjjjjjjj1111111116666666666666666666656666666666666666666666666666666666666666666666j55333l111111111llllj11jj
jmmmmmmmmmmmmmmmjjjjjjjjjjj1111111116666666666666666666656666666666666666666666666666666666666666666666155jjj5551jjll1111jj3jj11
jjjjjjjjjjjjjjjjjjjjjjjjjjjj1111111116666666666666666666566666666666666666666666666666666666666666666663553jj5551jjll1111jj3jj11
jjjjjjjjjjjjjjjjjjjjjjjjjjjjj111111116666666666666666666566666666666666666666666666666666666666666666663553j3311511jjll11331ll11
jjjjjjjjjjjjjjjjjjjjjjjjjjjjj11111111166666666666666666656666666666666666666666666666666666666666666655j55333311511jjll11331ll11
1111111111111111111111111111111111111166666666666666666656666666666666666666666666666666666666666666655333jjj333jjj111111jjj5511
1111111111111111111111111111111111111116666666666666666665666666666666666666666666666666666666666666655333jjj333jjj111111jjj5511
mmmmmmmjjjjjjjjjjjjjjmmmjjjjjjj111111116666666666666666665666666666666666666666666666666666666666666666j33j113jjj11llllll11111ll
mmmmmmmmmjjjjjjjjjjjjjmmmjjjjjjj111111116666666666666666656666666666666666666666666666666666666666666331jjl11ljjj11llllll11111ll
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj111111116666666666666666656666666666666666666666666666666666666666656331jjl11l115jjjj55555555555
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj11111111666666666666666656666666666666666666666666666666666666666656331ll55533511jjj55mm555j111
11111111111jjjjjjjjjjjjjjjjjjjjjj11111111666666666666666656666666666666666666666666666666666666666635jj3jj5jj331551jj55mm555l111
111111111111111111111111111111111111111111666666666666666566666666666666666666666666666666666666666j5jj3jj5jj3315511j55mmmm1l111
111111llllllllllllllllllllllllllllllll111116666666llllllllllllllllllllllll6666666666665555lllllllllllllllllllllllljj155mmmmj511j
mmmmmmllllllllllllllllllllllllllllllll111116666666llllllllllllllllllllllll6666666666665555lllllllllllllllllllllllljj15333mm33333
jjjjjjllllllllllllllllllllllllllllllll111116666666llllllllllllllllllllllll6666666666665555llllllllllllllllllllllll11l5333mm33333
111111llllllllllllllllllllllllllllllll111111666666llllllllllllllllllllllll6666666666665555lllllllllllllllllllllllljj333333333333
jmllll5555mmmmnnnnnnnnnnnnnnnnnnnnllll11111166llllmmmmnnnnnnnnnnnnnnnnmmmmllll66666666llllnnnnnnnnnnnnnnnnnnnnmmmm55553333333333
jjllll5555mmmmnnnnnnnnnnnnnnnnnnnnllll11111166llllmmmmnnnnnnnnnnnnnnnnmmmmllll666666ddllllnnnnnnnnnnnnnnnnnnnnmmmm5555jjjjjjj333
11llll5555mmmmnnnnnnnnnnnnnnnnnnnnllll11111166llllmmmmnnnnnnnnnnnnnnnnmmmmllll66666dddllllnnnnnnnnnnnnnnnnnnnnmmmm5555jjjjjjj333
1jllll5555mmmmnnnnnnnnnnnnnnnnnnnnllllj1111166llllmmmmnnnnnnnnnnnnnnnnmmmmllll666666ddllllnnnnnnnnnnnnnnnnnnnnmmmm5555jjjjjjjjjj
11llllmmmmnnnnmmmm5555lllllllllllllllljj111166llllnnnnnnnnllllllllnnnnnnnnllllddddddddllllnnnnllll55555555mmmmnnnnlllljjjjjjjjjj
51llllmmmmnnnnmmmm5555lllllllllllllllljj111166llllnnnnnnnnllllllllnnnnnnnnllllddddddddllllnnnnllll55555555mmmmnnnnlllljjjjjjjjjj
55llllmmmmnnnnmmmm5555llllllllllllllll11111166llllnnnnnnnnllllllllnnnnnnnnllllddddddddllllnnnnllll55555555mmmmnnnnlllljjjjjjjjjj
55llllmmmmnnnnmmmm5555lllllllllllllllljjjj1166llllnnnnnnnnllllllllnnnnnnnnllllddddddddllllnnnnllll55555555mmmmnnnnllll111jj11j33
55llllnnnnnnnn5555pppp1111jjjjjjjjjjjjjjjj1166llllnnnn5555656666665555nnnnllllddddddddllllnnnnllllllllllllmmmmnnnnllll1111113333
55llllnnnnnnnn5555pppp111111111111111111111166llllnnnn5555656666665555nnnnllllddddddddllllnnnnllllllllllllmmmmnnnnllll3333333333
55llllnnnnnnnn5555ppppjjjjjjjjj113666666666666llllnnnn55556656666d5555nnnnllllddddddddllllnnnnllllllllllllmmmmnnnnllll3333333333
55llllnnnnnnnn5555ppppjjjjjjj11336666666666666llllnnnn5555665666665555nnnnllllddddddddllllnnnnllllllllllllmmmmnnnnllll33333333jj
55llllnnnnnnnnllllppppjjjjjjj11jj6666666666666llllnnnnllll6656666dllllnnnnllllddddddddllllnnnnnnnnnnnnnnnnnnnn55551133jjjjjjjjjj
55llllnnnnnnnnllllppppj11jj1111336666666666666llllnnnnllll66566666llllnnnnllllddddddddllllnnnnnnnnnnnnnnnnnnnn55553333jjjjjjjjjj
55llllnnnnnnnnllllppppj11jj1111333366666666666llllnnnnllll6665ddddllllnnnnllllddddddddllllnnnnnnnnnnnnnnnnnnnn55553333jjjjjjjjjj
55llllnnnnnnnnllllpppp111111133jjjj66666636666llllnnnnllll666566ddllllnnnnllllddddddddllllnnnnnnnnnnnnnnnnnnnn55553333111jjjjjjj
55llllnnnnnnnnllllpppppppppppppppppppppppppppp5555nnnn5555llllllll5555nnnn5555ppppppppllllnnnnllllllllllllllllmmmm5555111jjjjjjj
55llllnnnnnnnnllllpppppppppppppppppppppppppppp5555nnnn5555llllllll5555nnnn5555ppppppppllllnnnnllllllllllllllllmmmm5555111jjjjjjj
55llllnnnnnnnnllllpppppppppppppppppppppppppppp5555nnnn5555llllllll5555nnnn5555ppppppppllllnnnnllllllllllllllllmmmm5555111111jj11
55llllnnnnnnnnllllpppppppppppppppppppppppppppp5555nnnn5555llllllll5555nnnn5555ppppppppllllnnnnllllllllllllllllmmmm55553331111111
55llllnnnnnnnnllllpppp444444444444444444445555nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn55554444llllnnnnllll44444444llllnnnnnnnn5555331133
55llllnnnnnnnnllllpppp444444444444444444445555nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn55554444llllnnnnllll44444444llllnnnnnnnn5555331133
55llllnnnnnnnnllllpppp444444444444444444445555nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn55554444llllnnnnllll44444444llllnnnnnnnn5555333333
55llllnnnnnnnnllllpppp444444444444444444445555nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn55554444llllnnnnllll44444444llllnnnnnnnn5555113311
55llllnnnnnnnnllllpppp33333qq333333133jj1jllllnnnnmmmmllllllllllllllllmmmmnnnnlllljjj3llllnnnnllll33333333llllnnnnnnnnllllpppp11
55llllnnnnnnnnllllpppp3333333333333333jj13llllnnnnmmmmllllllllllllllllmmmmnnnnlllljjjjllllnnnnllll33333333llllnnnnnnnnllllpppp33
55llllnnnnnnnnllllpppp3333333333333133111jllllnnnnmmmmllllllllllllllllmmmmnnnnlllljjjjllllnnnnllll33333qq3llllnnnnnnnnllllpppp33
55llllnnnnnnnnllllpppp3333333333333333333jllllnnnnmmmmllllllllllllllllmmmmnnnnlllljjjjllllnnnnllll3333333mllllnnnnnnnnllllpppp33
55llllnnnnnnnn5555ppppm33mm33mmqq33333333jllllnnnn5555jjjj33jjjj5mjjjj5555nnnnlllljj31llllnnnnllllm33mm333llllnnnnnnnnllllpppppp
55llllnnnnnnnn5555pppp3mmmmmmmm33333333331llllnnnn5555jjjjj3jjjj55jj555555nnnnlllljjj1llllnnnnllllmmm3333mllllnnnnnnnnllllpppppp
55llllnnnnnnnn5555ppppm33mmmmmm33333333333llllnnnn5555jjjjjjjjjjj5jjjj5555nnnnlllljj13llllnnnnllllm33mmmm3llllnnnnnnnnllllpppppp
55llllnnnnnnnn5555ppppmmmmmmmmm33ttq333331llllnnnn5555jjjjjjjjjjj5mmjj5555nnnnlllljj13llllnnnnllllmmmmmmmmllllnnnnnnnnllllpppppp
55llllmmmmnnnnmmmm5555llllllllllllllll3333llllnnnnllll3jjjjjjjjjj555j5llllnnnnllll3133llllnnnnllllllllllllmmmmnnnnnnnnllll4444pp
55llllmmmmnnnnmmmm5555llllllllllllllllqq33llllnnnnllll133jjjjjjjjj5jjjllllnnnnllllj133llllnnnnllllllllllllmmmmnnnnnnnnllll4444pp
55llllmmmmnnnnmmmm5555llllllllllllllll3333llllnnnnllllj1jjjjjjjjjj5jjjllllnnnnllll1333llllnnnnllllllllllllmmmmnnnnnnnnllll4444pp
55llllmmmmnnnnmmmm5555llllllllllllllll333qllllnnnnllll3jjjjjjjjjjjj5j5llllnnnnllll1333llllnnnnllllllllllllmmmmnnnnnnnnllll4444pp
55llll5555mmmmnnnnnnnnnnnnnnnnnnnnllll33t3llllmmmmllll31j3jjjjjjjjj5jjllllnnnnllll3333llllmmmmnnnnnnnnnnnnnnnnnnnnllll3333pppppp
55llll5555mmmmnnnnnnnnnnnnnnnnnnnnllllttt3llllmmmmllllj3jjjjjjjjj15m55llllnnnnllll3333llllmmmmnnnnnnnnnnnnnnnnnnnnllllmmm3pppppp
55llll5555mmmmnnnnnnnnnnnnnnnnnnnnllllttt3llllmmmmllllj1jjjjjjjjjp5pj5llllnnnnllll3333llllmmmmnnnnnnnnnnnnnnnnnnnnllllmmmtpppppp
55llll5555mmmmnnnnnnnnnnnnnnnnnnnnlllltttmllllmmmmllll1jjjjjjjpjpjpjpjllllnnnnllll3333llllmmmmnnnnnnnnnnnnnnnnnnnnllllmmmtpppppp
555555lllllllllllllllllllllllllllllllltttm1111lllllllljjjjjjjpjpjpjpjp1111llllllll33t31111llllllllllllllllllllllllmmmmmmmtpppppp
555555lllllllllllllllllllllllllllllllltttm1111llllllllj3jjjjpjpjpppppj1111llllllll3mtt1111llllllllllllllllllllllllmmmmmmmtpppppp
555555lllllllllllllllllllllllllllllllltttm1111llllllll113jjjjpjppppppp1111llllllll3mtt1111llllllllllllllllllllllllmmmmmmmtpppppp
555555lllllllllllllllllllllllllllllllltttm1111llllllll311jjjpjpppppppp1111llllllll3mtt1111llllllllllllllllllllllllmmmmmmmtpppppp
555555555mmmmmmmmmmmmmmmmmmmmmmttttmmmtttmmttmmttm333t331mjpjppn4pppppppjpj55j5333mmttmttmmtttmmmmmmmmmmmmmmmmmmmmmmmmmmmtpppppp
555555555mmmmmmmmmmmmmmmmmmmmmmttttmmmtttmmttmmttmt33t333m33p3np4ppppppjpjj55j533tmmttmttmmtttmmmmmmmmmmmmmmmmmmmmmmmmmmmtpppppp
555555555mmmmmmmmmmmmmmmmmmmmmmttttmmmtttmmttmmttmtmtt333m3p3pppppppppppjpj55j53mtmmttmttmmtttmmmmmmmmmmmmmmmmmmmmmmmmm333pppppp
555555555mllllllll555mmmmmmmmmmttttmmmtttmmttmmttmtmtt333mjjp1pppppppppjpjj55j53mtmmttmttmmtttmmmmmmmmmmmmmmmmmmmmmmmmm333pppppp
555555llllllllllllllllllllllll5555tmmmtttm5555lllllllltm3m5555llllllllllllllllllllmmttmttmmttt5555llllllllllllllllllllllllllllpp
555555llllllllllllllllllllllll5555tmmmtttm5555lllllllltmtm5555llllllllllllllllllllmmttmttmmttt5555llllllllllllllllllllllllllllpp
555555llllllllllllllllllllllll5555tmmmtttm5555lllllllltqqq5555llllllllllllllllllllmmttmttmmttt5555llllllllllllllllllllllllllllpp
555555llllllllllllllllllllllll5555tmmmtttm5555llllllll33335555llllllllllllllllllllmmttmttmmttt5555llllllllllllllllllllllllllllpp
55llllnnnnnnnnnnnnnnnnnnnnnnnnnnnn5555tttmllllnnnnllll3311llllnnnnnnnnnnnnnnnnmmmm5555mttmmtttllllnnnnnnnnnnnnnnnnnnnnnnnnllllpp
55llllnnnnnnnnnnnnnnnnnnnnnnnnnnnn5555tttmllllnnnnllll11ltllllnnnnnnnnnnnnnnnnmmmm5555mttmmtttllllnnnnnnnnnnnnnnnnnnnnnnnnllllpp
55llllnnnnnnnnnnnnnnnnnnnnnnnnnnnn5555tttmllllnnnnllllltttllllnnnnnnnnnnnnnnnnmmmm5555mttmmtttllllnnnnnnnnnnnnnnnnnnnnnnnnllllpp
55llllnnnnnnnnnnnnnnnnnnnnnnnnnnnn5555ttt3llllnnnnlllltdddllllnnnnnnnnnnnnnnnnmmmm55553ttmmtttllllnnnnnnnnnnnnnnnnnnnnnnnnllllpp
55llllnnnnllllllllllllllll5555nnnnllllqqqqllllnnnnllllddddllllnnnnllllllllllll5555mmmmllllmtttllllnnnn5555llllllllllllllllllllpp
55llllnnnnllllllllllllllll5555nnnnllllqqqqllllnnnnlllltdddllllnnnnllllllllllll5555mmmmllllmtttllllnnnn5555llllllllllllllllllllpp
55llllnnnnllllllllllllllll5555nnnnllll3333llllnnnnllllddddllllnnnnllllllllllll5555mmmmllll3tttllllnnnn5555llllllllllllllllllllpp
55llllnnnnllllllllllllllll5555nnnnllllqqqqllllnnnnllllddddllllnnnnllllllllllll5555mmmmllllqqqqllllnnnn5555llllllllllllllllllllpp
55llllnnnnllllppppppppmmmmllllnnnnllllqqqqllllnnnnllllddd5llllnnnnllllt6nt5dddllllnnnnllllqqqqllllnnnnllllmmmmmmmmmmmmm333pppppp
55llllnnnnllllpppppppp3333llllnnnnllll3311llllnnnnlllldd5tllllnnnnllllt6n15dddllllnnnnllll3333llllnnnnllll333333mmmmmmm333pppppp
55llllnnnnllllpppppppp3333llllnnnnllll3111llllnnnnllllddddllllnnnnllllmmnn1dddllllnnnnlllllmm3llllnnnnllll333333mmmmmmm333pppppp
55llllnnnnllllpppppppp3333llllnnnnllll11llllllnnnnllllddd1llllnnnnllll116nddddllllnnnnllllllm3llllnnnnllll333333mmmmmmm333pppppp
55llllnnnnllllllllllllllllllllnnnnllll11ltllllnnnnllllddd1llllnnnnllll116n1dddllllnnnnllllllllllllnnnnllllllll55553333pppppppp44
55llllnnnnllllllllllllllllllllnnnnllllltttllllnnnnlllldtttllllnnnnlllltt6nt15dllllnnnnllllttllllllnnnnllllllll55553333pppppppp44
55llllnnnnllllllllllllllllllllnnnnllllltttllllnnnnlllld516llllnnnnllll116nndddllllnnnnllllttllllllnnnnllllllll55553333pppppppp44
55llllnnnnllllllllllllllllllllnnnnllllttttllllnnnnllllttt6llllnnnnllllttt6nt15llllnnnnlllltlllllllnnnnllllllll5555qqqqpppppppp44
55llllnnnnnnnnnnnnnnnnnnnnnnnn5555ppppppppllllnnnnllllppppllllnnnnllllppppppppllllnnnnllllppppllllnnnnnnnnnnnnllllpppppppp444433
55llllnnnnnnnnnnnnnnnnnnnnnnnn5555ppppppppllllnnnnllllppppllllnnnnllllppppppppllllnnnnllllppppllllnnnnnnnnnnnnllllpppppppp444433
55llllnnnnnnnnnnnnnnnnnnnnnnnn5555ppppppppllllnnnnllllppppllllnnnnllllppppppppllllnnnnllllppppllllnnnnnnnnnnnnllllpppppppp444433
55llllnnnnnnnnnnnnnnnnnnnnnnnn5555ppppppppllllnnnnllllppppllllnnnnllllppppppppllllnnnnllllppppllllnnnnnnnnnnnnllllpppppppp444433
55llllnnnnllllllllllll5555nnnnnnnnllll4444llllnnnnllll4444llllnnnnllll44444444llllnnnnllll4444llllnnnn5555llllllll44444444333333
55llllnnnnllllllllllll5555nnnnnnnnllll4444llllnnnnllll4444llllnnnnllll44444444llllnnnnllll4444llllnnnn5555llllllll44444444333333
55llllnnnnllllllllllll5555nnnnnnnnllll4444llllnnnnllll4444llllnnnnllll44444444llllnnnnllll4444llllnnnn5555llllllll44444444333333
55llllnnnnllllllllllll5555nnnnnnnnllll4444llllnnnnllll4444llllnnnnllll44444444llllnnnnllll4444llllnnnn5555llllllll44444444333333
55llllnnnnllllppppppppllllmmmmnnnnllllddddllllnnnnllllntttllllnnnnllllttttt6ntllllnnnnllllddddllllnnnnllllllmll33333333333333333
55llllnnnnllllppppppppllllmmmmnnnnllllddddllllnnnnlllln111llllnnnnllll111116nnllllnnnnllllddddllllnnnnlllllllmml3333333333333333
55llllnnnnllllppppppppllllmmmmnnnnllllddddllllnnnnllll55ddllllnnnnllll551116nnllllnnnnllll6dddllllnnnnllllllllmmlmm33333333qqqqq
55llllnnnnllllppppppppllllmmmmnnnnllll5jj1llllnnnnllllmmmmllllnnnnllllmmmmm66nllllnnnnllllddddllllnnnnlllllllllllmmmmmm3333qqqqq
55llllnnnnllll44444444llll5555nnnnlllljj11llllnnnnllllttttllllnnnnllllllllllllllllnnnnllllddddllllnnnn5555llllllllllllllllllll33
55llllnnnnllll44444444llll5555nnnnlllljj11llllnnnnllll1111llllnnnnllllllllllllllllnnnnllllddddllllnnnn5555llllllllllllllllllll33
55llllnnnnllll44444444llmm5555nnnnllllj11dllllnnnnllll1111llllnnnnllllllllllllllllnnnnllllddddllllnnnn5555llllllllllllllllllll33
51llllnnnnllll44444444llmm5555nnnnllll11ddllllnnnnlllldd55llllnnnnllllllllllllllllnnnnllllddddllllnnnn5555llllllllllllllllllll33
11llllnnnnllll55mmllllllmmllllnnnnllll11ddllllnnnnllll5dddllllmmmmnnnnnnnnnnnnnnnnnnnnllllddddllllmmmmnnnnnnnnnnnnnnnnnnnnllll33
j1llllnnnnllll55mmlllmmmmmllllnnnnllll1dddllllnnnnllllddddllllmmmmnnnnnnnnnnnnnnnnnnnnllllddddllllmmmmnnnnnnnnnnnnnnnnnnnnllll33
1dllllnnnnllll55mmlllmmmmmllllnnnnllllddddllllnnnnllllttttllllmmmmnnnnnnnnnnnnnnnnnnnnllllddddllllmmmmnnnnnnnnnnnnnnnnnnnnllll33
ddllllnnnnllll55mmlllmmmmmllllnnnnlllld55tllllnnnnllllttttllllmmmmnnnnnnnnnnnnnnnnnnnnllllddddllllmmmmnnnnnnnnnnnnnnnnnnnnllll33
d91111llllllllll55lllmmmmm1111llllllll11111111llll555511111111lllllllllllllllllllllllldddddddd1111llllllllllllllllllllllllllll33
991111llllllllll55lllmmmmm1111lllllllldddd1111llll555511111111lllllllllllllllllllllllldddddddd1111llllllllllllllllllllllllllllml
991111llllllllll55lllmmmmm1111lllllllldddd1111llll5555ddd51111lllllllllllllllllllllllldddddddd1111llllllllllllllllllllllllllllmm
dd1111llllllllmmmmmmmmmmmm1111llllllllddd51111llll5555d55d1111lllllllllllllllllllllllldddddddd1111llllllllllllllllllllllllllllll
dddddmmmmmmmmmmmmmmmmmmmmm555jjj111ddddddmmmm66nnmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm66nnmmm11ddddddddddddddddddddddtttttttlllllllllll
dddmmmmmmmmmmmmmmmmmmmmmm555jjj111dddddddmmmm66nnmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm66nnmmm111dddddddddddddddddddddddtttttttlllllllll
ddmmmmmmmmmmmmmmmmmmmmmm555jjj111ddddtttttttt66ntttttttttttttttttttttttttttttttt66nttt11155ddddddddddddddddd66dddddttttlllllllll
dmmmmmmmmmmmmmmmmmmmmmm5555jjj111dd55ttttttt66nntttttttttttttttttttttttttttttttt66nnttt11155dddddddddddddddddddtttddtttttttlllll
mmmmmmmmmmmmmmmmmmmmmm5555jjj111dd55tttttttt66nntttttttttttttttttttttttttttttttt666nttt11155ddddddddddddddddddddttdddtttttttllll
mmmmmmmmmmmmmmmmmmmmmm555jjjj111dd111111111666n111111111111111111111111111111111166nn111111dddddddddddddddddddddddddttttttttttll
mmmmmmmmmmmmmmmmmmmmm555jjjj111dd111111111166nn111111111111111111111111111111111166nn111111dddddddddddddddddddddddddttttttttttll
mmmmmmmmmmmmmtttmmmm555jjjj111dddddddd1111166nn1111111111111111111111111111111111666n1111ddddddddddddddddddddddd666dddddtttttttt
mmmmmmmmmmmmmtttmmmm555jjjj111ddddddd11111666nn1111111111111111111111111111111111166nn111dddddddddddddddddddddddd666dddddttttttt
m666nnnnnnnnnnn666mmmm5551111dddddddddd111666n1555ddd5555555555555555555551111111166nn1111dddddddddddddddddddddddddddttttttttttt
nnnn666mmmmnnnnnnnmmmm5551111dddd555ddd11166nn155dddddd5555555555555555dddddd11111666nn111ddddddddddddddddddddddddd66ddddddttttt
nn6666mmmmnnnnnnnmmmm5551111ddddd555ddd11666nn1555ddddd55555555555555555ddddd11111166nn1111ddddddddddddddddddddddddd666dddddtttt
mmmmmmmmmmmmmmmm5555jjj1111ddddddddddd111666n1555dddddd55ddd55555555555dddddd111111666n1111dddddddddddddddddddddddddddd666tttttt
mmmmmmmmmmmmmmmm555jjjj1111ddddddddddd11166nn1555dddddd555ddd55555555555dddddd11111666nn1111ddddddddddddddddddddddddddddd666tttt
mmmmmmmmmmmmmm5555jjjj1111ddddddddmmmmmm666nnmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm66nnmmmm111ddddddddddddddddddddddddddddddddt
mmmmmmmmmmmmmm5555jjjj1111ddddddddmmmmmm666nmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm666nnmmmm111dddddddddddddddddddddddddddddddd

__map__
c0c1c2c3c0c1c2c3c3f100c0c3c100c0e0d2d2d2e0d2d1d2f00000f3f00000f300d2e30000d20000f100000000e20000d09f000000000000c0c1c2c3f0f2f2f3f00000f3c0c1c2c3c3d3f3bcbcbcbcbcd3f3bcbcbcbcbcbcbcc3f0f3000000000000000000000000000000000000000000000000000000000000000000000000
d2d1d2d3d2d1c3d300d2e2d200d2e2d2d1d2d1e0d1d2d1d1c3e2e3c3bcc1c2c3d08ff000d0d30000000000f100d0c1f20000d09f00d0c29fd2d1c3d3c3f2f2f3bcc1c2c3d2d1c3d3f0f2c0bcbcd1d2bce3bcbcd3bcd1c0bcc3d3c0bc000000000000000000000000000000000000000000000000000000000000000000000000
e0e1f1e3e0e1f1e3d2e2f2e2d2f39fe2e3e0e1d1e3c3e1d1f000d28fbcc3bcc3c0c1c0c1c0c1c0c100d2f1000000c0f100d0c19f00000000e0e1f1e3bcc1c2bcbcc3bcc3e0e1f1e3c3f2f2f3bce18ff3bcbcf0e3f0f2f2f3f0d09ff3000000000000000000000000000000000000000000000000000000000000000000000000
f0f2f2f3f0f1f2f3f0d2e2e3f0d2e2e3c3d300e1c3d3c2e1c3e2d2c1c3e2d2c19fc09fc0d0f1d2c000f10000e200000000000000d0c39f00f0f1f2f3bcd3c0bcc3e2d2c1f0f1f2f3bcc1c2bcbcbcbcbcbcbcbcbcbcc1c2bcbcc1c2bc000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00000764518000180001800000665000000000005635086451800018000180000166500000000000663507645180001800018000006650000000000056350864518000180001800001665000000000006635
010e00000764504015040150402500665040250403505635086450403504035040350166504025040150663507645040150401504025006650402504035056350864504035040350403501665040250401506635
010e00001471514715147151472514725147251473514735147451473514735147351472514725147151471514715147151471514725147251472514735147351474514735147351473514725147251471514715
010e00002852028525275102751525520255252351023515205202052120521205212052120521205252151023520235212352123521235222352223522235222352123521235212352518500185001c5151c555
010e00002852028525275102751525520255252351023515205202052120521215212152221522215232150028520285252651026515255202552523510235151f5201f5211f5211a5211a5221a5251a5151b515
010e00000764509015090150902500665090250903505635086450903509035090350166509025090150663507645070150701507025006650702507035056350864507035070350703501665070250701506635
010e00001971519715197151972519725197251973519735197451973519735197351972519725197151971515715157151571515725157251572515735157351574515735157351573515725157251571515715
010e00001c5101c515235212352523520235212352223522235222352223522235212352123521235112351300000000000000000000000000000000000000000000000000000000000000000000001c5001c500
010e00002850028500275002750025500255002350023500205002050020500205002050020500205002150023500235002350023500235002350023500235002350023500235002350018500185001c5151c555
010e000014715147151c3151472514725147251473514735147452c315147352c31514725147252c3121471514715147151c315147251472514725147351473514745147352c3152c31214725147251471514715
010e00000760018000273151800000600000000000005600086002731518000273150160000000273120660507605180002731518000006050000000000056050760518000273152731200605000001c5351c535
010e00000764504015040150402500665040250403505635086450403504035040350166504025040150663507645040150401504025006650402504035056350864504035347230403501665287330401506635
010e00000764506015060150602500665060250603505635066450603506035060350166506025060150663507645060150601506025006650602506035056350864506035060350603501665080250801506635
010e000007645090150901509025006650902509035056350864509035090350903501665090250901506635076450d0150d0150d025006650d0250d03505635086450b0350b0350b035016650b0250b01506635
010e00001571515715157151572515725157251573515735157451573515735157351572515725157151571515715157151571515725157251572515735157351574515735157351573517725177251771517715
010e0000197151971519715197251972519725197351973519745197351973519735197251972519715197151c7151c7151c7151c7251c7251c7251c7351c7351b7451b7351b7351b7351b7251b7251b7151b715
010e000019715197151971519725197251972519735197351974519735197351973519725197251971519715197151b7151c7151c7251c7251c7251c7351c7351c7451c7351c7351c7351b7251b7251971517715
010e000006534125311e5311e5351c5201c5211c5351e5301e5321e53120531205322053120521205232350509534155312153121535205202052120535215302153221531235312353223532235212352323505
010e00000d53419531255352353520530205352152021525285202852127521275212352123521255202552125521255212c5242c5212c5222c52223521235222352223522235222352223525185001c5151c555
010e00000d534195312552523525205202052521510215152c5202c5212a5212a5112752127521285202852128521285112f5202f5212f5222f5222752127522275221b5110f5110351117725177251571514715
010e000015715157151c3151572515725157251573515735157452c315157352c31515725157252c3121571515715157151c315157251572515725157351573515745157352c3152c31217725177251771517715
010e000007645180001800018000006650000000000056350864518000180001800001665000000000006635076451f1002d3152d315006651f1002b312056350864524100263152631501665263152831206635
010e00001c5401c5401c5401c5311f5401f5451a5401a5411a5421a5421c5401c5411c53510505195401954119541195311554015542105401054110541105421054210531105331450014500145001554017545
010e00000464504021040252050004665040210402504625046450402104025205000466504021040250462504645040210402520500046650402104025046250464504021040252050004665040210402504625
010e00000c0200c0210c0220c01517000170000b0200b0210b0210b0210b0220b0220b01504000090200902109021090210902109025090200901509000090250902009021090152050009020090210901520500
010e00000502005021050220501517000170000702007021070210702107022070150400004000090200902109021090210902109025090200901509000090250902009021090152050009020090210901520500
010700001c5001c5011c5011c5011f5001f5051a5001a5011a5021a5021c5001c5011c50510505195001950119501195011550015501105011050110501105021050210501105031450014500145001550017505
010e0000185401854118541185311c5401c5451a5401a5411a5421a5311c5401c5411c5451050519542195411954119541195411954119541195421954219542195421953119533155001550014500195401a545
010e0000185401854118541185311754017545135401354113542135411054010541105351050517542175411754117541155401554115541155421554215542155411553115533155001550014500195001a500
010e00000664506021060210601106665170000d0250663506645060210602206015066650400006025066350664506021060210601506665060250d025066350664506021060152050006665060210601506635
010e0000056450502105022050150566517000050250563505645050210502205015056650400005025056350564505021050210501505665050250c025056350564505021050152050005665050210501505635
010e00002a705287052a7152c7252d7252f725317353473536745287352a7352c7252d7252372525715287152a715287152a7152c7252d7252f725317353473536745287352a7352c7252d725237252571528715
010e000021104211052102521015201042002520025200151e1041e1041e0251e0151c1041c0251c0251c01519715197151971519725197251972519735197351974519735197351972519725197251971519715
010e00002970528705297152b7252d7253072532735347353574528735297352b7252d7252472526715287152971528715297152b7252d7253072532735347353574528735297352b7252d725247252671528715
010e0000187151871521025210151f1041f0251f0251f0151d1041d1041d0251d0151c1041c0251c0251001518715187151871518725187251872518735187351874518735187351872518725187251871518715
010e0000096450902109022090150966517000090250963509645090210902209015096650400009025096350864508021080210801508665080250f025086350864508021080152050008665080210801508635
010e000018715187151c1251c1251c1211c111181251a1251c1241c1211c1211d1211d1211d1211c1201c1151b1201b1211b1211b1211b1221b1221b1221b1221b1221b1221b1221b1211b1211b1131b1251a125
010e00002d7052c7052d7152f7253072532725347253672538725397253b7253c7252f7253072532715347153371532715337153c7153a7153771533725357253e7253c7253a725377153f7153e7153c7153a715
010e0000181321812218121151202112315113151211512518130181221812215120211231511315120151252112021121211211f1211f1211f1251c1221c125181201812118123181051a1201a1211a1251a100
010e00001c7151b7151c7151d715207152171523725247252772528725297252c7252d7352f7353073533735347353573538725397253b7253c7253f7253c7252f72530725337252372524715277152471523715
010e00001c1211c1211c1211c1211c1211c1211c1221c1221c1221c1221c1221c1221c1221c1221c1211c12110121101211012210122101221012210126101261012614126101261411610111041110411315100
011500001750523531235252352523535235252352523535235252352523535235002f5212f5352f5252f5252f5352f5252f5352f52123523175030b5031c5001c500005001c5001c5001c500005001c50000500
010e000007645180001800018000006650000000000056350864518000180001800001665000000000006635076451f1002d3152d315006651f1002f312056350864524100263152631501665263152831206635
010e0000237162871623716287162372628726237262872623736287362373628736207462574620746257462073625736207362573620726257262072625726277162c726277362c746277432c706277062c706
010e00000871714717087171471708717147170872714727087271473708737147370974715747097471574709737157370973715727097271572709717157170403104031040310403510700007001070000700
010e0000287162d716287162d716287262d726287262d726287362d736287362d7362a7462f7462a7462f7462a7362f7362a7362f7362a7262f7262a7262f726277162c726277362c746277432c706277062c706
010e0000067171271706717127170671712717067271272706727127370673712737037470f747037470f747037370f737037370f727037270f727037170f7170403104031040310403504700007001070000700
010e00000764518000180001800000665000000000005635086451800018000180000166500000000000663507645180001800018000006650000000000056350864518000180001800001665000002352206635
010e00002853028532285312852527530275312753525535235302353223531235252053020532205312052300500005000050000500005000050000500005000050000500005000050000500005000050000500
010e00002c5202c5222c5212c5252a5302a5312a53528535275302753227531275252353023532235312352300500005000050000500005000050000500005000050000500005000050000500005000050000500
010e00000010000100001000010000100001000010028105041001c10010131101251013512125171201712500100001000010000100001000010000100001000010000100001000010000100001000010000100
010e00002503025021250212803128021280132f0202f0252c0252f0202f0222f0222f0212f0112f0130c0002303023021230212803128021280132f0202f0252c0252f0202f0222f0222f0212f0112f01300000
010e00002103021021210212803128021280132f0202f0252c0252f0202f0222f0222f0212f0112f013000002300023000230002800028000280002f0002f0002c0002f0002f0002f0002f0002f0002f00000000
010e00001871518715187151872518725187251873518735187451873518735187351872518725197151b7151c7151c7151c7151c7251c7251c7251c7351c7351b7411b7351b7351b7351b723187051870518705
010e000007645090150901509025006650902509035056350864509035090350903501665090250901506635076450d0150d0150d025006650d0250d0350563508645140211402514025016650b0053421306635
010e00002403024021240212803128021280132d0202d0252a0252c0202c0222c0222c0212c0152a0212a0252802028022280222802228013280012a02728027270202702127021270132712524115201251c115
010e00003102131022310252f0202f0222f0222802028022270202702127013270202702127011280222802100000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000028510285122851227521275122751223520235152052220511205131b5211b5211b5111c5321c52200000000000000000000000000000000000000000000000000000000000000000000000000000000
010700002605426004260540000426054000042605400004260540000426054000042605400004260540000426054000042605400004260540000400350073510735106351053510335103351033510335103355
00120000107501c7501c7501c75004700047000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001001510015100151001510015100151002510025100351002510025100251001510015100151001510015100151001510015100151001510025100251003510025100251002510015100151001510015
010e0000285001c514285212851527512275002551200000205220000021512000001e522000022051200000285001c514285212851527512000002551200002205221e511205221e515205221e5112052220515
0105000000010007030a6000a6000b0000b0000b0000b0000b0000b0000b000033500335103351033510335103351043510535105351063510735107351073510735107351073510735107351073510735107351
010a00001c5541c5501c5501555415550155501555015555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 40004244
00 40014108
01 40010203
00 40010203
00 40050604
00 40010207
00 4901090a
00 4b0b0203
00 4b0b0203
00 40050604
00 4b0b0207
00 4901090a
00 490c0e11
00 400d0f12
00 490c1411
02 4b0d1013
00 40551757
01 40551729
00 40001816
00 4100191b
00 40001816
00 4100191c
00 40151816
00 412a191b
00 40151618
00 4100191c
00 41201d1f
00 41221e21
00 41242325
00 41261e21
02 41281727
00 5a005769
00 1a002932
01 5a2f2b2c
00 1a003032
00 5a2f2d2e
00 1a003132
00 5a2f2b2c
00 1a003032
00 5a2f2d2e
00 1a003938
00 5a0d0f33
00 1a0c0e34
00 5a0d0f33
00 1a0c0e38
00 5a0d0f33
00 1a0c1434
00 5a0d1033
00 5a363537
00 1a0d0f20
00 1a0d0f29
00 5a0d0f20
00 5a0c0f0e
00 1a0d0f0e
02 1a0d320e
01 1a3c023d
00 1a3c0e3d
00 413c063d
00 1a3c023d
00 1a3c143d
02 413c063d

