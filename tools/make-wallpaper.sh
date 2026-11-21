#!/bin/bash
# Generates a palette-only sun wallpaper.
#   usage: make-wallpaper.sh out.png                 the wallpaper
#          make-wallpaper.sh out.png --sun-layer     only the sun, on a transparent canvas (see below)
# Layers, bottom to top: the sky, with its clouds, the sun's halo, its ring and the disc, then the horizon haze and the ground, then
# film grain.
set -e
W=3840; H=2160; CX=1920; CY=940; R=600
T=$(mktemp -d)
D=$((R*2))
# SINNERS_GROUND=0 leaves out the haze, the ground and the farmhouse below the sun. The sun layer is built that way: the
# unlock screen does not carry them (it only needs the sun to be in the same place, size and colours), and
# tools/verify-sun.py builds the wallpaper it compares against that way.
GROUND=${SINNERS_GROUND:-1}; if [[ ${2:-} == --sun-layer ]]; then GROUND=0; fi

# 1. sky: scorched brown glow fading to the background black
magick -size ${W}x${H} -define gradient:center=${CX},${CY} -define gradient:radii=2300,1600 \
  radial-gradient:'#5A1F0F-#1A0905' $T/sky.png

# 1b. clouds. Measured on the poster, in the clean sky beside the head (top corners, and the sides below them): dark cloud is
# about as dark as this sky's far edge (rgb 30,10,5), the gaps between clouds show a saturated red glow, 2 to 3 times
# brighter (rgb 95-160, 25-35, 4), and the clouds are big soft masses: their brightness varies by 10-12% at 20-50px
# of this wallpaper and only 2-5% at 3-7px, with ragged tops and an orange light along their edges where the sun reaches
# them. They are in the upper sky, and the horizon haze takes over below. They are cut from fractal noise stretched
# CLOUD_ASPECT times wider than tall, in five octaves, as dark bodies over a lit red sky. Subtle on purpose: the
# strengths below are well under the poster's. This is the sky only, so the halo, ring and disc go over it: the glow
# beside the sun lights the clouds there, and the sun's rim stays sharp against a dark cloud, as on the poster.
# SINNERS_CLOUDS=0 leaves them out.
CLOUDS=${SINNERS_CLOUDS:-1}
CLOUD_ASPECT=3.2; CLOUD_LIT=0.50; CLOUD_RIM=0.40; CLOUD_DARK=0.36
if [[ $CLOUDS == 1 && ${2:-} != --sun-layer ]]; then
  # Built at a quarter of the size, and scaled up: the clouds are soft, and it is four times faster.
  # the field: five noises, each looked up smoothly at its own size (the number is the size of its features, in pixels of the
  # whole wallpaper, across; they are CLOUD_ASPECT times shorter than that), each divided by its own spread and weighted;
  # the sum is stored as 0.5 + 0.15 per unit, so that 16 bits hold it with room.
  CW=$((W/4)); CH=$((H/4)); k=0; fargs=(); fw=()
  for spec in "8101 700 1.00" "8202 350 0.85" "8303 175 0.55" "8404 90 0.25" "8505 45 0.10"; do
    read -r cseed csize cweight <<< "$spec"
    crows=$(awk -v h=$H -v a=$CLOUD_ASPECT -v c=$csize 'BEGIN{printf "%d", h*a/c+3}')
    magick -seed $cseed -size $((W/csize+3))x${crows} xc:gray50 +noise Gaussian -colorspace Gray -depth 16 \
      -filter Cubic -resize ${CW}x${CH}! -depth 16 $T/cloud_$k.png
    fargs+=( $T/cloud_$k.png ); fw+=( "$cweight/$(magick $T/cloud_$k.png -format '%[fx:standard_deviation]' info:)" ); k=$((k+1))
  done
  cnorm=$(awk 'BEGIN{printf "%.4f", sqrt(1+0.7225+0.3025+0.0625+0.01)}')
  magick "${fargs[@]}" -fx "0.5+0.15*( (u[0]-0.5)*${fw[0]} + (u[1]-0.5)*${fw[1]} + (u[2]-0.5)*${fw[2]} + (u[3]-0.5)*${fw[3]} + (u[4]-0.5)*${fw[4]} )/$cnorm" \
    -depth 16 $T/cloud_field.png
  # cover: 1 inside a dark cloud, 0 in the clear, with a wide, soft, ragged edge; fading out toward the horizon, from row
  # 650 to 1250 (the haze begins about 500px above the horizon).
  magick $T/cloud_field.png -fx "
    ff=(u[0]-0.5)/0.15; cc=min(1,max(0,(ff-0.05)/1.7)); cc=cc*cc*(3-2*cc);
    wz=1-min(1,max(0,(j*4-650)/600)); wz=wz*wz*(3-2*wz); cc*wz" -depth 16 $T/cloud_cover.png
  # the cloud's body is darker than the sky: a multiplier (1 in the clear)
  magick $T/cloud_cover.png -evaluate Multiply -$CLOUD_DARK -evaluate Add 1 -filter Cubic -resize ${W}x${H}! -depth 16 $T/cloud_dark.png
  # the gaps are lit with a red glow, scaled by how clear it is (the cover is already faded out toward the horizon, and so
  # the glow is, through the factor below, which is 1 where the cover fade has not begun: it is made from the same wz)
  magick $T/cloud_cover.png -fx "
    wz=1-min(1,max(0,(j*4-650)/600)); wz=wz*wz*(3-2*wz); (wz-u[0])*$CLOUD_LIT" -depth 16 -filter Cubic -resize ${W}x${H}! -depth 16 $T/cloud_lit.png
  # the rim: a thin orange light along the lower edge of a cloud, the side facing the sun: where the cover above a point is
  # more than at the point itself
  magick $T/cloud_cover.png \( +clone -roll +0+3 \) -fx "max(0,u[1]-u[0])*$CLOUD_RIM" -depth 16 -filter Cubic -resize ${W}x${H}! -depth 16 $T/cloud_rim.png
  magick $T/sky.png $T/cloud_dark.png -compose Multiply -composite \
    \( -size ${W}x${H} xc:'rgb(78,16,3)' $T/cloud_lit.png -compose Multiply -composite \) -compose Plus -composite \
    \( -size ${W}x${H} xc:'rgb(150,44,5)' $T/cloud_rim.png -compose Multiply -composite \) -compose Plus -composite \
    -depth 16 $T/sky_c.png
  mv $T/sky_c.png $T/sky.png
fi

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

if [[ $GROUND == 1 ]]; then
# 4. the horizon and the ground. Measured on the poster, down its left edge, where nothing stands over it (rows in
# the poster's 4096px height; luma is the colour's brightness, 0-255):
#   the sun's lower rim is at row 2870 and a red haze (colours like #E3170B, luma 50-65) fills the air above the
#   horizon, which is a soft step down at about row 2960, 3.6% of the sun's diameter below the sun's rim: the sun
#   just clears it. Below it the ground is a dark maroon that darkens steadily: #651111 just under the horizon,
#   #4B1010 at 160px, #270C0A at 280, #220908 at 400, #110604 from 660px on. Its texture, measured again later as the
#   band-pass energy at five scales (0.7, 1.5, 3, 8 and 20px of this wallpaper, as a percentage of the mean brightness, at 90,
#   270 and 500px below the horizon): 7, 6, 4, 4, 5 near the horizon; 9, 8, 6, 4, 6 in the middle; and 18, 18, 15, 10, 7 low
#   down. So it is isotropic grit, strongest at the finest scales, and growing stronger toward the bottom as the ground
#   darkens: not smooth, and not streaked (an earlier reading, of a coarser measurement, said it was). The poster's yellow sparks over the ground are left out: the Embers plugin has them.
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
150 76,17,15,1
200 60,14,12,1
260 45,11,9,1
320 36,10,8,1
400 28,8,6,1
500 20,7,4,1"
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
#       (i - W/2) / dy   across,        ASPECT * ln(dy)   away,              (dy = rows below the horizon, plus a few)
# and four noise images, at four scales (0.3, 1, 5 and 20 times the coarse one; the first is for patches of soil near
# the viewer), are looked up there. An octave whose
# texels have shrunk below a pixel across has nothing left to show, so its weight falls to zero there (otherwise it
# would turn to a shimmer of aliasing, though see GT_FLOOR); and the whole texture fades in over the first 90px, so
# the ground emerges from the haze, with its colour and its contrast, instead of switching on.
# An octave whose texels are below a pixel across keeps GT_FLOOR of its weight: in a still picture that is not a
# shimmer, only fine grit, and the ground should get finer toward the horizon, not smooth.
# GT_TEXEL is the coarse octave's texel size at the bottom of the picture, in pixels across (its features are a few
# texels). BACK puts the camera's horizon BACK rows above the real one, which makes the perspective milder: at the
# horizon the texture is not infinitely fine, and at the sides of the picture it is sheared less, toward the vanishing
# point (with none, the big features at the bottom corners are smeared into diagonal streaks like a zoom blur).
# The rest of it is handled in oct(), by blending toward an un-slanted lookup at the far sides. ASPECT sets how flat the
# features are, the same at every depth: width over height, so a larger number lays them down flatter. The amplitudes are the variation each octave adds, as a
# fraction of the brightness. Measured on the poster the whole ground varies by about 20% (14% at 2-3px, 17-19% at 5px,
# 20-22% at 11px); here the octaves add up to about 0.28 where all show (near the viewer) and fall away with distance.
# What made an earlier version read as a game texture, and what replaced it. Its features were stretched sideways into
# long streaks near the horizon (the flattening grew without limit there, up to 9 to 1) and nothing in it was finer than
# a few pixels, so it looked like smeared water or a low-resolution tile. The poster's ground is the opposite: isotropic
# grit, with much more at 1-3px than at 20px, and more of it, not less, toward the bottom where the ground is darkest.
# So now: features are flattened by a constant ASPECT (a logarithmic mapping of depth does that: they shrink with
# distance but keep their shape); a layer of fine grit, GRIT_FAR to GRIT_NEAR in strength, is added at the screen's own
# resolution, as the poster's film grain and dirt are; and sparse dark clods, CLOD in strength, break up the evenness.
GT_TEXEL=44; ASPECT=1.5; BACK=90; GT_P=0.07; GT_C=0.15; GT_M=0.13; GT_F=0.11; GT_FLOOR=0.35
GRIT_FAR=0.17; GRIT_NEAR=0.36; CLOD=0.22; GRIT_SKEW=0.16
HG=$((H-YH)); DYREF=$((HG+BACK)); TXS=$(awk -v hg=$((HG+BACK)) -v t=$GT_TEXEL 'BEGIN{printf "%.4f", hg/t}')
tile_noise() { magick -seed $1 -size 1024x1024 xc:gray50 +noise Gaussian -colorspace Gray -virtual-pixel Tile -blur 0x$2 -auto-level -depth 16 "$3"; }
tile_noise 7001 1.4 $T/gt_p.png; tile_noise 7101 1.2 $T/gt_c.png; tile_noise 7202 1.0 $T/gt_m.png; tile_noise 7303 0.8 $T/gt_f.png
# fine grit at the screen's own resolution, and clods: dark blotches of 10-40px, thresholded so that most of the ground is
# untouched and the blotches have a soft edge but a definite shape
magick -seed 7404 -size ${W}x$((H-YH)) xc:gray50 +noise Gaussian -colorspace Gray -blur 0x0.55 -auto-level -depth 16 $T/gt_grit.png
magick -seed 7606 -size ${W}x$((H-YH)) xc:gray50 +noise Gaussian -colorspace Gray -blur 0x1.1 -auto-level -depth 16 $T/gt_speck.png
magick -seed 7505 -size ${W}x$((H-YH)) xc:gray50 +noise Gaussian -colorspace Gray -blur 0x9 -auto-level -depth 16 $T/gt_clod.png
SD_GRIT=$(sdev $T/gt_grit.png); SD_SPECK=$(sdev $T/gt_speck.png); SD_CLOD=$(sdev $T/gt_clod.png)
SD_P=$(sdev $T/gt_p.png); SD_C=$(sdev $T/gt_c.png); SD_M=$(sdev $T/gt_m.png); SD_F=$(sdev $T/gt_f.png)
# one octave: ground position (across, away) times its frequency, a lookup, then the weight for its texel size.
# oct IMAGE_INDEX FREQUENCY STANDARD_DEVIATION LETTER (the letter keeps the variable names apart; -fx dislikes digits in them)
# The lookup is blended, by wl (1 in the middle of the picture, falling to 0 toward the far sides), with one that does not
# slant: the same noise, read across at the width it would have at the bottom of the picture, whatever the depth.
# True perspective slants the features along lines running to the vanishing point, and at the sides of a wide picture
# that drags the coarse ones into diagonal streaks like a zoom blur. (Fading them out instead leaves a wedge of
# texture in the middle of the picture, which is worse.) The two lookups are independent noise, so the blend is
# divided by its own spread to keep the octave's strength.
oct() { echo "gx$4=$2*$TXS*(i-$((W/2)))/dy+512; gf$4=$2*$TXS*(i-$((W/2)))/$DYREF+512; gy$4=$2*$TXS*$ASPECT*ln(dy); gn$4=(wl*(u[$1].p{gx$4,gy$4}-0.5)+(1-wl)*(u[$1].p{gf$4,gy$4}-0.5))/$3/sqrt(wl*wl+(1-wl)*(1-wl)); gw$4=min(1,max($GT_FLOOR,dy/($2*$TXS)-0.5));"; }
magick -size ${W}x${HG} xc:black -virtual-pixel Tile -interpolate Bilinear $T/gt_p.png $T/gt_c.png $T/gt_m.png $T/gt_f.png $T/gt_grit.png $T/gt_clod.png $T/gt_speck.png \
  -fx "dy=j+$BACK; ls=min(1,max(0,(abs(i-$((W/2)))/dy-1.4)/1.6)); wl=1-ls*ls*(3-2*ls);
       $(oct 1 0.3 $SD_P a) $(oct 2 1 $SD_C b) $(oct 3 5 $SD_M c) $(oct 4 20 $SD_F d)
       fade=min(1,max(0,(j-2)/90)); fade=fade*fade*(3-2*fade);
       gz=0.85*(u[5]-0.5)/$SD_GRIT+0.50*(u[7]-0.5)/$SD_SPECK; gg=($GRIT_FAR+($GRIT_NEAR-$GRIT_FAR)*j/$HG)*(gz+$GRIT_SKEW*(gz*gz-1));
       gc=-$CLOD*max(0,(u[6]-0.5)/$SD_CLOD-0.6);
       gv=fade*($GT_P*gwa*gna+$GT_C*gwb*gnb+$GT_M*gwc*gnc+$GT_F*gwd*gnd+gg+gc);
       min(1,max(0,0.5+gv/4))" -depth 16 $T/gtex_ground.png
# the texture over the whole picture: neutral (0.5) above the horizon, the ground's below
magick -size ${W}x${YH} xc:'rgb(50%,50%,50%)' $T/gtex_ground.png -append -depth 16 $T/gtex_full.png
magick $T/ground_base.png $T/gtex_full.png -fx "u[0]*max(0,1+4*(u[1]-0.5))" -depth 16 $T/ground_rgb.png
magick $T/ground_rgb.png $T/ground_alpha.png -alpha off -compose CopyOpacity -composite -depth 16 $T/ground.png

# 5. the farmhouse: Bert and Joan's, a small wooden cabin with a low corrugated-tin roof that overhangs a long front porch,
# standing alone on the plain and centred under the sun. It is drawn here from its architecture, not traced or cut from the
# reference photo, which is a film still. Only the house: no car, horse or cow. Measured on the photo, with the door (about
# 2 m) as the scale: about 12 m long including the porch roof, a wall 3 m high to the eave and a ridge 5.6 m high, so a
# roof that is a large part of what you see; a roof of corrugated tin in large sheets of very different tones, some patched,
# some gone, over a front porch with six thin posts; a clapboard gable end at the right with a small window; and a low
# foundation. How big, and where: from real distances, not by eye. At DIST_YD yards, seen with a FOV_DEG-degree view
# across the wallpaper's 3840px, from an eye EYE_M metres above the ground, a thing HOUSE_L_M long is F*L/Z pixels wide (F is
# the focal length in pixels, Z the distance), and the ground at its foot is F*EYE/Z pixels below the horizon: close to it,
# but not on it. The sun is behind the house, so it is dark: only the roof, which faces the sky, is faintly lit.
# Rendered, not just filled: a gradient of light (sky-light on top, gloom near the ground), the haze's light wrapping round
# its edges, a warm rim along the ridge and gable where the sun reaches it, slightly irregular edges, all of it graded to
# the scene's red light, and a veil of haze that thickens toward the ground, with a band of dust across its foot.
DIST_YD=200; FOV_DEG=40; EYE_M=1.7; HOUSE_X=$CX
HOUSE_F=$(awk -v fov=$FOV_DEG 'BEGIN{printf "%.2f", 1920/(sin(fov/2*3.14159265/180)/cos(fov/2*3.14159265/180))}')
HOUSE_Z=$(awk -v yd=$DIST_YD 'BEGIN{printf "%.2f", yd*0.9144}')
HOUSE_U=$(awk -v f=$HOUSE_F -v z=$HOUSE_Z 'BEGIN{printf "%.3f", f/z}')                 # pixels per metre at the house
HOUSE_BASE=$(awk -v yh=$YH -v f=$HOUSE_F -v z=$HOUSE_Z -v e=$EYE_M 'BEGIN{printf "%d", yh+f*e/z+0.5}')   # row of its foot
HOUSE_ROW=260; HOUSE_H=330                                                                  # the strip: the foot is HOUSE_ROW rows down
HOUSE_Y=$((HOUSE_BASE-HOUSE_ROW))
HOUSE_TOP_PX=$(awk -v u=$HOUSE_U 'BEGIN{printf "%.1f", 5.7*u}')                             # the ridge's height in pixels
# The drawing, in metres: x across from the centre, y up from the ground. fill r,g,b,a sets the colour of what follows;
# poly is a polygon; bar is a straight bar from one point to another, with a width. Painted in order: foundation, walls,
# porch, gable end, posts, roof. The roof's sheets, and the boards and battens, are generated below from a fixed
# sequence, so the picture is the same every time.
lcg_awk='function rnd(){ X=(X*1103515245+12345)%2147483648; return X/2147483648 }'
HOUSE_BATTENS=$(awk "$lcg_awk"' BEGIN{X=4711; x=-4.75; while (x<3.3) { x+=0.38+0.30*rnd(); if (x>3.3) break; if (x>-2.1 && x<-0.9) continue; if (x>1.1 && x<2.6) continue; printf "bar %.2f,0.32 %.2f,2.45 0.05\n", x, x+0.01*(rnd()-0.5) }}')
HOUSE_CLAP=$(awk 'BEGIN{for (k=0;k<14;k++) { y=0.62+0.2*k; if (y>3.0) break; printf "bar 3.5,%.2f 5.55,%.2f 0.03\n", y, y+0.14 }}')
HOUSE_ROOF=$(awk "$lcg_awk"' BEGIN{X=9091
  blx=-6.2; bly=2.9; tlx=-4.7; tly=5.25; trx=4.7; try_=5.6; brx=5.85; bry=3.55
  for (r=0; r<2; r++) { s0=(r==0?0:0.52); s1=(r==0?0.52:1); n=(r==0?15:13); off=(r==0?0:0.04)
    for (c=0; c<n; c++) { u0=c/n+off*(c>0); u1=(c+1)/n+(c<n-1?off:0)
      q=rnd(); tone=0.55+0.9*q*q; if (rnd()<0.07) tone=0.18; if (rnd()>0.93) tone=1.55
      for (k=0;k<4;k++) { us=(k==0||k==3)?u0:u1; ss=(k<2)?s0:s1
        lx=blx+ss*(tlx-blx); ly=bly+ss*(tly-bly); rx=brx+ss*(trx-brx); ry=bry+ss*(try_-bry)
        PX[k]=lx+us*(rx-lx); PY[k]=ly+us*(ry-ly) }
      printf "fill %d,%d,%d,1\npoly %.2f,%.2f %.2f,%.2f %.2f,%.2f %.2f,%.2f\n", 54*tone, 10*tone, 7*tone, PX[0],PY[0],PX[1],PY[1],PX[2],PY[2],PX[3],PY[3] } } }')
HOUSE="fill 12,3,2,1
poly -6.0,0.14 5.7,0.14 5.7,0.32 -6.0,0.32
poly -5.8,0 -5.58,0 -5.58,0.16 -5.8,0.16
poly -4.2,0 -3.98,0 -3.98,0.16 -4.2,0.16
poly -2.4,0 -2.18,0 -2.18,0.16 -2.4,0.16
poly -1.0,0 -0.78,0 -0.78,0.16 -1.0,0.16
poly 0.7,0 0.92,0 0.92,0.16 0.7,0.16
poly 2.3,0 2.52,0 2.52,0.16 2.3,0.16
poly 3.9,0 4.12,0 4.12,0.16 3.9,0.16
poly 5.3,0 5.52,0 5.52,0.16 5.3,0.16
fill 18,3,2,1
poly -5.0,0.32 3.5,0.32 3.5,3.5 -5.0,3.05
fill 13,2,2,1
$HOUSE_BATTENS
fill 5,1,1,1
poly -2.0,0.32 -1.0,0.32 -1.0,2.5 -2.0,2.5
poly 1.2,1.1 2.4,1.1 2.4,2.3 1.2,2.3
fill 15,3,2,1
bar 1.8,1.1 1.8,2.3 0.05
bar 1.2,1.7 2.4,1.7 0.05
fill 6,1,1,1
poly -5.0,2.4 3.5,2.8 3.5,3.5 -5.0,3.05
fill 38,8,6,1
poly 3.5,0.32 5.55,0.46 5.55,3.55 4.7,5.3 3.5,3.5
fill 14,2,2,1
$HOUSE_CLAP
fill 5,1,1,1
poly 4.3,1.4 5.0,1.5 5.0,2.4 4.3,2.3
fill 14,3,2,1
poly -5.3,0.32 -5.13,0.32 -5.09,3.0 -5.26,3.0
poly -3.62,0.32 -3.45,0.32 -3.46,3.05 -3.63,3.05
poly -2.07,0.32 -1.9,0.32 -1.87,3.07 -2.04,3.07
poly -0.4,0.32 -0.23,0.32 -0.25,3.05 -0.42,3.05
poly 1.37,0.32 1.54,0.32 1.57,3.08 1.4,3.08
poly 3.25,0.32 3.42,0.32 3.41,3.1 3.24,3.1
$HOUSE_ROOF
fill 10,2,2,1
bar -6.2,2.9 -1.5,3.12 0.2
bar -1.5,3.12 5.85,3.55 0.2
bar 4.7,5.6 5.85,3.55 0.2
fill 12,3,2,1
bar -4.7,5.25 0.0,5.37 0.15
bar 0.0,5.37 4.7,5.6 0.15
fill 255,120,34,0.5
bar -4.7,5.3 0.0,5.42 0.05
bar 0.0,5.42 4.7,5.65 0.05
bar 4.7,5.65 5.88,3.6 0.05"
# convert the drawing to pixels, and paint it
args=()
while read -r kind rest; do
  case $kind in
    fill) IFS=, read -r fr fg fb fa <<< "$rest"; args+=( -fill "rgba($fr,$fg,$fb,$fa)" ) ;;
    poly) args+=( -draw "polygon $(awk -v u=$HOUSE_U -v hx=$HOUSE_X -v hr=$HOUSE_ROW '{for(i=1;i<=NF;i++){split($i,c,","); printf "%.1f,%.1f ", hx+c[1]*u, hr-c[2]*u}}' <<< "$rest")" ) ;;
    bar)  args+=( -draw "polygon $(awk -v u=$HOUSE_U -v hx=$HOUSE_X -v hr=$HOUSE_ROW '{split($1,a,","); split($2,b,","); w=$3*u; if (w<1) w=1; x1=hx+a[1]*u; y1=hr-a[2]*u; x2=hx+b[1]*u; y2=hr-b[2]*u; dx=x2-x1; dy=y2-y1; l=sqrt(dx*dx+dy*dy); nx=-dy/l*w/2; ny=dx/l*w/2; printf "%.1f,%.1f %.1f,%.1f %.1f,%.1f %.1f,%.1f", x1+nx,y1+ny, x2+nx,y2+ny, x2-nx,y2-ny, x1-nx,y1-ny}' <<< "$rest")" ) ;;
  esac
done <<< "$HOUSE"
# its shadow, thrown toward the viewer across the ground and fading with distance; it goes under the house
magick -size ${W}x${HOUSE_H} xc:none -fill 'rgba(6,1,1,0.30)' \
  -draw "polygon $(awk -v u=$HOUSE_U -v hx=$HOUSE_X -v hr=$HOUSE_ROW 'BEGIN{printf "%.1f,%.1f %.1f,%.1f %.1f,%.1f %.1f,%.1f", hx-5.9*u,hr, hx+6.0*u,hr, hx+6.7*u,hr+0.55*u, hx-6.6*u,hr+0.6*u}')" \
  -blur 0x2.5 $T/house_shadow.png
magick -size ${W}x${HOUSE_H} xc:none "${args[@]}" -depth 16 $T/house_body.png
# Light and weathering. The brightness falls off from the top (sky-light) to the ground (gloom), varies a little from place
# to place, and streaks with rain (noise stretched 14 times taller than it is wide); each noise is divided by its own spread,
# so the numbers are the variation they add, as a fraction of the brightness. Then the colour is graded into the scene's
# red light: lit by that glow, everything is a darker version of the haze, so green and blue are held down.
magick -seed 9101 -size ${W}x${HOUSE_H} xc:gray50 +noise Gaussian -colorspace Gray -blur 0x1.4 -auto-level -depth 16 $T/house_n1.png
magick -seed 9202 -size ${W}x$((HOUSE_H/14)) xc:gray50 +noise Gaussian -colorspace Gray -blur 0x0.7 -auto-level \
  -filter Cubic -resize ${W}x${HOUSE_H}! -auto-level -depth 16 $T/house_n2.png
magick -seed 9303 -size ${W}x${HOUSE_H} xc:gray50 +noise Gaussian -colorspace Gray -blur 0x1.0 -auto-level -depth 16 $T/house_n3.png
SD_H1=$(sdev $T/house_n1.png); SD_H2=$(sdev $T/house_n2.png); SD_H3=$(sdev $T/house_n3.png)
magick $T/house_body.png -alpha extract $T/house_alpha.png
magick $T/house_body.png -alpha off $T/house_n1.png $T/house_n2.png \
  -fx "rise=max(0,min(1,($HOUSE_ROW-j)/$HOUSE_TOP_PX)); light=0.72+0.40*rise*rise;
       u[0]*light*max(0,1+0.16*(u[1]-0.5)/$SD_H1+0.20*(u[2]-0.5)/$SD_H2)" \
  -channel G -evaluate multiply 0.62 +channel -channel B -evaluate multiply 0.55 +channel -depth 16 $T/house_rgb.png
# slightly irregular edges: the colour and the outline are both read from a point nudged by a pixel's worth of noise
magick -interpolate Bilinear $T/house_rgb.png $T/house_n1.png $T/house_n3.png \
  -fx "u[0].p{i+0.35*(u[1]-0.5)/$SD_H1, j+0.35*(u[2]-0.5)/$SD_H3}" -depth 16 $T/house_rgb_j.png
magick -interpolate Bilinear $T/house_alpha.png $T/house_n1.png $T/house_n3.png \
  -fx "u[0].p{i+0.35*(u[1]-0.5)/$SD_H1, j+0.35*(u[2]-0.5)/$SD_H3}" -depth 16 $T/house_alpha_j.png
magick $T/house_rgb_j.png $T/house_alpha_j.png -alpha off -compose CopyOpacity -composite -depth 16 $T/house_body.png
# Light wrap: the bright haze behind bleeds over the house's edge, a couple of pixels deep, all round it.
magick $T/house_alpha_j.png \( +clone -blur 0x2.0 \) -fx "min(1,u[0]*(1-u[1])*1.9)" -depth 16 $T/house_wrap_a.png
magick -size ${W}x${HOUSE_H} xc:'rgb(205,30,14)' $T/house_wrap_a.png -alpha off -compose CopyOpacity -composite \
  -channel A -evaluate multiply 0.55 +channel -depth 16 $T/house_wrap.png
# Rim light: with the sun behind it, a thin warm edge of light, strongest along the top, where the sun reaches it.
magick $T/house_alpha_j.png \( +clone -blur 0x1.4 \) \
  -fx "min(1,u[0]*(1-u[1])*1.7*(0.35+0.65*max(0,1-j/$HOUSE_ROW)))" -depth 16 $T/house_rim_a.png
magick -size ${W}x${HOUSE_H} xc:'rgb(255,118,34)' $T/house_rim_a.png -alpha off -compose CopyOpacity -composite \
  -channel A -evaluate multiply 0.45 +channel -depth 16 $T/house_rim.png
magick $T/house_body.png $T/house_wrap.png -compose Over -composite $T/house_rim.png -compose Over -composite -depth 16 $T/house_lit.png
# The veil of haze at 200 yards: thin at the top, thickening toward the ground, as it does with distance and dust, and
# the whole softened a little. The haze layer is laid over the colour only: the outline's alpha is put back after.
magick $T/house_lit.png -alpha extract $T/house_lit_a.png
magick -size ${W}x${HOUSE_H} xc:'rgb(190,24,12)' \
  \( -size ${W}x${HOUSE_H} xc:black -fx "0.10+0.26*max(0,min(1,(j-($HOUSE_ROW-1.9*$HOUSE_U))/(1.9*$HOUSE_U)))" -colorspace Gray \) \
  -alpha off -compose CopyOpacity -composite $T/house_veil.png
magick $T/house_lit.png -alpha off $T/house_veil.png -compose Over -composite $T/house_lit_a.png -alpha off -compose CopyOpacity -composite \
  -blur 0x0.9 -depth 16 $T/house_body.png
magick $T/house_shadow.png $T/house_body.png -compose Over -composite -depth 16 $T/house.png
# a low band of dust across its foot ties it to the ground
magick -size ${W}x${HOUSE_H} xc:none -fill 'rgba(170,24,16,0.10)' \
  -draw "ellipse $HOUSE_X,$((HOUSE_ROW+3)) $(awk -v u=$HOUSE_U 'BEGIN{printf "%.0f,%.0f", 8.5*u, 0.55*u}') 0,360" -blur 0x3 $T/house_dust.png
magick $T/house.png $T/house_dust.png -compose Over -composite -depth 16 $T/house.png
else
  YH=1; HOUSE_Y=0                           # nothing below the sun: empty layers, laid where they do nothing
  magick -size ${W}x${H} xc:none $T/ground.png
  magick -size ${W}x1 xc:none $T/house.png
fi

# --sun-layer: the sun alone on a transparent canvas, for tools/sun-unlock.py: the same halo, ring and disc as the
# wallpaper, built by the lines above, so the unlock screen's sun cannot drift from this one in position, size or colour.
# It has no haze, ground or farmhouse over its lower rim (the unlock screen is not meant to carry them, so it no longer
# matches the wallpaper there), and no sky or grain: the sky is the background, and the grain is random, so it could
# not line up anyway.
if [[ ${2:-} == --sun-layer ]]; then
  magick -size ${W}x${H} xc:none \
    $T/halo.png -compose Over -composite \
    $T/ring.png -gravity NorthWest -geometry +$((CX-RC/2))+$((CY-RC/2)) -compose Over -composite \
    $T/disc.png -gravity NorthWest -geometry +$((CX-R))+$((CY-R)) -compose Over -composite -depth 8 "$1"
  rm -rf $T
  exit 0
fi

magick -size ${W}x${H} xc:gray50 -attenuate 0.5 +noise Gaussian -colorspace Gray -alpha set -channel A -evaluate set 14% +channel $T/grain.png
magick $T/sky.png \
  $T/halo.png -compose Over -composite \
  $T/ring.png -gravity NorthWest -geometry +$((CX-RC/2))+$((CY-RC/2)) -compose Over -composite \
  $T/disc.png -gravity NorthWest -geometry +$((CX-R))+$((CY-R)) -compose Over -composite \
  $T/ground.png -gravity NorthWest -geometry +0+0 -compose Over -composite \
  $T/house.png -gravity NorthWest -geometry +0+$HOUSE_Y -compose Over -composite \
  $T/grain.png -compose Overlay -composite \
  -depth 8 -colorspace sRGB "$1"
rm -rf $T
