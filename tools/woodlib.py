"""Procedural weathered wood, used by make-bar-wood.py to draw the Sinners bar boards. Original work: no photograph is
sampled or traced. Needs numpy, scipy and Pillow (see make-bar-wood.py).

Everything is drawn at SS x the logical pixel size. A wood is three float arrays: v (tone, 0..1), hgt (relief) and a
crack mask."""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter, gaussian_filter1d, map_coordinates

SS = 2


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def anis(rng, h, w, sx, sy):
    """Unit-variance noise stretched sx along the grain (x) and sy across it (y)."""
    n = rng.standard_normal((h, w)).astype(np.float32)
    n = gaussian_filter(n, (sy, sx), mode="reflect")
    s = n.std()
    return n / (s if s > 1e-6 else 1.0)


def lut(stops):
    xs = np.array([s[0] for s in stops], dtype=np.float32)
    cs = np.array([s[1] for s in stops], dtype=np.float32)

    def f(v):
        v = np.clip(v, 0, 1)
        return np.stack([np.interp(v, xs, cs[:, i]) for i in range(3)], axis=-1).astype(np.float32)

    return f


# Tone ramps, dark (cracks, late-wood) to light (bleached early-wood). sRGB 0..1.
SILVER = lut([(0.0, (0.15, 0.135, 0.12)), (0.25, (0.42, 0.385, 0.34)), (0.55, (0.65, 0.61, 0.55)),
              (0.80, (0.78, 0.74, 0.68)), (1.0, (0.88, 0.85, 0.79))])
BROWN = lut([(0.0, (0.05, 0.035, 0.025)), (0.30, (0.17, 0.12, 0.085)), (0.60, (0.34, 0.26, 0.19)),
             (0.85, (0.48, 0.39, 0.30)), (1.0, (0.58, 0.49, 0.39))])
DARK = lut([(0.0, (0.035, 0.026, 0.02)), (0.30, (0.115, 0.088, 0.066)), (0.60, (0.23, 0.18, 0.14)),
            (0.85, (0.34, 0.28, 0.22)), (1.0, (0.43, 0.37, 0.30))])


def make_wood(h, w, rng, ring=(6.0, 13.0), crack_rate=1 / 520, knots=None, blotch=1.0, lift=0.0, crack_y=None):
    """Grain runs along x. Returns v, hgt, crack (all h x w float32)."""
    Y, X = np.mgrid[0:h, 0:w].astype(np.float32)
    hs = max(h, 40) / 68.0

    # knots: grain flows around them
    if knots is None:
        knots = int(rng.poisson(w / 2200.0))
    kn = []
    for _ in range(knots):
        kn.append((rng.uniform(0.08, 0.92) * w, rng.uniform(0.28, 0.72) * h,
                   rng.uniform(7.0, 12.0) * hs, rng.uniform(5.0, 8.0) * hs))
    warp = 7.0 * hs * anis(rng, h, w, 420, 40)
    knot = np.zeros((h, w), np.float32)
    kring = np.zeros((h, w), np.float32)
    for cx, cy, rx, ry in kn:
        dx, dy = X - cx, Y - cy
        fall = np.exp(-((dx / (5.5 * rx)) ** 2 + (dy / (3.4 * ry)) ** 2))
        warp += -0.55 * dy * fall
        r = np.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
        k = smooth(1.15, 0.65, r)
        knot = np.maximum(knot, k)
        kring += k * np.sin(r * 2 * np.pi * 2.4) * 0.5

    per = rng.uniform(*ring) * hs
    ph = (Y + warp) / per + 0.9 * anis(rng, h, w, 700, 50)
    rg = 0.5 + 0.5 * np.sin(2 * np.pi * ph)
    broken = smooth(-0.6, 0.7, anis(rng, h, w, 140, 5))     # grain lines fade in and out, as they do on eroded wood
    ridge = smooth(0.60, 1.0, rg) * (0.35 + 0.65 * broken)
    rg2 = 0.5 + 0.5 * np.sin(2 * np.pi * (ph * 2.9 + 0.7 * anis(rng, h, w, 300, 20)))
    ridge2 = smooth(0.78, 1.0, rg2) * 0.55

    band = anis(rng, h, w, 260, 7)
    low = anis(rng, h, w, 520, 16)
    mid = anis(rng, h, w, 90, 3.0)
    fib = anis(rng, h, w, 18, 1.3)
    hair = anis(rng, h, w, 6, 0.8)
    speck = anis(rng, h, w, 0.9, 0.9)
    # eroded pits: soft early-wood has been scoured out in short dashes along the grain
    pits = smooth(0.9, 2.2, anis(rng, h, w, 9, 0.8) + 0.5 * anis(rng, h, w, 40, 2.5))

    # cracks (checks): long, thin, wandering, tapered, mostly parallel to the grain
    cm = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(cm)
    n_cr = 0 if crack_rate <= 0 else max(1, int(round(w * crack_rate * rng.uniform(0.7, 1.4))))
    for _ in range(n_cr):
        x = rng.uniform(-60, w)
        if crack_y == "edges":       # keep checks above and below the lettering band
            y = (rng.uniform(0.07, 0.26) if rng.random() < 0.5 else rng.uniform(0.74, 0.93)) * h
        else:
            y = rng.uniform(0.08, 0.92) * h
        L = rng.uniform(140, 720) * (hs ** 0.5)
        steps = max(4, int(L / 5))
        yv = 0.0
        px, py = x, y
        for i in range(steps):
            x += 5.0
            yv = yv * 0.94 + rng.normal(0, 0.11) + (h * 0.5 - y) * 0.003
            y = float(np.clip(y + yv, 1, h - 2))
            wd = 0.8 + 1.8 * hs * np.sin(np.pi * i / steps) ** 0.8 * rng.uniform(0.7, 1.15)
            d.line([(px, py), (x, y)], fill=255, width=max(1, int(round(wd))))
            px, py = x, y
            if rng.random() < 0.012:      # short branch
                bx, by, bv = x, y, rng.normal(0, 0.9)
                for _ in range(int(rng.uniform(5, 18))):
                    bx += 4.0
                    by += bv
                    d.line([(bx - 4, by - bv), (bx, by)], fill=255, width=1)
    # a short radial check running out of each knot
    for cx, cy, rx, ry in kn:
        x, y = cx + rx * 0.8, cy
        for i in range(int(rng.uniform(15, 50))):
            d.line([(x, y), (x + 5, y + rng.normal(0, 0.4))], fill=255, width=max(1, int(round(1.5 * hs * (1 - i / 50)))))
            x += 5
    c0 = gaussian_filter(np.asarray(cm, np.float32) / 255.0, 0.8)
    Yc, Xc = np.mgrid[0:h, 0:w].astype(np.float32)
    c0 = map_coordinates(c0, [Yc + 1.1 * anis(rng, h, w, 3, 2.2), Xc + 1.6 * anis(rng, h, w, 4, 2.0)], order=1, mode="nearest")
    crack = smooth(0.22, 0.62, c0)
    lip = np.clip(gaussian_filter(crack, 2.2) * 2.2, 0, 1) * (1 - crack)

    v = (0.50 + lift + blotch * (0.085 * low + 0.06 * band) + 0.03 * band + 0.075 * mid + 0.05 * fib + 0.02 * hair + 0.03 * speck
         - 0.17 * ridge - 0.08 * ridge2 + 0.04 * pits)
    v = v - 0.46 * crack - 0.34 * knot + 0.06 * kring + 0.09 * lip
    hgt = (0.8 * ridge + 0.3 * ridge2 + 0.30 * mid + 0.12 * fib + 0.04 * hair + 0.05 * speck
           - 0.50 * pits - 3.0 * crack + 0.6 * lip + 0.9 * knot * smooth(0.0, 1.0, 1.15 - np.sqrt(1.0 - np.clip(knot, 0, 1))) + 0.25 * kring)
    return v.astype(np.float32), hgt.astype(np.float32), crack.astype(np.float32)


def planks(h, w, cuts, rng, tones, mix_range=(0.0, 0.55), **kw):
    """Butt-jointed planks side by side. cuts: x positions of the joints. Returns v, hgt, crack, rgb, seam."""
    edges = [0] + list(cuts) + [w]
    v = np.zeros((h, w), np.float32)
    hg = np.zeros((h, w), np.float32)
    cr = np.zeros((h, w), np.float32)
    rgb = np.zeros((h, w, 3), np.float32)
    seam = np.zeros((h, w), np.float32)
    for i in range(len(edges) - 1):
        a, b = edges[i], edges[i + 1]
        pv, ph_, pc = make_wood(h, b - a, rng, **kw)
        pv = pv + rng.uniform(-0.06, 0.06)
        t = rng.uniform(*mix_range)
        base, alt = tones
        col = (1 - t) * base(pv) + t * alt(pv)
        rgb[:, a:b] = col * rng.uniform(0.9, 1.08)
        v[:, a:b], hg[:, a:b], cr[:, a:b] = pv, ph_, pc
        if i > 0:     # joint
            X = np.arange(w, dtype=np.float32)
            g = smooth(2.6, 0.6, np.abs(X - a))
            seam = np.maximum(seam, np.broadcast_to(g, (h, w)))
        # plank ends are slightly rounded over
        X = np.arange(a, b, dtype=np.float32)
        bevel = smooth(0, 3.0, np.minimum(X - a, b - 1 - X))
        hg[:, a:b] -= (1 - bevel)[None, :] * 1.6
    hg -= seam * 3.2
    rgb *= (1 - 0.7 * seam[..., None])
    return v, hg, cr, rgb, seam


def text_mask(shape, items, fonts):
    """items: (text, fontkey, x, cy, anchor, tracking). Coordinates in canvas pixels."""
    im = Image.new("L", (shape[1], shape[0]), 0)
    d = ImageDraw.Draw(im)
    for s, fk, x, cy, anchor, trk in items:
        f = fonts[fk]
        glyph = f.get("icon", False)
        font = f["font"]
        if glyph:
            d.text((x, cy), s, font=font, fill=255, anchor="mm")
            continue
        cap = f["cap"]
        base = cy + cap / 2
        widths = [d.textlength(ch, font=font) for ch in s]
        total = sum(widths) + trk * (len(s) - 1)
        if anchor == "l":
            x0 = x
        elif anchor == "r":
            x0 = x - total
        else:
            x0 = x - total / 2
        for ch, wd in zip(s, widths):
            d.text((x0, base), ch, font=font, fill=255, anchor="ls")
            x0 += wd + trk
    return np.asarray(im, np.float32) / 255.0


def paint(alb, hgt, cov, color, rng, wood_v, block=None, wear=0.8, opacity=0.94, wobble=0.8):
    """Lay paint over wood. cov: 0..1 coverage mask. Paint wicks along the grain, breaks up on ridges,
    cracks and at its own edges, and shows the grain through where it is thin."""
    h, w = cov.shape
    Y, X = np.mgrid[0:h, 0:w].astype(np.float32)
    m = gaussian_filter(cov, (0.45, 1.25))
    dx = anis(rng, h, w, 40, 3) * wobble
    dy = anis(rng, h, w, 40, 3) * wobble * 0.7
    m = map_coordinates(m, [Y + dy, X + dx], order=1, mode="nearest")
    wn = (0.55 * anis(rng, h, w, 26, 1.1) + 0.38 * anis(rng, h, w, 160, 6) + 0.30 * anis(rng, h, w, 4, 0.6))
    wn = wn + 0.9 * np.clip(-(wood_v - 0.5) * 3, -1, 1)          # thin on the dark late-wood lines
    c = smooth(0.38, 0.66, m - 0.30 * wear * (wn - 0.3))
    if block is not None:
        c = c * (1 - np.clip(block * 1.6, 0, 1))
    thick = np.clip(opacity - 0.16 * wear * (0.5 + 0.5 * anis(rng, h, w, 60, 3)), 0.55, 1.0)
    col = np.asarray(color, np.float32)
    shown = col[None, None, :] * (0.80 + 0.40 * np.clip(wood_v, 0, 1))[..., None]
    a = (c * thick)[..., None]
    alb[:] = alb * (1 - a) + shown * a
    hgt[:] = hgt * (1 - 0.55 * c) + 0.5 * c            # paint fills the pores, so it is smoother
    return c


def nail(alb, hgt, x, y, rng, r=4.2):
    h, w = hgt.shape
    # rust bleeding down the grain
    ln = int(r * 7 + rng.uniform(0, r * 5))
    y0, y1 = int(max(0, y)), int(min(h, y + ln))
    if y1 > y0:
        yy = np.arange(y0, y1, dtype=np.float32)
        xs0, xs1 = int(max(0, x - r * 3)), int(min(w, x + r * 3))
        xx = np.arange(xs0, xs1, dtype=np.float32)
        t = (yy - y)[:, None]
        wob = 0.9 * np.sin(t / 5.0 + x)
        a = (0.62 * np.exp(-np.maximum(t, 0) / (ln * 0.5)) * np.exp(-(((xx[None, :] - x - wob) / (r * (0.8 + t / ln))) ** 2)))
        rust = np.array([0.26, 0.12, 0.06], np.float32)
        region = alb[y0:y1, xs0:xs1]
        alb[y0:y1, xs0:xs1] = region * (1 - a[..., None]) + (rust * (0.5 + region.mean(-1, keepdims=True))) * a[..., None] * 0.9
    ys0, ys1 = int(max(0, y - r * 3)), int(min(h, y + r * 3))
    xs0, xs1 = int(max(0, x - r * 3)), int(min(w, x + r * 3))
    if ys1 <= ys0 or xs1 <= xs0:
        return
    yy, xx = np.mgrid[ys0:ys1, xs0:xs1].astype(np.float32)
    d = np.hypot(xx - x, yy - y)
    disc = smooth(r, r - 1.0, d)
    ring = smooth(r + 2.6, r, d) * (1 - disc)
    iron = np.array([0.095, 0.08, 0.07], np.float32)
    reg = alb[ys0:ys1, xs0:xs1]
    reg *= (1 - 0.45 * ring)[..., None]
    alb[ys0:ys1, xs0:xs1] = reg * (1 - disc[..., None]) + iron * disc[..., None]
    hgt[ys0:ys1, xs0:xs1] += 2.4 * disc * np.sqrt(np.clip(1 - (d / r) ** 2, 0, 1)) - 0.8 * ring


def shade(alb, hgt, strength=1.7, light=(-0.30, -0.70, 0.65)):
    g = gaussian_filter(hgt, 0.8)
    hy, hx = np.gradient(g)
    nx, ny, nz = -hx * strength, -hy * strength, np.ones_like(hx)
    L = np.array(light, np.float32)
    L /= np.linalg.norm(L)
    lam = (nx * L[0] + ny * L[1] + nz * L[2]) / np.sqrt(nx * nx + ny * ny + nz * nz)
    flat = L[2]
    s = np.clip(1 + 1.9 * (lam - flat), 0.30, 1.7)
    cav = hgt - gaussian_filter(hgt, 3.0)
    ao = np.clip(1 + 0.50 * cav, 0.5, 1.08)
    return alb * (s * ao)[..., None]
