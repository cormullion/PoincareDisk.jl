using PoincareDisk # hide
using Luxor # hide
using Colors # hide

img = readpng("$(homedir())/projects/programming/julia/poincare.png")
imgside = max(img.width, img.height)

Drawing(1000, 1000, "/tmp/mrpoincare.png")
origin()
draw_poincare_disk(action = :fill, radius = 500)
tiles = hyperbolic_tiling(
    5, 4;
    depth = 8,
    hcenter = 0.0 + 0.0im,
    rotation = π / 2,
    maxtiles = 2000
)
for (tile, g) in tiles
    sethue(Oklch(0.5, 0.3, rand(1:360)))
    @layer begin
        pts = hyperbolic_poly(tile, radius = 500, action = :path)
        translate(polycentroid(pts))
        polymove!(pts, O, -polycentroid(pts))
        poly(pts, :clip)
        setopacity(0.8)
        randomhue()
        paint()
        scale(boxdiagonal(BoundingBox(pts)) / imgside)
        placeimage(img, O, 0.8, centered = true)

        clipreset()
    end
    setline(1)
    sethue("white")
    pts = hyperbolic_poly(tile, radius = 500, action = :path)
    poly(pts, :stroke)
end
finish()
preview()
