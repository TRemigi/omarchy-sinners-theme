#!/bin/bash
# Generates a palette-only sun wallpaper.
#   usage: make-wallpaper.sh out.png                 the wallpaper
#          make-wallpaper.sh out.png --sun-layer     only the sun, on a transparent canvas (see below)
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

# 4. ground: dark band rising from the bottom, like the posters' horizon
magick -size ${W}x$((H*42/100)) gradient:'rgba(13,5,3,0)-rgba(13,5,3,0.97)' $T/ground.png

# --sun-layer: the sun alone on a transparent canvas, for tools/sun-unlock.py. It is the same halo, disc and
# horizon haze as the wallpaper, built by the lines above, so the unlock screen's sun cannot drift from this one.
# The ground band darkens the sun's colour only, as if the sun were opaque, and the sun keeps its own alpha.
# (ImageMagick's Atop operator is not used: it scales the colour by the destination alpha, which dims the
# halo.) The sky and the grain are left out: the sky is the background, and the grain is random, so it
# could not line up anyway.
if [[ ${2:-} == --sun-layer ]]; then
  magick -size ${W}x${H} xc:none \
    $T/halo.png -compose Over -composite \
    $T/ring.png -gravity NorthWest -geometry +$((CX-RC/2))+$((CY-RC/2)) -compose Over -composite \
    $T/disc.png -gravity NorthWest -geometry +$((CX-R))+$((CY-R)) -compose Over -composite $T/sun.png
  magick $T/sun.png -alpha off $T/ground.png -gravity South -compose Over -composite $T/sun_color.png
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
  $T/ground.png -gravity South -compose Over -composite \
  $T/grain.png -compose Overlay -composite \
  -depth 8 -colorspace sRGB "$1"
rm -rf $T
