#!/bin/bash
# Generates a palette-only sun wallpaper.
#   usage: make-wallpaper.sh out.png                 the wallpaper
#          make-wallpaper.sh out.png --sun-layer     only the sun, on a transparent canvas (see below)
# Layers, bottom to top: the sky, the sun's halo, its ring and the disc, then the horizon haze and the ground, then
# film grain.
set -e
W=3840; H=2160; CX=1920; CY=940; R=600
T=$(mktemp -d)
D=$((R*2))

# 1. sky: scorched brown glow fading to the background black
magick -size ${W}x${H} -define gradient:center=${CX},${CY} -define gradient:radii=2300,1600 \
  radial-gradient:'#5A1F0F-#1A0905' $T/sky.png

# 2. halo: a blurred disc used as an alpha mask (masks are forced to opaque gray first).
# Measured on the poster, in rings just outside the sun's rim: below the sun's centre line the glow is strong and
# warm (luminance 55-71, colours like #F11B0F and #A52708), and above it there is almost none, the rim being sharp
# against dark cloud (luminance 16-43). So the halo is a blurred disc, scaled up, with a horizon factor that fades
# it out above the centre line, leaving HALO_TOP of it. The poster's horizon is broken up by clouds; on a clean
# wallpaper a sharp edge reads as an artifact, so the glow comes in gradually, over 0.6 of a radius.
# Version 1 was a symmetric halo: '#E91A02', strength 1.0, no horizon factor (45 all round, double the poster's
# top and under its sides).
HALO_COLOR='#F0300C'; HALO_STRENGTH=1.4; HALO_TOP=0.2
magick -size ${W}x${H} xc:black -fill white -draw "circle ${CX},${CY} ${CX},$((CY-R))" \
  -blur 0x300 -alpha off $T/halo_blur.png
magick -size 1x${H} xc: -fx "tt=min(1,max(0,(j-($CY-0.30*$R))/(0.60*$R))); $HALO_TOP+(1-$HALO_TOP)*tt*tt*(3-2*tt)" \
  -scale ${W}x${H}! -colorspace Gray $T/horizon.png
magick $T/halo_blur.png $T/horizon.png -compose Multiply -composite -evaluate Multiply $HALO_STRENGTH -alpha off $T/halo_mask.png
magick -size ${W}x${H} xc:"$HALO_COLOR" $T/halo_mask.png -alpha off -compose CopyOpacity -composite $T/halo.png

# 3. sun disc, coloured like the sun on the Sinners poster. Measured from the poster's sun: it runs yellow at
# the top, through orange, to a red-orange that stays about that red below the middle, and that is why the
# poster's yellow title reads against it. The colour depends mostly on height, and a little on the distance
# from the centre line (the sides run redder), so every pixel gets a position
#     t = (v + K*u^2 + 1) / 2        u, v = offsets from the disc centre in disc radii, v positive downward
# and takes its colour from a ramp built from the poster's measured colours at those heights.
# Version 1 of this disc was a radial gradient centred 70px above the middle, gold -> orange -> red at the rim:
#     ramp: '#E91A02-#FB7407' + '#FB7407-#F9BD06';  radial-gradient:white-black, center $R,$((R-70)), radii $((R+90)), -gamma 1.6
# which put gold behind the middle of the sun, where a yellow title cannot be read (1.9:1 contrast).
K=0.25
# Limb. On the poster the yellow does not run to the sun's edge. Measured at fine steps along its clean upper arcs
# (in radii from the centre): gold holds to 0.988, is orange at the rim (1.000), red-orange at 1.004, red at 1.008,
# then falls through dark red to the dark sky by 1.03. So the edge is an orange-to-red ring about 0.03 of a radius
# wide, darker than the yellow, with a dark outer glow. Inside the disc, over the last 1% of the radius, the colour
# blends toward the ring's starting orange (LIMB_COLOR), so the disc and the ring layer outside it (step 3b) meet
# exactly. Both exist only above the horizon: below it the poster's rim stays red and runs into the red glow.
# SINNERS_SUN_RING=0 turns the whole limb off, which tools/verify-sun.py uses to measure the bare disc's edge.
RING=${SINNERS_SUN_RING:-1}; LIMB_COLOR='#FD6E01'
magick \( -size 205x1 gradient:'#F9BD06-#FAB105' \) \( -size 118x1 gradient:'#FAB105-#FB7407' \) \
  \( -size 61x1 gradient:'#FB7407-#FA5309' \) \( -size 102x1 gradient:'#FA5309-#FA4606' \) \
  \( -size 102x1 gradient:'#FA4606-#EE3E08' \) \( -size 128x1 gradient:'#EE3E08-#EA3A10' \) \
  \( -size 308x1 xc:'#EA3A10' \) +append $T/ramp.png
magick -size ${D}x${D} xc:black -fx "xx=(i-$R)/$R; yy=(j-$R)/$R; pos=(yy+$K*xx*xx+1)/2; max(0,min(1,pos))" \
  -colorspace Gray -depth 16 $T/disc_t.png
magick $T/disc_t.png $T/ramp.png -clut -depth 16 $T/disc_raw.png
magick -size ${D}x${D} xc:black -fx "xx=(i-$R)/$R; yy=(j-$R)/$R; rw=min(1,max(0,(hypot(xx,yy)-0.990)/0.010)); rw=rw*rw*(3-2*rw); hz=min(1,max(0,((j+$CY-$R)-($CY-0.30*$R))/(0.60*$R))); hz=hz*hz*(3-2*hz); $RING*rw*(1-hz)" \
  -colorspace Gray -depth 16 $T/limb_w.png
magick $T/disc_raw.png \( -size ${D}x${D} xc:"$LIMB_COLOR" \) $T/limb_w.png -fx "u[0]*(1-u[2])+u[1]*u[2]" -depth 16 $T/disc_limb.png
mv $T/disc_limb.png $T/disc_raw.png
# Texture: a faint grain with a little larger mottle, like the grain on the poster's sun. Measured on clean patches
# of it, the grain is 1-3% of the brightness at 1-3px scale on a sun 1424px across; here the sun is 667px across
# on the screen, so the grain is coarser to stay visible, and weaker than the raw measurement: at equal viewing
# size the poster's grain is averaged down by about half. It is seeded, so the wallpaper and the unlock screen's
# sun, which are built from these same lines, get exactly the same pixels.
TEX_GRAIN=0.3; TEX_MOTTLE=0.10
magick -seed 4242 -size ${D}x${D} xc:gray50 +noise Gaussian -colorspace Gray -blur 0x1.1 -auto-level $T/tex_grain.png
magick -seed 4343 -size ${D}x${D} xc:gray50 +noise Gaussian -colorspace Gray -blur 0x9 -auto-level $T/tex_mottle.png
magick $T/disc_raw.png $T/tex_grain.png $T/tex_mottle.png \
  -fx "u[0]*(1+$TEX_GRAIN*(u[1]-0.5)+$TEX_MOTTLE*(u[2]-0.5))" -depth 16 $T/disc_tex.png
mv $T/disc_tex.png $T/disc_raw.png
magick -size ${D}x${D} xc:black -fill white -draw "circle $R,$R $R,1" -blur 0x1.2 -alpha off $T/disc_mask.png
magick $T/disc_raw.png $T/disc_mask.png -alpha off -compose CopyOpacity -composite $T/disc.png

# 3b. the ring outside the disc: red-orange through red and dark red to a dark brown over 0.025 of a radius (the
# colours measured on the poster), and then that dark brown fading out over a further 0.045: the poster's red ring
# sits against near-black sky, and this tail supplies the darker surround. It starts under the disc's edge, and its
# alpha is cut by the same horizon factor as the halo, inverted, so it exists only against dark sky.
RC=$((2*R*108/100))
if [[ $RING == 1 ]]; then
  magick \( -size 164x1 gradient:'#FD6E01-#FD4501' \) \( -size 164x1 gradient:'#FD4501-#EE3001' \) \
    \( -size 164x1 gradient:'#EE3001-#BE2401' \) \( -size 164x1 gradient:'#BE2401-#8D1E01' \) \
    \( -size 164x1 gradient:'#8D1E01-#621801' \) \( -size 164x1 gradient:'#621801-#501602' \) \
    \( -size 40x1 gradient:'#501602-#401203' \) +append $T/ring_ramp.png
  magick -size ${RC}x${RC} xc:black -fx "rr=hypot(i-$((RC/2)),j-$((RC/2)))/$R; tt=min(1,max(0,(rr-1)/0.025)); tt" \
    -colorspace Gray -depth 16 $T/ring_t.png
  magick $T/ring_t.png $T/ring_ramp.png -clut -depth 16 $T/ring_rgb.png
  magick -size ${RC}x${RC} xc:black -fx "rr=hypot(i-$((RC/2)),j-$((RC/2)))/$R; ta=min(1,max(0,(rr-1)/0.07)); sm=min(1,max(0,(ta-0.12)/0.88)); ra=1-sm*sm*(3-2*sm); yy=j+($CY-$((RC/2))); hz=min(1,max(0,(yy-($CY-0.30*$R))/(0.60*$R))); hz=hz*hz*(3-2*hz); ra*(1-hz)" \
    -colorspace Gray -depth 16 $T/ring_a.png
  magick $T/ring_rgb.png $T/ring_a.png -alpha off -compose CopyOpacity -composite -depth 16 $T/ring.png
else
  magick -size ${RC}x${RC} xc:none $T/ring.png
fi

# 4. the horizon and the ground. Measured on the poster, down its left edge, where nothing stands over it (rows in
# the poster's 4096px height; luma is the colour's brightness, 0-255):
#   the sun's lower rim is at row 2870 and a red haze (colours like #E3170B, luma 50-65) fills the air above the
#   horizon, which is a soft step down at about row 2960, 3.6% of the sun's diameter below the sun's rim: the sun
#   just clears it. Below it the ground is a dark maroon that darkens steadily: #651111 just under the horizon,
#   #4B1010 at 160px, #270C0A at 280, #220908 at 400, #110604 from 660px on. Its texture is a multi-scale mottle, not
#   fine grit: the brightness varies by about 11% at 2px, 17% at 5px and 21-30% at 12px. Close to the horizon it is
#   streaked sideways, about 3:1, like dry earth seen at a grazing angle, and further down it is finer and softer, and
#   at the bottom nearly smooth. The poster's yellow sparks over the ground are left out: the Embers plugin has them.
# The ground is 27% of the height on the poster and here. Lengths below are in pixels of this 3840x2160 wallpaper
# (0.48 of the poster's, going by the sun, which is 2501px across there and 1200 here).
# What this wallpaper does differently from the poster, on purpose. On the poster the ground steps down from the haze to a
# darker, textured ground within about 60px, and its texture is the same size from the horizon to the bottom. Both read
# badly here: the step is a confusing seam, and with no change of scale the ground has no depth. So the ground's colours
# start at the haze's colour and darken over about twice the distance, and its texture is drawn in perspective, fine
# at the horizon and coarser toward the viewer, fading in out of the haze (see the texture below).
# ground_profile.png is one column of colour and opacity, copied across, built from the poster's measured colours (the
# median of its left edge, at each offset from the horizon; negative is above it), the ground's offsets spread out as
# just described. The haze has an opacity below 1, fading out into the sky overhead; the ground is opaque. Offsets are in
# pixels of this wallpaper; "r,g,b,a".
YH=1584                                    # the horizon: the sun's rim (CY+R = 1540) plus 3.6% of its diameter
STOPS="-520 150,20,9,0
-450 150,20,9,0.05
-390 150,20,9,0.14
-330 150,20,9,0.30
-280 150,20,9,0.50
-240 190,22,10,0.72
-200 215,23,11,0.88
-150 205,22,14,0.93
-100 186,21,17,0.94
-60 186,21,20,0.95
-30 167,23,22,0.95
0 156,22,21,1
45 125,20,19,1
95 97,18,17,1
150 80,17,15,1
200 66,15,13,1
260 48,12,10,1
320 36,10,8,1
400 30,9,6,1
500 26,9,5,1"
args=(); first=1; prev=""; poff=0
while read -r off rgba; do
  if (( first )); then args+=( \( -size ${W}x$((YH+off)) xc:"rgba($rgba)" \) ); first=0
  else args+=( \( -size ${W}x$((off-poff)) gradient:"rgba($prev)-rgba($rgba)" \) ); fi
  prev=$rgba; poff=$off
done <<< "$STOPS"
args+=( \( -size ${W}x$((H-YH-poff)) xc:"rgba($prev)" \) )
magick "${args[@]}" -append -depth 16 $T/ground_profile.png
# Dust in the haze: a slow, wide noise that raises and lowers the haze from place to place, so it is a cloudy glow and not a
# straight band. Only the faint tail of the haze moves (from 200px above the horizon up, fully by 330px): moving its
# bright body as well made a wavy ridge, like a graph, and the horizon has to stay straight. Its cells are
# 160px wide and 360px tall, so it undulates sideways: a noise that changed faster down the picture than the haze is
# displaced by would fold it over itself and print rings.
magick -seed 6404 -size $((W/160))x$((H/360)) xc:gray50 +noise Gaussian -colorspace Gray -auto-level \
  -filter Cubic -resize ${W}x${H}! -auto-level -depth 16 $T/gtex_dust.png
# Clouds in the haze's body: a wide, shallow noise (cells 100px by 43px) that brightens and dims it, so it is smoky and not
# a flat red. It changes the haze's brightness only, not its position.
magick -seed 6505 -size $((W/100))x$((H/50)) xc:gray50 +noise Gaussian -colorspace Gray -auto-level \
  -filter Cubic -resize ${W}x${H}! -auto-level -depth 16 $T/gtex_cloud.png
sdev() { magick "$1" -format '%[fx:standard_deviation]' info:; }
HAZE_WOBBLE=60; HAZE_CLOUD=0.11
SD_DUST=$(sdev $T/gtex_dust.png); SD_CLOUD=$(sdev $T/gtex_cloud.png)
shift() { echo "sh=$HAZE_WOBBLE*(u[$1]-0.5)/$SD_DUST*min(1,max(0,(($YH-200)-j)/130)); jj=min($H-1,max(0,j+sh));"; }   # shift DUST_IMAGE_INDEX
# The haze and the ground's colours, without the ground's texture: the haze's tail displaced by the dust, its body
# brightened and dimmed by the clouds (the clouds fade out over the 30px above the horizon, where the ground begins).
magick $T/ground_profile.png -alpha off $T/gtex_dust.png $T/gtex_cloud.png \
  -fx "$(shift 1) cl=1+min(1,max(0,($YH-j)/30))*$HAZE_CLOUD*(u[2]-0.5)/$SD_CLOUD; u[0].p{i,jj}*cl" -depth 16 $T/ground_base.png
magick $T/ground_profile.png -alpha extract $T/gtex_dust.png \
  -fx "$(shift 1) u[0].p{i,jj}" -depth 16 $T/ground_alpha.png

# The ground's texture, in perspective. The ground is a plane seen at a grazing angle, so something of a fixed size on it
# is smaller on the screen the nearer the horizon: dy rows below the horizon, its width is proportional to dy and its
# height to dy squared, so far away the texture is fine and flattened into streaks, and near the bottom it is
# coarse and rounder. Each pixel's place on the ground is
#       (i - W/2) / dy   across,        FOCAL / dy   away,                 (dy = rows below the horizon, plus a few)
# and four noise images, at four scales (0.3, 1, 5 and 20 times the coarse one; the first is for patches of soil near
# the viewer), are looked up there. An octave whose
# texels have shrunk below a pixel across has nothing left to show, so its weight falls to zero there (otherwise it
# would turn to a shimmer of aliasing, though see GT_FLOOR); and the whole texture fades in over the first 90px, so
# the ground emerges from the haze, with its colour and its contrast, instead of switching on.
# An octave whose texels are below a pixel across keeps GT_FLOOR of its weight: in a still picture that is not a
# shimmer, only fine grit, and the ground should get finer toward the horizon, not smooth. The whole texture fades in
# over the first 90px below the horizon.
# GT_TEXEL is the coarse octave's texel size at the bottom of the picture, in pixels across (its features are a few
# texels). BACK puts the camera's horizon BACK rows above the real one, which makes the perspective milder: at the
# horizon the texture is not infinitely fine, and at the sides of the picture it is sheared less, toward the vanishing
# point (with none, the big features at the bottom corners are smeared into diagonal streaks like a zoom blur).
# The rest of it is handled in oct(), by blending toward an un-slanted lookup at the far sides. FOCAL sets how flat the
# features are: a larger number lays them down flatter. The amplitudes are the variation each octave adds, as a
# fraction of the brightness. Measured on the poster the whole ground varies by about 20% (14% at 2-3px, 17-19% at 5px,
# 20-22% at 11px); here the octaves add up to about 0.28 where all show (near the viewer) and fall away with distance.
GT_TEXEL=44; FOCAL=800; BACK=90; GT_P=0.09; GT_C=0.20; GT_M=0.17; GT_F=0.15; GT_FLOOR=0.35
HG=$((H-YH)); DYREF=$((HG+BACK)); TXS=$(awk -v hg=$((HG+BACK)) -v t=$GT_TEXEL 'BEGIN{printf "%.4f", hg/t}')
tile_noise() { magick -seed $1 -size 1024x1024 xc:gray50 +noise Gaussian -colorspace Gray -virtual-pixel Tile -blur 0x$2 -auto-level -depth 16 "$3"; }
tile_noise 7001 1.4 $T/gt_p.png; tile_noise 7101 1.2 $T/gt_c.png; tile_noise 7202 1.0 $T/gt_m.png; tile_noise 7303 0.8 $T/gt_f.png
SD_P=$(sdev $T/gt_p.png); SD_C=$(sdev $T/gt_c.png); SD_M=$(sdev $T/gt_m.png); SD_F=$(sdev $T/gt_f.png)
# one octave: ground position (across, away) times its frequency, a lookup, then the weight for its texel size.
# oct IMAGE_INDEX FREQUENCY STANDARD_DEVIATION LETTER (the letter keeps the variable names apart; -fx dislikes digits in them)
# The lookup is blended, by wl (1 in the middle of the picture, falling to 0 toward the far sides), with one that does not
# slant: the same noise, read across at the width it would have at the bottom of the picture, whatever the depth.
# True perspective slants the features along lines running to the vanishing point, and at the sides of a wide picture
# that drags the coarse ones into diagonal streaks like a zoom blur. (Fading them out instead leaves a wedge of
# texture in the middle of the picture, which is worse.) The two lookups are independent noise, so the blend is
# divided by its own spread to keep the octave's strength.
oct() { echo "gx$4=$2*$TXS*(i-$((W/2)))/dy+512; gf$4=$2*$TXS*(i-$((W/2)))/$DYREF+512; gy$4=$2*$TXS*$FOCAL/dy; gn$4=(wl*(u[$1].p{gx$4,gy$4}-0.5)+(1-wl)*(u[$1].p{gf$4,gy$4}-0.5))/$3/sqrt(wl*wl+(1-wl)*(1-wl)); gw$4=min(1,max($GT_FLOOR,dy/($2*$TXS)-0.5));"; }
magick -size ${W}x${HG} xc:black -virtual-pixel Tile -interpolate Bilinear $T/gt_p.png $T/gt_c.png $T/gt_m.png $T/gt_f.png \
  -fx "dy=j+$BACK; ls=min(1,max(0,(abs(i-$((W/2)))/dy-1.4)/1.6)); wl=1-ls*ls*(3-2*ls);
       $(oct 1 0.3 $SD_P a) $(oct 2 1 $SD_C b) $(oct 3 5 $SD_M c) $(oct 4 20 $SD_F d)
       fade=min(1,max(0,(j-2)/90)); fade=fade*fade*(3-2*fade);
       gv=fade*($GT_P*gwa*gna+$GT_C*gwb*gnb+$GT_M*gwc*gnc+$GT_F*gwd*gnd);
       min(1,max(0,0.5+gv/4))" -depth 16 $T/gtex_ground.png
# the texture over the whole picture: neutral (0.5) above the horizon, the ground's below
magick -size ${W}x${YH} xc:'rgb(50%,50%,50%)' $T/gtex_ground.png -append -depth 16 $T/gtex_full.png
magick $T/ground_base.png $T/gtex_full.png -fx "u[0]*max(0,1+4*(u[1]-0.5))" -depth 16 $T/ground_rgb.png
magick $T/ground_rgb.png $T/ground_alpha.png -alpha off -compose CopyOpacity -composite -depth 16 $T/ground.png

# --sun-layer: the sun alone on a transparent canvas, for tools/sun-unlock.py. It is the same halo, disc and
# horizon haze as the wallpaper, built by the lines above, so the unlock screen's sun cannot drift from this one.
# The haze and the ground colour the sun's lower rim only, as if the sun were opaque, and the sun keeps its own alpha.
# (ImageMagick's Atop operator is not used: it scales the colour by the destination alpha, which dims the
# halo.) The sky and the grain are left out: the sky is the background, and the grain is random, so it
# could not line up anyway.
if [[ ${2:-} == --sun-layer ]]; then
  magick -size ${W}x${H} xc:none \
    $T/halo.png -compose Over -composite \
    $T/ring.png -gravity NorthWest -geometry +$((CX-RC/2))+$((CY-RC/2)) -compose Over -composite \
    $T/disc.png -gravity NorthWest -geometry +$((CX-R))+$((CY-R)) -compose Over -composite $T/sun.png
  magick $T/sun.png -alpha off $T/ground.png -gravity NorthWest -compose Over -composite $T/sun_color.png
  magick $T/sun.png -alpha extract $T/sun_alpha.png
  magick $T/sun_color.png $T/sun_alpha.png -alpha off -compose CopyOpacity -composite -depth 8 "$1"
  rm -rf $T
  exit 0
fi

magick -size ${W}x${H} xc:gray50 -attenuate 0.5 +noise Gaussian -colorspace Gray -alpha set -channel A -evaluate set 14% +channel $T/grain.png
magick $T/sky.png \
  $T/halo.png -compose Over -composite \
  $T/ring.png -gravity NorthWest -geometry +$((CX-RC/2))+$((CY-RC/2)) -compose Over -composite \
  $T/disc.png -gravity NorthWest -geometry +$((CX-R))+$((CY-R)) -compose Over -composite \
  $T/ground.png -gravity NorthWest -geometry +0+0 -compose Over -composite \
  $T/grain.png -compose Overlay -composite \
  -depth 8 -colorspace sRGB "$1"
rm -rf $T
