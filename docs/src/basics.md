# The basics

This package lets you draw hyperbolic geometry using the Poincaré disk model.

## The Poincaré disk

The Poincaré disk is a two-dimensional hyperbolic plane. It provides a surface on which you can draw using *non-Euclidean geometry*. All 2D points are mapped to a unit disk, with all points lying inside it. At the boundary of the circle lies infinity. Here, most of Euclid's geometric postulates apply, but the final (fifth, "parallel") postulate doesn't. You'll have no trouble finding explanatory material on the internet!

In the Poincaré disk model, the shortest path between two points is drawn as a circular arc called a *geodesic*. The internal angles of triangles add up to less than 180°. Hyperbolic circles are represented as Euclidean circles contained entirely inside the disk.

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

## Overview

Points on the Poincaré disk are represented as complex numbers `z`, where `|z| < 1`.

The disk is a *unit disk*, with `(0 + 0im)` at the center. The fourcardinal points (E, S, W, and N) are:

- `1.0 + 0.0im`
- `0 + 1.0im`
- `-1.0 + 0.0im`
- `0 - 1.0im`

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

All 2D graphics functions are provided by Luxor.jl, which you should probably add to the environment (`using Luxor`),and you can find the documentation for that package [here](https://juliagraphics.github.io/LuxorManual/).

The Luxor.jl method of supplying an *action* to a drawing function, such as `:stroke` or `:fill`, is used here.

## Hyperbolic points

The [`hyperbolic_point(z)`](@ref) function draws a small circle on the current drawing to represent the location of
a hyperbolic point at complex coordinate `z`.

This function has a `dotradius` keyword that determines the radius of the Luxor circle used to mark the position. All other graphic properties such as color are as set in Luxor.jl *before* you call the function.

The next example draws points on the disk using the form `center + radius * θ`. 

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

You can add graphics for the Poincaré disk itself with:

[`draw_poincare_disk(;action=:fill)`](@ref)

The size of the disk, on a Luxor drawing, is determined by the global constant `DEFAULT_DISK_RADIUS`, which is initially set to 295.0 (so that the Poincare disk fits neatly on the default Luxor drawing size of 600 × 600). The default action is `:stroke`; you can draw a filled disk with `action=:fill`.

## Hyperbolic lines

Use `hyperbolic_line(z1, z2)` to construct a hyperbolic line between `z1` and `z2`.

These lines are called *geodesics*, which are arcs of circles that would if extended meet the edge of the unit circle at right angles.

The default action is `:stroke`. `:fill` is not very useful here, but `:path` would allow you to obtain the path for later use. The function returns either the information for the supporting circle `(centerpoint, radius)`, or `(nothing, nothing)` if the geodesic is not part of a circle at all (it lies on a diameter).

In the next example, each hyperbolic line starts near the bottom edge (at `z1 = Complex(0, 0.999999)`) and reaches to each of the positions around the edge generated by the loop. The `Colors.Oklch` function generates a pleasing set of shades.

```@example
using PoincareDisk
using Luxor
using Colors

@drawsvg begin
    sethue("grey10")
    draw_poincare_disk(action = :fill)
    setline(4)
    z1 = 0.999999 * exp(π / 2 * im)
    for θ in range(0, 2π - 2π / 50, length = 50)
        sethue(Oklch(0.6, 0.6, 360rescale(θ, 0, 2π)))
        z2 = 0.999999 * exp(θ * im)
        hyperbolic_line(z1, z2) # default action is :stroke
        circle(complex_to_point(z2), 5, :fill)
    end
end
```

The `complex_to_point(z)` function converts from disk coordinates to Luxor drawing coordinates, so we can draw a circular dot using `Luxor.circle()` to mark the end point.

## Hyperbolic circles

The `hyperbolic_circle(zc, rho)` function constructs a hyperbolic circle of hyperbolic radius `rho` centered at the disk point `zc`. 

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
zc = 0.85cis(π / 2)
hyperbolic_circle(zc, 0.9) # default action is :stroke

sethue("cyan")
zc = 0.3cis(π / 2)
hyperbolic_circle(zc, 0.9, action = :stroke)
end
```

Here's a slightly more interesting example that explores the idea that hyperbolic circles with the same designated 'radius' (here `0.3`) look different depending on their distance from the center of the Poincaré disk.

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

The `hyperbolic_poly()` function constructs a hyperbolic polygon and adds it to the current drawing as a Luxor path. Each side of the polygon is a geodesic curve. The default action is `:stroke`.

This function expects an array of the corners of the polygon, as complex number coordinates. 

In the next example, we generate arrays of three random positions on the edge of the disk. Each path is filled and then stroked with white.

```@example
using PoincareDisk
using Luxor
using Colors
using Random

Random.seed!(62)

@drawsvg begin
    sethue("grey15")
    draw_poincare_disk(action = :fill)
    setopacity(0.7)
    for i in 1:6
        z = Complex[]
        push!(z, 0.99cis(rand() * π))
        push!(z, 0.99cis(rand() * 3π / 2))
        push!(z, 0.99cis(rand() * 2π))
        Random.shuffle!(z)
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
                hyperbolic_poly([p1, p2, p3, p4], action = :fill)
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

Use this keyword to specify the radius of the Poincaré disk if you're not using the default value (295.0). Luxor default drawings are 600 × 600, so a disk with radius 295 fits nicely.

`hyperbolic_poly()` provides these keywords:

- `radius=DEFAULT_DISK_RADIUS`
- `diskcenter=O`
- `action=:stroke`

The utility function [`regular_hyperbolic_poly()`](@ref) generates a regular hyperbolic polygon, inside a hyperbolic circle of a given radius.

```@example
using PoincareDisk
using Luxor

@drawsvg begin
sethue("grey10")
draw_poincare_disk(action = :fill)
setline(1)
sethue("white")
for i in 0.1:0.1:6
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