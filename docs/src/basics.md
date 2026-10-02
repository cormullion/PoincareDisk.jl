# The basics

This package lets you draw hyperbolic geometry using the Poincaré disk model.

## The Poincaré disk

The Poincaré disk is a two-dimensional space for hyperbolic geometry. It provides a surface on which you can draw using *non-Euclidean geometry*, where all 2D points are mapped to a unit disk and lie inside it. The boundary of the circle lies at infinity. In the Poincaré disk, all Euclid's geometric postulates apply except the final (fifth, "parallel") postulate. You'll have no trouble finding explanatory material on the internet!

In the Poincaré disk model, the shortest path between two points is a circular arc called a *geodesic*. The internal angles of triangles add up to less than 180°. Hyperbolic circles are represented as Euclidean circles contained entirely inside the disk. Hyperbolic lines that pass through the origin lie on the diameter of the disk, and can be represented as straight lines (they are arcs of infinite radius).

```@setup example
using PoincareDisk
using Luxor

d = Drawing(600, 600, :png)
    origin()
    setline(1)
    draw_poincare_disk(action = :path)
    sethue("grey10")
    fillpath()

    tiles = hyperbolic_tiling(3, 1000)
    sethue("white")
    for (tile, _) in tiles
        hyperbolic_poly(tile, action=:stroke)
    end
finish()
preview()
```

```@example example
d # hide
```

!!! note

    Famous French mathematician and physicist Henri Poincaré (1854–1912) popularized the hyperbolic disk model in 1905 and it now carries his name. However, it was really a rediscovery of the original work of Eugenio Beltrami some decades earlier.

The disk is a *unit disk*, with `(0 + 0im)` at the center.
Points are represented as complex numbers `z`, where `|z| < 1` The four cardinal points (E, S, W, and N) are:

- `1.0 + 0.0im`
- `0 + 1.0im`
- `-1.0 + 0.0im`
- `0 - 1.0im`

These lie on the boundary for the disk, at infinity.

```@example
using PoincareDisk
using Luxor
@drawsvg begin
    background("black")
    sethue("grey15")
    draw_poincare_disk(action = :fill)
    p1 = 1.0 + 0.0im  # E
    p2 = 0 + 1.0im    # S
    p3 = -1.0 + 0.0im # W
    p4 = 0 - 1.0im    # N
    sethue("cyan")
    fontsize(30)
    circle.(complex_to_point.([p1, p2, p3, p4]), 5, :fill)
    label.(["E", "S", "W", "N"], [:w, :n, :e, :s], 
        complex_to_point.([p1, p2, p3, p4]), 
        offset=20.0)
end
```

!!! note

    We can't draw these four points on the Poincaré disk, since they're outside, on the boundary, at infinity. So we converted them to Luxor points first.

In this package, the important functions are:

- [`hyperbolic_point()`](@ref)
- [`hyperbolic_line()`](@ref)
- [`hyperbolic_circle()`](@ref)
- [`hyperbolic_poly()`](@ref)
- [`draw_poincare_disk()`](@ref)
- [`hyperbolic_tiling()`](@ref)
- [`draw_tiling()`](@ref)
- [`complex_to_point()`](@ref)
- [`point_to_complex()`](@ref)

All 2D graphics functions are provided by Luxor.jl (include with `using Luxor`). You can find the documentation for Luxor [here](https://juliagraphics.github.io/LuxorManual/).

The Luxor.jl method of supplying an *action* to a drawing function, such as `:stroke` or `:fill`, is used here.

## Hyperbolic points

The [`hyperbolic_point(z)`](@ref) function draws a small circle
on the current drawing to represent the location of the hyperbolic point at complex coordinate `z`.

This function has a `dotradius` keyword (the default is 5) that determines the radius of the Luxor circle used to mark the position. All other graphic properties such as color are as set in Luxor.jl *before* you call the function.

The next example draws points in the form `center + radius * θ` on the disk. 

```@example
using PoincareDisk
using Luxor

@drawsvg begin
    sethue("grey40")
    draw_poincare_disk(action=:fill)
    sethue("gold")
    for θ in range(0, 2π, length=35)
        za = 0.5 + 0.4 * exp(1im * θ)
        hyperbolic_point(za, dotradius = 4)
        zb = -0.5 + 0.4 * exp(1im * θ)
        hyperbolic_point(zb, dotradius = 4)
    end
end
```

### The `cis()` function

In Julia you can also use the `cis()` function to generate complex numbers. It calculates `exp(im x)` using Euler's formula:

$ \cos(x) + i \sin(x) = \exp(i x) $

so `cis(π/4)` returns `0.7071 + 0.7071im`.

```@example
using PoincareDisk
using Luxor

@drawsvg begin
    sethue("grey40")
    draw_poincare_disk(action=:fill)
    sethue("gold")
    for θ in range(0, 2π, length=35)
        za = 0.5 + 0.4cis(θ)
        hyperbolic_point(za, dotradius = 4)
        zb = -0.5 + 0.4cis(θ)
        hyperbolic_point(zb, dotradius = 4)
    end
end
```

## The Poincaré disk

You can add graphics for the Poincaré disk itself with the function [`draw_poincare_disk()`](@ref).

The size of the disk, on a Luxor drawing, is determined by the global constant `DEFAULT_DISK_RADIUS`, which is initially set to 295.0 (so that the Poincaré disk fits neatly on the default Luxor drawing size of 600 × 600). The default action is `:stroke`; you can draw a filled disk in the current color with `action=:fill`.

## Hyperbolic lines

Use `hyperbolic_line(z1, z2)` to construct a hyperbolic line between `z1` and `z2`.

These lines are called *geodesics*, which are arcs of circles that would, if extended, meet the edge of the unit circle at right angles.

The default action is `:stroke`. `:fill` is not very useful here, but `:path` would allow you to obtain the path for later use. The function returns either the information for the supporting circle `(centerpoint, radius)`, or `(nothing, nothing)` if the geodesic is not part of a circle (ie. the line lies on a diameter of the disk).

In the next example, each hyperbolic line starts near the bottom edge (at `z1 = 0.999999 * exp(π/2 * im)`) and reaches to each of the positions around the edge generated by the loop. The `Colors.Oklch` function generates a pleasing set of shades.

```@example
using PoincareDisk
using Luxor
using Colors

@drawsvg begin
    sethue("grey10")
    draw_poincare_disk(action = :fill)
    setline(4)
    z1 = 0.999999 * exp(π/2 * im)
    for θ in range(0, 2π - 2π / 50, length = 50)
        sethue(Oklch(0.6, 0.6, 360rescale(θ, 0, 2π)))
        z2 = 0.999999 * exp(θ * im)
        hyperbolic_line(z1, z2) # default action is :stroke
        circle(complex_to_point(z2), 5, :fill)
    end
end
```

The `complex_to_point(z)` function converts from disk coordinates to Luxor drawing coordinates, so we can draw a circular dot using `Luxor.circle()` to mark the end point.

Here's another line-drawing example.

```@example
using PoincareDisk
using Luxor
using Colors

@drawsvg begin
    draw_poincare_disk(action = :fill)
    sethue("white")
    setline(5)
    R = 0.99
    for θ in logrange(π / 30, π/2, length = 50)
        sethue(HSV(360rescale(θ, 0, π/2), 0.8, 0.8))
        z1 = R * cis(π/2 + θ)
        z2 = R * cis(π/2 - θ)
        hyperbolic_line(z1, z2)
    end
    setline(1)
    sethue("white")
    for θ in range(π / 30, π, length = 30)
        z1 = R * cis(θ)
        z2 = R * cis(-θ)
        hyperbolic_line(z1, z2)
    end
end
```

## Hyperbolic circles

The `hyperbolic_circle(zc, rho)` function constructs a hyperbolic circle of radius `rho` centered at the disk point `zc`. 

Hyperbolic circles are ordinary Euclidean circles, but the actual center/radius differs from the hyperbolic center/radius. 

Notice in the next example that the two hyperbolic circles have the same hyperbolic radius (`0.9`) but look different sizes, because the centers are different.

```@example
using PoincareDisk 
using Luxor 
@drawsvg begin 
sethue("grey15")
draw_poincare_disk(action = :fill)
setline(5)
setopacity(0.6)
sethue("magenta")
zc = 0.85cis(π/2)
hyperbolic_circle(zc, 0.9) # default action is :stroke

sethue("cyan")
zc = 0.3cis(π/2)
hyperbolic_circle(zc, 0.9, action = :stroke)
end
```

Here's a slightly more interesting example that explores the fact that hyperbolic circles with the same designated 'radius' (here `0.3`) look different depending on their distance from the center of the Poincaré disk.

```@example
using PoincareDisk 
using Luxor 
using Colors 

@drawsvg begin 
    sethue("grey15")
    draw_poincare_disk(action = :fill)
    setopacity(0.5)
    setline(1)
    for k in range(0.1, 0.95, length = 50)
        for angle in range(0, 2π - 2π/7, length=7)
            sethue(Oklch(0.5, 0.5, 360k))
            zc = k * cis(angle)
            hyperbolic_circle(zc, 0.3, action = :fillpreserve)
            sethue("white")
            strokepath()
        end
    end
end
```

## Hyperbolic polygons

The `hyperbolic_poly()` function constructs a hyperbolic polygon and adds it to the current drawing as a Luxor path. Each side of the polygon is a geodesic curve. The default action applied to the path is `:stroke`.

This function expects an array of the corners of the polygon as complex number coordinates. It returns the Luxor bounding box of the extents of the path enclosing it.

In the next example, we generate arrays of three random positions on the edge of the disk. Each path is filled with a random color and then stroked with white.

```@example
using PoincareDisk
using Luxor
using Colors
using Random

Random.seed!(3)

@drawsvg begin
    sethue("grey15")
    draw_poincare_disk(action = :fill)
    setopacity(0.7)
    for i in 1:6
        z = Complex[]
        push!(z, 0.9999cis(rand() * π/3))
        push!(z, 0.9999cis(rand() * 2π/3))
        push!(z, 0.9999cis(rand() * 4π/3))
        randomhue()
        hyperbolic_poly(z, action = :fillpreserve)
        sethue("white")
        strokepath()
    end
end
```

In the next example, we generate a polar grid of boxes, and render each one as a hyperbolic polygon.

```@example
using PoincareDisk # hide
using Luxor # hide
using Colors # hide

@drawsvg begin
    sethue("grey10")
    draw_poincare_disk(action = :fill)
    setline(2)
    # radius from 0.2 to ~1
    rs = range(0.2, 0.99999, length = 16)
    # angle from 0 to 2π
    θs = range(0, 2π, length = 16)
    polargrid = [r * cis(θ) for r in rs, θ in θs]
    let
        fill = 0
        for r in 1:(length(polargrid[1, :]) - 1)
            for c in 1:(length(polargrid[:, 1]) - 1)
                setgray(fill == 0 ? fill = 1 : fill = 0)
                p1, p2, p3, p4 = polargrid[r, c], 
                    polargrid[r, c + 1],
                    polargrid[r + 1, c + 1],
                    polargrid[r + 1, c]
                hyperbolic_poly([p1, p2, p3, p4], 
                    action = :fill)
            end
        end
    end
end
```

A number of the drawing functions have the `radius=` keyword:

- [`hyperbolic_point()`](@ref)
- [`hyperbolic_line()`](@ref)
- [`hyperbolic_circle()`](@ref)
- [`hyperbolic_poly()`](@ref)
- [`complex_to_point()`](@ref)
- [`draw_poincare_disk()`](@ref)
- [`draw_tiling()`](@ref)

Use this keyword to specify the radius of the Poincaré disk if you're not using the default value (295.0). Luxor default drawings are 600 × 600, so a disk with default radius of 295 fits nicely.

`hyperbolic_poly()` also provides these keywords:

- `diskcenter=O`
- `action=:stroke`

The utility function [`regular_hyperbolic_poly()`](@ref) generates a regular hyperbolic polygon that would fit inside a hyperbolic circle of a given radius.

```@example
using PoincareDisk
using Luxor

@drawsvg begin
sethue("grey10")
draw_poincare_disk(action = :fill)
setline(1)
sethue("white")
for i in 0.1:0.1:2π
    vs = regular_hyperbolic_poly(5, i, rotation = -π/2)
    hyperbolic_poly(vs, action=:stroke)
end
end
```

The `hcenter=` keyword lets you center the polygon anywhere on the disk:

```@example
using PoincareDisk
using Luxor 

@drawsvg begin 
    sethue("grey10")
    draw_poincare_disk(action = :fill)
    setline(1)
    sethue("white")
    L = 6
    for i in 0.1:0.1:1.6
        for pc in [0.7 * cis(θ) for θ in range(0, 2π - 2π / L, length = L)]
            vs = regular_hyperbolic_poly(6, i, hcenter = pc)
            hyperbolic_poly(vs, action = :stroke)
        end
    end
end 
```

## Trees

In the next example, a recursive function draws a tree in hyperbolic space. The origin is placed off-center just to enhance the hyperbolic distortion.

This uses two built-in functions that do Möbius transformations: 

- `mobius_to_origin(a, z)`: moves `a` to the center (0), then return `z` after the same transformation

- `mobius_from_origin(w, a)`: the inverse of the `mobius_to_origin()` function, ie. maps 0 to `a`

!!! note

    Möbius transformations are used when drawing on the Poincaré disk because they preserve the disk's structure and maintain the essential properties of hyperbolic geometry, such as distances and angles.

```@example
using Luxor
using PoincareDisk
using Colors

function build_tree(node::ComplexF64, parent, depth::Int;
        branches = 12)
    depth == MAXDEPTH && return  
    if parent === nothing
        directions = range(0, 2π - 2π/branches, length = branches)  
    else
        # recenter the disk on `node` 
        local_parent = mobius_to_origin(parent, node)
        # face the opposite way to create new branch directions
        away = angle(local_parent) + π
        # reduce branch angles as we get further away from origin
        directions = away .+ range(-π, π, length = branches) ./ branches
    end
    setblend(blend(O, 0, O, 300, "orange", "cyan"))
    for theta in directions
        # calculat step length and the next point
        # in node's local frame 
        local_child = rescale(depth, 1, MAXDEPTH, 0.6, 0.8) * cis(theta)
        # map back to the disk
        child = mobius_from_origin(local_child, node)
        setline(rescale(depth, 1, MAXDEPTH, 6, 0.2))
        hyperbolic_line(node, child)                           
        build_tree(child, node, depth + 1, branches=branches)
    end
    return
end

const MAXDEPTH = 3

@drawsvg begin
    sethue("grey20")
    draw_poincare_disk(action = :fill)
    build_tree(0.2 + 0.2im, nothing, 0, branches = 5)
end
```

## Farey sequence

The rational numbers on the boundary correspond to the *Farey sequence*, which is a collection of reduced fractions between 0 and 1. This example uses Luxor's `textplace()` function to approximate the look of decent fractions. Ideally you'd be using ``\LaTeX`` or Typst to make them look nice.

```@example
using PoincareDisk
using Luxor
using LinearAlgebra
using Colors

"""
Convert `z` on the boundary of the Poincaré disk to its corresponding Farey fraction.
"""
function vertex_to_farey(z; tol::Float64 = 1.0e-11)
    # on the boundary?
    if abs(abs(z) - 1.0) > tol
        @warn "Warning: Vertex \$z is not on the boundary of the Poincaré disk."
    end

    # point maps to infinity (z = 1)
    if abs(z - 1.0) < tol
        return rationalize(1 / 0)
    end

    # Cayley transform
    τ = im * (1.0 + z) / (1.0 - z)
    real_val = real(τ)
    return rationalize(Int, real_val, tol = tol)
end

function poinfarey()
    Drawing(600, 600, :svg)
    origin()
    background("black")
    sethue("grey15")
    draw_poincare_disk(action = :fill, radius = 230)
    tiles = hyperbolic_tiling(4, 50000, depth = 3)
    setline(1.5)
    sethue("gold")
    for (tile, g) in tiles
        hyperbolic_poly(tile, action = :stroke, radius = 230)
        for vertex in tile
            pt = complex_to_point(vertex, radius = 230)
            sl = slope(O, pt)
            if g >= 3
                rat = vertex_to_farey(vertex, tol = 0.001)
                offsetpoint = polar(245, sl)
                fsize = 8
                if sign(rat.num) >= 0
                    textplace(
                        string(rat.num, "_", rat.den), offsetpoint,
                        [
                            (
                                size = fsize, advance = false,
                                color = colorant"white",
                            ),
                            (size = 2fsize, shift = -2, advance = false, kern = -2), # 'fraction bar'
                            (size = fsize, shift = -14, advance = false),
                        ]
                    )
                else
                    textplace(
                        string(rat.num, "_", rat.den), offsetpoint,
                        [
                            (
                                size = fsize,
                                color = colorant"white",
                            ),
                            (
                                advance = false,
                            ),
                            (size = 2fsize, shift = -2, advance = false, kern = -2), # 'fraction bar'
                            (size = fsize, shift = -14, advance = false),
                        ]
                    )
                end
            end
        end
    end
    finish()
    return preview()
end

poinfarey()
```
