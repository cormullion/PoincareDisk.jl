
using PoincareDisk # hide
using Luxor # hide
using Colors # hide


function lighten(col::Colorant, f)
    c = convert(RGB, col)
    return RGB(f * c.r, f * c.g, f * c.b)
end

function blend_render(pts, color::Luxor.Colorant)
    cpt = polycentroid(pts)
    d = boxwidth(BoundingBox(pts))
    setblend(
        blend(
            cpt, 0, cpt, d / 2,
            lighten(color, 1.5),
            lighten(color, 0.6),
        )
    )
    @layer begin
    poly(pts, :clip)
    paint()
    clipreset()
    end
end

Drawing(600, 600, "/tmp/poincaredisk-logo.png")
origin()

circle(O, 275, :clip)
sethue("grey20")
paint()
tiles = hyperbolic_tiling(
    3, 8;
    depth = 6,
    hcenter = 0.0 + 0.0im,
    rotation = π / 2,
    maxtiles = 400
)
fontsize(30)
setline(1)
setlinejoin("bevel")
for (tile, g, corners) in tiles
    sethue([Luxor.julia_red, Luxor.julia_green, Luxor.julia_purple][mod1(g, end)])
    pts = hyperbolic_poly(tile, action = :none)
    pc = polycentroid(pts)
    blend_render(pts, getcolor())
    setline(rescale(distance(pc, O), 0, 200, 10, 4))
    sethue("white")
    strokepath()
end

sethue("purple")
setline(10)
circle(O, 275, :stroke)
finish()
preview()
