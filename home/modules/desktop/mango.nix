{ pkgs, ... }:

{
  wayland.windowManager.mango = {
    enable = true;

    autostart_sh = ''
      # see autostart.sh

      waybar >/dev/null 2>&1 &
      swaybg -i /home/bws428/Pictures/wallpapers/moss.jpg -m fill >/dev/null 2>&1 &
    '';
    settings = ''
      # see config.conf

      # Window colors
      focuscolor=0x005577ff
      shadowscolor= 0x000000ff

      # Keyboard options
      repeat_rate=25
      repeat_delay=600

      # Primary keybindings
      bind=SUPER,m,quit
      bind=SUPER,q,killclient
      bind=SUPER,Return,spawn,alacritty          
      bind=SUPER,space,spawn,rofi -show drun     
      bind=ALT,i,spawn,grim -l 0 -g "$(slurp)"   
      bind=SUPER,b,spawn,firefox                 
      bind=SUPER,s,spawn,signal-desktop --password-store="gnome-libsecret"         
      bind=SUPER,o,spawn,obsidian                

      # Reload Mango configuration
      bind=SUPER+SHIFT,r,reload_config

      # What do these DO exactly?
      bind=SUPER,i,incnmaster,+1
      bind=SUPER,p,incnmaster,-1

      # Window layouts
      bind=SUPER+SHIFT,f,togglefullscreen,
      bind=SUPER,f,togglefloating,
      bind=SUPER,t,setlayout,tile
      bind=SUPER,v,setlayout,vertical_grid
      bind=SUPER,c,setlayout,spiral
      bind=SUPER,x,setlayout,scroller
      bind=SUPER,n,switch_layout
      bind=SUPER,a,togglegaps

      # Window focus
      bind=SUPER,j,focusstack,next
      bind=SUPER,k,focusstack,prev
      bind=SUPER,h,focusdir,left
      bind=SUPER,l,focusdir,right

      # Swap windows
      bind=SUPER+SHIFT,k,exchange_client,up
      bind=SUPER+SHIFT,j,exchange_client,down
      bind=SUPER+SHIFT,h,exchange_client,left
      bind=SUPER+SHIFT,l,exchange_client,right

      # Mouse Button Bindings
      mousebind=SUPER,btn_left,moveresize,curmove
      mousebind=SUPER,btn_right,moveresize,curresize

      # Switch workspaces
      bind=SUPER,1,comboview,1
      bind=SUPER,2,comboview,2
      bind=SUPER,3,comboview,3
      bind=SUPER,4,comboview,4
      bind=SUPER,5,comboview,5
      bind=SUPER,6,comboview,6
      bind=SUPER,7,comboview,7
      bind=SUPER,8,comboview,8
      bind=SUPER,9,comboview,9

      # Window Smart Move
      bind=CTRL+SHIFT,k,smartmovewin,up
      bind=CTRL+SHIFT,j,smartmovewin,down
      bind=CTRL+SHIFT,h,smartmovewin,left
      bind=CTRL+SHIFT,l,smartmovewin,right

      # Layouts in Mango are per tag
      # Set all tags to tile by default
      tagrule=id:1,layout_name:tile
      tagrule=id:2,layout_name:tile
      tagrule=id:3,layout_name:tile
      tagrule=id:4,layout_name:tile
      tagrule=id:5,layout_name:tile
      tagrule=id:6,layout_name:tile
      tagrule=id:7,layout_name:tile
      tagrule=id:8,layout_name:tile
      tagrule=id:9,layout_name:tile

      # Gaps and borders
      animations=1
      gappih=5
      gappiv=5
      gappoh=5
      gappov=5
      borderpx=4
      no_border_when_single=0

      # Effect
      blur=0
      blur_layer=1
      blur_optimized=1
      blur_params_num_passes = 2
      blur_params_radius = 5
      blur_params_noise = 0.02
      blur_params_brightness = 0.9
      blur_params_contrast = 0.9
      blur_params_saturation = 1.2

      # Window shadows
      shadows = 1
      layer_shadows = 1
      shadow_only_floating=1
      shadows_size = 8
      shadows_blur = 12
      shadows_position_x = 0
      shadows_position_y = 0

      # Animations
      animations=1
      layer_animations=1
      animation_type_open=zoom
      animation_type_close=slide
      layer_animation_type_open=slide
      layer_animation_type_close=slide
      animation_fade_in=1
      animation_fade_out=1
      tag_animation_direction=1
      zoom_initial_ratio=0.3
      zoom_end_ratio=0.7
      fadein_begin_opacity=0.6
      fadeout_begin_opacity=0.8
      animation_duration_move=500
      animation_duration_open=400
      animation_duration_tag=350
      animation_duration_close=800
      animation_curve_open=0.46,1.0,0.29,1.1
      animation_curve_move=0.46,1.0,0.29,1
      animation_curve_tag=0.46,1.0,0.29,1
      animation_curve_close=0.08,0.92,0,1

      # Scroller Layout Setting
      scroller_structs=20
      scroller_default_proportion=0.8
      scroller_focus_center=0
      scroller_prefer_center=1
      edge_scroller_pointer_focus=1
      scroller_default_proportion_single=1.0
      scroller_proportion_preset=0.5,0.8,1.0

      # Gesturebind
      gesturebind=none,left,3,focusdir,left
      gesturebind=none,right,3,focusdir,right
      gesturebind=none,up,3,focusdir,up
      gesturebind=none,down,3,focusdir,down
      gesturebind=none,left,4,viewtoleft_have_client
      gesturebind=none,right,4,viewtoright_have_client
      gesturebind=none,up,4,toggleoverview
      gesturebind=none,down,4,toggleoverview
      bind=SUPER,0,toggleoverview

      '';
    };
}
