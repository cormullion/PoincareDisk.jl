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
    regular_hyperbolic_polygon_vertices

# default radius of the unit disk
# this is smaller than the default Luxor drawing
# width, so that it fits automatically
const DEFAULT_DISK_RADIUS = 295.0  

"""
    complex_to_point(z; radius=DEFAULT_DISK_RADIUS, diskcenter=O)

Convert a point `z` on the unit disk (a complex number with
|z| < 1) into a `Point` on the Luxor drawing, 
scaling by `radius` and shifting so the disk is centered at 
`diskcenter`.

Uses the global constant `DEFAULT_DISK_RADIUS`.

"""
complex_to_point(z::Complex; radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O) =
    Point(diskcenter.x + real(z) * radius, diskcenter.y + imag(z) * radius)

"""
    point_to_complex(p::Point; radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O)

Convert Luxor point `p` into a coordinate on the Poincaré disk.

Uses the global constant `DEFAULT_DISK_RADIUS`.
"""
point_to_complex(
    p::Point;
    radius::Real = DEFAULT_DISK_RADIUS,
    diskcenter::Point = O) =
    Complex((p.x - diskcenter.x) / radius, (p.y - diskcenter.y) / radius)

"""
    mobius_to_origin(z, az)

Apply a Möbius transformation that maps the unit disk to
itself, effectively "recentering" the disk so that the point
`a` moves to the origin 0, while everything stays inside the
unit disk. Angles at each point are preserved. 
"""
mobius_to_origin(z, a) = (Complex(z) - a) / (1 - conj(a) * Complex(z))

"""
    mobius_from_origin(wz, az)

Find the inverse of the `mobius_to_origin()` function: ie send `0` to `a`.
"""
mobius_from_origin(w, a) = (Complex(w) + a) / (1 + conj(a) * Complex(w))

"""
    hyperbolic_distance(az, bz)

Find the hyperbolic distance between two points on the (Poincaré disk.
"""
hyperbolic_distance(a, b) =
    2atanh(abs((Complex(a) - Complex(b)) / (1 - conj(Complex(a)) * Complex(b))))

"""
    _arc_angles_avoiding(theta_a, theta_b, theta_x; steps=60)

Make `steps` angles sweeping around a circle from `theta_a` to
`theta_b`, taking whichever of the two possible directions
does *not* pass through `theta_x`. The result starts
at `theta_a` and ends at `theta_b`,
regardless of which direction was used internally, since
the functions that call this rely on that to stitch consecutive 
edges together.
"""
function _arc_angles_avoiding(theta_a, theta_b, theta_x; steps::Int = 60)
    s = mod2pi(theta_a)
    e = mod2pi(theta_b)
    e = e < s ? e + 2π : e
    x = mod2pi(theta_x)
    x = x < s ? x + 2π : x
    if s <= x <= e
        # direct sweep a -> b passes the excluded angle: use
        # the complementary arc instead (built b -> a), then
        # reverse it back to a -> b order
        s2 = mod2pi(theta_b)
        e2 = mod2pi(theta_a)
        e2 = e2 < s2 ? e2 + 2π : e2
        return reverse(range(s2, e2, length = steps))
    else
        return range(s, e; length = steps)
    end
end

"""
    _geodesic_points(a, b; radius=DEFAULT_DISK_RADIUS, diskcenter=O, steps=60)

Return sampled `Point`s along the hyperbolic geodesic
segment joining disk points `a` and `b`. 

This handles the degenerate diameter case (a, b and the origin
collinear) by returning just the two endpoints.
"""
function _geodesic_points(
        a, b;
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O, steps::Int = 60
    )
    a, b = Complex(a), Complex(b)
    (abs(a) >= 1 || abs(b) >= 1) && error(
        """_geodesic_points():
        The geodesic endpoints must satisfy |z| < 1. You have supplied
        $(abs(a)) and $(abs(b))).
        """
    )

    # a, b and 0 collinear  <=>  Im(conj(a) b) == 0  -> geodesic is a diameter
    if abs(imag(conj(a) * b)) < 1.0e-9
        return [
            complex_to_point(a; radius = radius, diskcenter = diskcenter),
            complex_to_point(b; radius = radius, diskcenter = diskcenter),
        ]
    end

    ainv = 1 / conj(a)   # inversion of a in the unit circle
    p1 = complex_to_point(a; radius = radius, diskcenter = diskcenter)
    p2 = complex_to_point(b; radius = radius, diskcenter = diskcenter)
    p3 = complex_to_point(ainv; radius = radius, diskcenter = diskcenter)

    center, r = center3pts(p1, p2, p3)
    theta_a = angle(Complex(p1.x - center.x, p1.y - center.y))
    theta_b = angle(Complex(p2.x - center.x, p2.y - center.y))
    theta_x = angle(Complex(p3.x - center.x, p3.y - center.y))

    angles = _arc_angles_avoiding(theta_a, theta_b, theta_x; steps = steps)
    return [Point(center.x + r * cos(t), center.y + r * sin(t)) for t in angles]
end

"""
    draw_poincare_disk(; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke)

Draw the boundary circle of the Poincaré disk itself.
"""
draw_poincare_disk(;
    radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O,
    action::Symbol = :stroke
) = circle(diskcenter, radius, action)


"""
    hyperbolic_point(z; 
        radius=DEFAULT_DISK_RADIUS, 
        dotradius = 5, 
        diskcenter=O)

Draw the hyperbolic point at complex number `z` using a small
circle of `dotradius` units.
Returns the sampled `Point` used to draw it.
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
    hyperbolic_line(z1, z2; radius=DEFAULT_DISK_RADIUS, diskcenter=O, action=:stroke, steps=60)

Makes the hyperbolic geodesic segment between disk points `z1`
and `z2` (complex numbers), and apply `action`. 

Returns the sampled `Point`s used to draw it.
"""
function hyperbolic_line(
        z1, z2; radius::Real = DEFAULT_DISK_RADIUS, diskcenter::Point = O,
        action::Symbol = :stroke, steps::Int = 60
    )
    pts = _geodesic_points(z1, z2; radius = radius, diskcenter = diskcenter, steps = steps)
    return poly(pts, action, close = false)
end

"""
    hyperbolic_circle(center, rho; radius=DEFAULT_DISK_RADIUS, diskcenter=O, action=:stroke)

Draw the hyperbolic circle of hyperbolic radius `rho`
centered at disk point `center`. 

The `action` is applied, and the function returns the 
center and radius as points on the drawing. These aren't the same as
`center`/`rho` themselves, since hyperbolic circles are
off-center, undersized Euclidean circles, unless when
centered at the origin.
"""
function hyperbolic_circle(
        center, rho; radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O,
        action::Symbol = :stroke
    )
    c = Complex(center)
    abs(c) >= 1 && error("hyperbolic circle center must satisfy |z| < 1")
    rho <= 0 && error("hyperbolic radius must be positive")

    s = tanh(rho / 2)                       # Euclidean radius once c is moved to 0
    phis = (0.0, 2pi / 3, 4pi / 3)           # 3 sample points determine the circle exactly
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

"""
    hyperbolic_poly(vertices; 
        radius=DEFAULT_DISK_RADIUS, 
        diskcenter=O, 
        action=:stroke, 
        steps=40)

Construct the closed hyperbolic polygon with the given (>= 3)
disk-point `vertices`, each consecutive pair joined by a
geodesic edge. `steps` controls how finely each curved edge is
sampled. Apply `action`.

Returns all the sampled boundary points.

The key fact used to build a geodesic between two points `a`
and `b` on the Poincare disk is that the unique circle
orthogonal to the unit circle that passes through `a` and
`b` also passes through `a* = 1/conj(a)`, the inversion of
`a` in the unit circle. The geodesic circle
is the circle through 3 points (`(a, b, a*)` as used in 
`Luxor.center3pts()`.

For hyperbolic circles, the hyperbolic center moves to the
origin with a disk automorphism (Möbius map), where a
hyperbolic circle of radius `rho` is the Euclidean circle of
radius `tanh(rho/2)`. Three points of that circle are mapped
back with the inverse Möbius map, and the resulting circle
can be drawn directly with `circle()`.
"""
function hyperbolic_poly(
        vertices::AbstractVector{<:Number};
        radius::Real = DEFAULT_DISK_RADIUS,
        diskcenter::Point = O,
        action::Symbol = :stroke,
        steps::Int = 40
    )
    verts = Complex.(vertices)
    m = length(verts)
    m < 3 && error("a polygon needs at least 3 vertices")

    allpts = Point[]
    for i in 1:m
        a, b = verts[i], verts[mod1(i + 1, m)]
        edgepts = _geodesic_points(a, b; radius = radius, diskcenter = diskcenter, steps = steps)
        append!(allpts, i == 1 ? edgepts : edgepts[2:end])
    end
    pts = poly(allpts, action, close = true)
    return pts
end

"""
    regular_hyperbolic_polygon_vertices(nsides, rho; hcenter=0.0+0.0im, rotation=0.0)

Vertices of a regular hyperbolic `nsides`-gon inscribed in
the hyperbolic circle of radius `rho` centered at `hcenter`,
with the first vertex placed at angle `rotation`. Handy for
feeding straight into `hyperbolic_poly`, or for building tilings
by repeated Möbius transforms.
"""
function regular_hyperbolic_polygon_vertices(
        nsides::Integer, rho::Real; hcenter::Complex = 0.0 + 0.0im,
        rotation::Real = 0.0
    )
    s = tanh(rho / 2)
    hc = Complex(hcenter)
    return [mobius_from_origin(s * cis(rotation + (2π * (k - 1) / nsides)), hc) for k in 1:nsides]
end

"""
    geodesic_support(a, b)

The circle (or line) supporting the geodesic through disk
points `a`, `b`, in the same unscaled math coordinates as
`a`,`b` themselves (|z| < 1). Returns `(:diameter, theta,
0.0)` for a diameter at angle `theta`, or `(:circle, center,
r)` for the orthogonal circle otherwise.
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
through `a` and `b`. This is the hyperbolic isometry used to
generate a tiling from one fundamental polygon. Reflecting a
tile's vertices (and its center) across one of its edges
produces the neighboring tile across that edge.
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

Generates data for the hyperbolic tiling of polygons with `p` sides,
with `q` lines joining at each vertex when restricted to the
Poincaré disk.

Returns an array where each element contains:

- an array of complex numbers (the coordinates of each side the hyperpolygon)

- the tile's generation number

`p` and `q` must satisfy `1/p + 1/q < 1/2` (the hyperbolic condition). 
Most of the simpler tilings are listed in this table:

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

The fundamental polygon is a regular `p`-gon centered at
`hcenter`. `rho` (`rho = acosh(cot(π / p) * cot(π / q))`) is the
hyperbolic circumradius of one of these regular polygons,
the distance (in hyperbolic space) from the center of
the polygon to one of its vertices. The interior angle of each polygon is `2π/q`.

The rest of the tiling is built breadth-first by reflecting
each known tile across each of its edges. A hyperbolic
reflection is an inversion in the edge's supporting circle,
skipping any tile whose center has already been seen, up to
`depth` reflection-generations, or `maxtiles` tiles.

A reflection across a geodesic is an inversion in that
geodesic's supporting circle. This reuses the same
circle-through-three-points technique as the geodesic
drawing. 

Duplicate tiles are pruned by tracking each tile's
hyperbolic center.
"""
function hyperbolic_tiling(
        p, q; depth = 8,
        hcenter::Number = 0.0 + 0.0im, rotation::Real = 0.0,
        maxtiles::Integer = 4000
    )
    (1 / p + 1 / q) >= 1 / 2 && error("hyperbolic_tiling(): ($p, $q) is not hyperbolic: 
    p and q must satisfy the relation `1/p + 1/q < 1/2`")
    rho = acosh(cot(π / p) * cot(π / q))
    # shorten complex key to assist "have we visited this?" 
    # vertex already set membership
    # stay alert for signed zero ( isequal(-0.0, 0.0) = false) )
    key(z::Complex) = (round(real(z), digits = 4) + 0.0, round(imag(z), digits = 4) + 0.0)
    hc = Complex(hcenter)
    v1 = ComplexF64.(regular_hyperbolic_polygon_vertices(p, rho; hcenter = hc, rotation = rotation))
    # initial tile
    tiles = [(v1, 0)]
    visited = Set{Tuple{Float64, Float64}}([key(hc)])
    frontier = [(v1, hc)]
    generation = 1
    while generation <= depth && !isempty(frontier) && length(tiles) < maxtiles
        newfrontier = Vector{Tuple{Vector{ComplexF64}, ComplexF64}}()
        for (vertices, center) in frontier
            m = length(vertices)
            for i in 1:m
                a, b = vertices[i], vertices[mod1(i + 1, m)]
                newcenter = hyperbolic_reflect(center, a, b)
                k = key(newcenter)
                k in visited && continue
                push!(visited, k)
                newvertices = ComplexF64[hyperbolic_reflect(v, a, b) for v in vertices]
                any(abs.(newvertices) .>= 0.99999999) && continue # keep away from the boundary
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
        action=:stroke, 
        steps=16, 
        colors=nothing)

An example function to draw a hyperbolic tiling.
    
Draw every polygon in the list of tiles produced by 
`hyperbolic_tiling()`.

If `colors` is given (a 2-element array, e.g.
`["white","gray90"]`), tiles are drawn, alternating color by
generation number. This gives a proper checkerboard
coloring whenever `q` (from `(p, q)`) is even.
"""
function draw_tiling(tiles; 
    radius::Real = DEFAULT_DISK_RADIUS, 
    diskcenter::Point = O,
    action::Symbol = :stroke, steps::Int = 16, colors = nothing
    )
    tilenumber = 1
    for (vertices, generation) in tiles
        if colors === nothing
            randomhue()
            hyperbolic_poly(vertices; radius = radius, diskcenter = diskcenter, action = action, steps = steps)
        else
            sethue(colors[iseven(generation) ? 1 : 2])
            hyperbolic_poly(vertices; radius = radius, diskcenter = diskcenter, action = :fill, steps = steps)
        end
        tilenumber += 1
    end
    return
end

end
