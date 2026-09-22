module PoincareDisk

using Luxor

export hyperbolic_line,
    hyperbolic_circle,
    hyperbolic_poly,
    hyperbolic_tiling,
    hyperbolic_point,
    draw_tiling,
    draw_poincare_disk,
    complex_to_point,
    point_to_complex,
    hyperbolic_distance,
    regular_hyperbolic_poly

# default radius of the unit disk
# this is slightly smaller than the default Luxor drawing
# width (600 × 600), so that it fits nicely
const DEFAULT_DISK_RADIUS = 295.0

"""
    complex_to_point(z; radius=DEFAULT_DISK_RADIUS, diskcenter::Point=O)

Convert a point `z` on the unit disk (a complex number with
|z| < 1) into a `Point` on the Luxor drawing, scaling by
`radius` and shifting so the disk is centered at
`diskcenter`.

Uses the global constant `DEFAULT_DISK_RADIUS`.

"""
function complex_to_point(z::Complex; radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O)
    return Point(diskcenter.x + real(z) * radius, diskcenter.y + imag(z) * radius)
end

"""
    point_to_complex(p::Point; radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O)

Convert the Luxor point `p` into a coordinate on the Poincaré disk.

Uses the global constant `DEFAULT_DISK_RADIUS`.
"""
function point_to_complex(
        p::Point;
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O
    )
    return Complex((p.x - diskcenter.x) / radius, (p.y - diskcenter.y) / radius)
end

"""
    mobius_to_origin(z, a)

Apply a Möbius transformation that maps the unit disk to
itself. This "recenters" the disk so that the point
`a` moves to the origin 0 while everything stays inside the
unit disk. Angles are preserved. 
"""
function mobius_to_origin(z, a)
    return (Complex(z) - a) / (1 - conj(a) * Complex(z))
end

"""
    mobius_from_origin(w, a)

Find the inverse of the `mobius_to_origin()` function: ie send `0` to `a`.
"""
function mobius_from_origin(w, a)
    return (Complex(w) + a) / (1 + conj(a) * Complex(w))
end

"""
    hyperbolic_distance(a, b)

Find the hyperbolic distance between two points on the Poincaré disk.
"""
function hyperbolic_distance(a, b)
    return 2atanh(abs((Complex(a) - Complex(b)) / (1 - conj(Complex(a)) * Complex(b))))
end

"""
    _geodesic_arc_info(a, b; radius=DEFAULT_DISK_RADIUS, diskcenter=O)

Build the hyperbolic geodesic that passes through disk
points `a` and `b`. It can either be a circular arc or a
straight line - which happens when `a` and `b`
form a diameter.

Returns one of three different results:

- `(:arc, center, r, theta1, theta2)` — the geodesic is
an arc centered at `center` with radius `r`. The
arc runs counterclockwise from angle `theta1` to
`theta2` and does not pass through the excluded point
(the inversion of `a` in the unit circle).

- `(:carc, center, r, theta1, theta2)` — the geodesic is
an arc centered at `center` with radius `r`, but the
non-excluded arc runs *clockwise* from `theta1` to
`theta2`.

- `(:line, p1, p2)` — `a`, `b`, and the origin are
  collinear, so the geodesic is just a straight line
  between the points `p1` and `p2`.

The unique circle orthogonal to the unit circle that passes
through `a` and `b` also passes through `a* = 1/conj(a)`,
the inversion of `a` in the unit circle. The geodesic arc is
the arc of the circle through `(a, b, a*)` that avoids `a*`.
"""
function _geodesic_arc_info(
        a, b;
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O
    )
    a, b = Complex(a), Complex(b)
    (abs(a) >= 1 || abs(b) >= 1) && error(
        """_geodesic_arc_info():
        The geodesic endpoints must satisfy |z| < 1. You have supplied
        $(abs(a)) and $(abs(b))).
        """
    )

    p1 = complex_to_point(a; radius = radius, diskcenter = diskcenter)
    p2 = complex_to_point(b; radius = radius, diskcenter = diskcenter)

    # are a, b, and the 0 are collinear? When they are,
    # the geodesic between them lies along a full diameter
    # line of the disk (a straight line through the center,
    # extended to the boundary in both directions). 
    # In the Poincaré disk model hyperbolic geodesics are
    # either "diameters" or arcs of circles orthogonal to the
    # boundary
    if abs(imag(conj(a) * b)) < 1.0e-9
        return (:line, p1, p2)
    end

    ainv = 1 / conj(a)   # inversion of a in the unit circle
    p3 = complex_to_point(ainv; radius = radius, diskcenter = diskcenter)

    center, r = center3pts(p1, p2, p3)
    theta_a = angle(Complex(p1.x - center.x, p1.y - center.y))
    theta_b = angle(Complex(p2.x - center.x, p2.y - center.y))
    theta_x = angle(Complex(p3.x - center.x, p3.y - center.y))

    s = mod2pi(theta_a)
    e = mod2pi(theta_b)
    e = e < s ? e + 2π : e
    x = mod2pi(theta_x)
    x = x < s ? x + 2π : x

    if s <= x <= e
        # the direct counterclockwise sweep s -> e passes through the
        # excluded point, so the wanted arc is the clockwise one instead
        return (:carc, center, r, s, e)
    else
        return (:arc, center, r, s, e)
    end
end

"""
    draw_poincare_disk(; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke)

Construct the boundary circle of the Poincaré disk itself. The default
Luxor action used here is `:stroke`, or you could use, eg, `:fill`.
"""
function draw_poincare_disk(;
        radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O,
        action::Symbol = :stroke
    )
    return circle(diskcenter, radius, action)
end

"""
    hyperbolic_point(z; 
        radius=DEFAULT_DISK_RADIUS, 
        dotradius = 5, 
        diskcenter=O)

Draw a small filled circle of radius `dotradius` to 
mark the location of the hyperbolic point at complex number `z`.
Return the coordinates of the Luxor point.
"""
function hyperbolic_point(
        z;
        radius::Real = DEFAULT_DISK_RADIUS,
        dotradius = 5,
        diskcenter::Point = O,
    )
    p1 = complex_to_point(z; radius = radius, diskcenter = diskcenter)
    circle(p1, dotradius, :fill)
    return p1
end

"""
    hyperbolic_line(z1, z2; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke)

Construct a new path that makes the hyperbolic geodesic
between disk points `z1` and `z2` as a circular arc (or a
straight line, if collinear).

Then the `action` is applied. The default action is `:stroke`.

Returns either the `(center, radius)` of a circle that would contain
the arc, or `(nothing, nothing)` if it's a diameter.
"""
function hyperbolic_line(z1, z2; 
        radius::Real = DEFAULT_DISK_RADIUS, 
        diskcenter::Point = O,
        action::Symbol = :stroke
    )
    info = _geodesic_arc_info(z1, z2; radius = radius, diskcenter = diskcenter)

    newpath()
    if info[1] === :line
        _, p1, p2 = info
        move(p1)
        line(p2)
        do_action(action)
        return (nothing, nothing)
    else
        kind, center, r, s, e = info
        move(Point(center.x + r * cos(s), center.y + r * sin(s)))
        if kind === :arc
            arc(center, r, s, e, action)
        else
            carc(center, r, s, e, action)
        end
        return (center, r)
    end
end

"""
    hyperbolic_circle(center, rho; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke)

Construct the hyperbolic circle of hyperbolic radius `rho`
centered at disk point `center`. The `action` (default `:stroke`) 
is applied.

Return the Luxor coordinates of the circle's center and radius.
"""
function hyperbolic_circle(
        center, rho; radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O,
        action::Symbol = :stroke
    )
    c = Complex(center)
    abs(c) >= 1 && error("hyperbolic circle center must satisfy |z| < 1")
    rho <= 0 && error("hyperbolic radius must be positive")

    # Euclidean radius once c is moved to 0
    s = tanh(rho / 2)
    # three sample points define the circle
    phis = (0.0, 2pi / 3, 4pi / 3)
    pts = [
        complex_to_point(
                mobius_from_origin(s * cis(phi), c);
                radius = radius,
                diskcenter = diskcenter
            )
            for phi in phis
    ]

    cc, r = circle(pts[1], pts[2], pts[3])
    circle(cc, r, action)
    return cc, r
end

# return the BoundingBox of the current path's extents
function _currentpathboundingbox()
    dx1 = Cdouble[0]
    dx2 = Cdouble[0]
    dy1 = Cdouble[0]
    dy2 = Cdouble[0]
    ccall((:cairo_path_extents, Luxor.Cairo.libcairo),
        Nothing, (Ptr{Nothing}, Ptr{Cdouble}, Ptr{Cdouble},
            Ptr{Cdouble}, Ptr{Cdouble}),
        Luxor._get_current_cr().ptr, dx1, dy1, dx2, dy2)
    return BoundingBox(Point(dx1[1], dy1[1]), Point(dx2[1], dy2[1]))
end

"""
    hyperbolic_poly(vertices; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke)

Construct the closed hyperbolic polygon with `vertices`,
joined by geodesic edges. Each side is built with a
circular arc or straight line, giving a chain of
`arc`/`carc`/`line` path elements.

Finally apply the Luxor action `action` to the resulting path.
The default is `:stroke`.

Return the BoundingBox of the extents of the 
path defining hyperbolic polygon.

The unique circle orthogonal to the unit circle that passes
through `a` and `b` also passes through `a* = 1/conj(a)`,
the inversion of `a` in the unit circle.  The geodesic
circle is the circle through 3 points (`(a, b, a*)`.

For hyperbolic circles, the hyperbolic center moves to the
origin via a Möbius mapping, so a hyperbolic circle of
radius `rho` is the Euclidean circle of radius
`tanh(rho/2)`. 
"""
function hyperbolic_poly(
        vertices::Vector{<:Number};
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O,
        action::Symbol = :stroke
    )
    verts = Complex.(vertices)
    m = length(verts)
    m < 3 && error("hyperbolic_poly(): a polygon needs at least 3 vertices")

    newpath()
    firstpoint = complex_to_point(verts[1]; radius = radius, diskcenter = diskcenter)
    move(firstpoint)

    for i in 1:m
        a, b = verts[i], verts[mod1(i + 1, m)]
        info = _geodesic_arc_info(a, b; radius = radius, diskcenter = diskcenter)
        if info[1] === :line
            _, _, p2 = info
            line(p2)
        else
            kind, center, r, s, e = info
            if kind === :arc
                arc(center, r, s, e, :path)
            else
                carc(center, r, s, e, :path)
            end
        end
    end

    closepath()
    bbx = _currentpathboundingbox()
    do_action(action)
    return bbx
end

"""
    regular_hyperbolic_poly(n, rho; 
        hcenter=0.0+0.0im, 
        rotation=0.0)

Return the vertices of a regular hyperbolic polygon with `n`
sides that fits inside the hyperbolic circle of radius `rho`
centered at `hcenter`, with the first vertex placed at angle
`rotation`.
"""
function regular_hyperbolic_poly(
        n::Integer,
        rho::Real;
        hcenter::Complex = 0.0 + 0.0im,
        rotation::Real = 0.0
    )
    s = tanh(rho / 2)
    return [mobius_from_origin(s * cis(rotation + (2π * (k - 1) / n)), hcenter) for k in 1:n]
end

"""
    geodesic_support(a, b)

The circle or line supporting a geodesic through disk
points `a` and `b`. 

Returns `(:diameter, theta, 0.0)` for a diameter at angle
`theta`, or `(:circle, center, r)` for a circle.
"""
function geodesic_support(a, b)
    a, b = Complex(a), Complex(b)
    if abs(imag(conj(a) * b)) < 1.0e-9
        theta = abs(a) > abs(b) ? angle(a) : angle(b)
        return (:diameter, theta, 0.0)
    else
        ainv = 1 / conj(a)
        c, r = _circle_through(a, b, ainv)
        return (:circle, c, r)
    end
end

"""
    _circle_through(z1, z2, z3) -> (center::Complex, radius::Float64)

Find the Euclidean circumcenter/radius of three complex
points. This is used for reflections which operate in
unscaled disk coordinates rather than drawing coordinates.
"""
function _circle_through(z1::Complex, z2::Complex, z3::Complex)
    ax, ay = reim(z1); bx, by = reim(z2); cx, cy = reim(z3)
    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    ux = ((ax^2 + ay^2) * (by - cy) + (bx^2 + by^2) * (cy - ay) + (cx^2 + cy^2) * (ay - by)) / d
    uy = ((ax^2 + ay^2) * (cx - bx) + (bx^2 + by^2) * (ax - cx) + (cx^2 + cy^2) * (bx - ax)) / d
    center = ux + uy * im
    return center, abs(center - z1)
end

"""
    hyperbolic_reflect(z, a, b)

Reflect disk point `z` across the hyperbolic geodesic
through `a` and `b`.
"""
function hyperbolic_reflect(z, a, b)
    kind, p1, p2 = geodesic_support(a, b)
    zz = Complex(z)
    if kind == :diameter
        θ = p1
        return cis(2θ) * conj(zz)
    else
        c, r = p1, p2
        return c + (r^2 / conj(zz - c))
    end
end

"""
    hyperbolic_tiling(p, q; 
        depth = 8, 
        hcenter = 0.0 + 0.0im, 
        rotation = 0.0, 
        maxtiles = 4000)

Construct the coordinates for a hyperbolic tiling of the Poincaré disk
with polygons with `p` sides and `q` lines joining at each vertex.

Returns an array where each element contains:

- an array of complex numbers (the disk coordinates of each polygon)

- the tile's generation number: `depth` specifies how many generations 

`maxtiles` tiles limits the number of tiles generated.

`p` and `q` must satisfy `1/p + 1/q < 1/2`. 
The simpler tilings are listed in this table:

| p:q | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 |  |  |  |  |  |  |  |  |  |  |  |  |
| 2 |  |  |  |  |  |  |  |  |  |  |  |  |
| 3 |  |  |  |  |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 4 |  |  |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 |  |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 |  |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 7 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 8 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 9 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 10 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 11 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 12 |  |  | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

For example, `(5, 4)`, `(7, 3)`, and `(4, 5)` are all
accepted. The 'simplest' tiling of a triangle is `(3,
7)`, such that 7 lines connect at each of the triangles'
vertices.

Starting with the basic polygon, a hyperbolic polygon
centered at `hcenter`, the tiling is built by reflecting
each tile across each of its edges. A hyperbolic reflection
is an inversion in the edge's circle.
"""
function hyperbolic_tiling(
        p, q; depth = 8,
        hcenter::Number = 0.0 + 0.0im, rotation::Real = 0.0,
        maxtiles::Integer = 4000
    )
    (1 / p + 1 / q) >= 1 / 2 && error("hyperbolic_tiling(): ($p, $q) is not hyperbolic: 
    p and q must satisfy the relation `1/p + 1/q < 1/2`")

    # `rho` is the hyperbolic circumradius of the
    # regular polygons, the distance in hyperbolic space
    # from the center of the polygon to one of its vertices. 
    rho = acosh(cot(π / p) * cot(π / q))

    # Use a set to remember the centres of each tile.
    # Shorten the complex number to improve membership testing.
    # Stay alert for signed zero ( isequal(-0.0, 0.0) = false) )
    key(z::Complex) = (round(real(z), digits = 4) + 0.0, round(imag(z), digits = 4) + 0.0)
    hc = Complex(hcenter)
    # initial tile
    v1 = ComplexF64.(regular_hyperbolic_poly(p, rho; hcenter = hc, rotation = rotation))
    tiles = [(v1, 1)]
    visited = Set{Tuple{Float64, Float64}}([key(hc)])
    frontier = [(v1, hc)]
    generation = 2
    while generation <= depth && !isempty(frontier) && length(tiles) < maxtiles
        newfrontier = Vector{Tuple{Vector{ComplexF64}, ComplexF64}}()
        for (vertices, center) in frontier
            m = length(vertices)
            for i in 1:m
                a, b = vertices[i], vertices[mod1(i + 1, m)]
                newcenter = hyperbolic_reflect(center, a, b)
                # check for unwanted repetition
                k = key(newcenter)
                k in visited && continue
                push!(visited, k)
                newvertices = ComplexF64[hyperbolic_reflect(v, a, b) for v in vertices]
                # keep away from the boundary
                any(abs.(newvertices) .>= 0.9999999999) && continue 
                push!(tiles, (newvertices, generation))
                push!(newfrontier, (newvertices, newcenter))
                length(tiles) >= maxtiles && break
            end
            length(tiles) >= maxtiles && break
        end
        frontier = newfrontier
        generation += 1
    end
    return tiles
end

"""
    draw_tiling(tiles; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:fill, 
        colors=nothing)

Draw the hyperbolic tiling produced by `hyperbolic_tiling()`
by drawing every hyperpolygon in the array of tiles, using the provided
colors.

Apply Luxor `action` to the path that describes each tile. The default is `:fill`.

`colors` can be supplied as an array of two colorants. 
The generation number of each tile is used to alternate
between the two colours. If `q` is even, the tiling has a "chess board"
appearance. 

Otherwise random colors are used.

Use `radius` to specify the radius of the Poincaré disk when
drawing points.
"""
function draw_tiling(tiles;
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O,
        action::Symbol = :fill,
        colors = nothing
    )
    for (vertices, generation) in tiles
        if colors === nothing
            randomhue()
        else
            sethue(colors[iseven(generation) ? 1 : 2])
        end
        hyperbolic_poly(vertices; 
            radius = radius, 
            diskcenter = diskcenter, 
            action = action)
    end
    return nothing
end

end