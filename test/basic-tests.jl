using Test
using PoincareDisk
using Luxor
using Colors
using Test

@testset "Basics" begin
    z = cis(0.5)
    @test isapprox(complex_to_point(z), Point(258.8, 141.43), atol = 0.1)
    @test isapprox(point_to_complex(Point(258.8, 141.43)), z, atol = 0.01)
end


@testset "geometry" begin
    # hyperbolic_point() = requires a current Luxor drawing!
    Drawing(600, 600, :png)
    z = cis(0.5)
    @test isapprox(hyperbolic_point(z), Point(258.88685, 141.4305), atol = 0.1)

    z1 = 0.0 + 0.0im
    z2 = 0.75 + 0.35im
    z3 = -0.6 + 0.5im
    z4 = 0.6 - 0.4im
    z5 = -0.85 - 0.15im
    z6 = 0.8 - 0.05im
    R = 200
    h1 = hyperbolic_line(z1, z2; radius = R)
    h2 = hyperbolic_line(z3, z4; radius = R)
    h3 = hyperbolic_line(z5, z6; radius = R)

    @test length(h1) == 2
    @test length(h2) == 60
    @test length(h3) == 60

    # hyperbolic_circle()
    z = cis(0.2) / 2
    a1, a2 = hyperbolic_circle(z, 0.2)
    @test isapprox(a1, Point(121.37, 6.97), atol = 0.1)
    @test isapprox(a2, Point(165.58, 51.19), atol = 0.1)

    # hyperbolic_poly()
    hp = hyperbolic_poly([z1, z2, z3, z4, z5, z6])
    @test length(hp) == 159
    @test hp[1] == Point(0.0, 0.0)

    # hyperbolic_distance()
    @test isapprox(hyperbolic_distance(z1, z2), 2.36124, atol = 0.01)
    @test isapprox(hyperbolic_distance(z1, z3), 2.0959, atol = 0.01)

    # hyperbolic_reflect() is INTERNAL
    @test isapprox(PoincareDisk.hyperbolic_reflect(z1, z2, z3), 0.065 + 0.51im, atol = 0.01)

    # mobius_to_origin()
    @test isapprox(PoincareDisk.mobius_to_origin(z1, z1), 0.0 + 0.0im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_to_origin(z1, z2), -0.75 - 0.35im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_to_origin(z1, z3), 0.6 - 0.5im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_to_origin(z1, z4), -0.6 + 0.4im, atol = 0.01)

    # mobius_from_origin()
    @test isapprox(PoincareDisk.mobius_from_origin(z1, z2), 0.75 + 0.35im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_from_origin(z1, z3), -0.6 + 0.5im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_from_origin(z1, z4), 0.6 - 0.4im, atol = 0.01)
    @test isapprox(PoincareDisk.mobius_from_origin(z2, z4), 0.881 - 0.381im, atol = 0.01)

    # regular_hyperbolic_polygon_vertices
    reg_hyup = regular_hyperbolic_polygon_vertices(5, 10)
    @test reg_hyup isa Vector{ComplexF64}
    @test length(reg_hyup) == 5

    # geodesic_support()
    @test PoincareDisk.geodesic_support(z1, z2)[1] == :diameter
    @test isapprox(PoincareDisk.geodesic_support(z1, z2)[2], 0.436, atol = 0.01)
    @test PoincareDisk.geodesic_support(z1, z2)[3] == 0.0

    @test PoincareDisk.geodesic_support(z1, z3)[1] == :diameter
    @test isapprox(PoincareDisk.geodesic_support(z1, z3)[2], 2.446, atol = 0.01)
    @test PoincareDisk.geodesic_support(z1, z3)[3] == 0.0

    @test PoincareDisk.geodesic_support(z1, z4)[1] == :diameter
    @test isapprox(PoincareDisk.geodesic_support(z1, z4)[2], -0.588, atol = 0.01)
    @test PoincareDisk.geodesic_support(z1, z4)[3] == 0.0

    @test PoincareDisk.geodesic_support(z1, z5)[1] == :diameter
    @test isapprox(PoincareDisk.geodesic_support(z1, z5)[2], -2.966, atol = 0.01)
    @test PoincareDisk.geodesic_support(z1, z5)[3] == 0.0

    @test PoincareDisk.geodesic_support(z1, z6)[1] == :diameter
    @test isapprox(PoincareDisk.geodesic_support(z1, z6)[2], -0.062, atol = 0.01)
    @test PoincareDisk.geodesic_support(z1, z6)[3] == 0.0

    finish()
end

@testset "tiling" begin
    # hyperbolic_tiling()

    d = Drawing(600, 600, :png)
    origin()

    @test_throws "p and q must satisfy the relation" hyperbolic_tiling(3, 3)
    tiling = hyperbolic_tiling(3, 7)
    @test length(tiling) == 298

    # first element of tiling is tuple
    @test all(v -> typeof(v) <: Complex, tiling[1][1])
    @test tiling[1][2] == 0

    # draw_poincare_disk()
    draw_poincare_disk(action = :fill)
    pd = draw_poincare_disk(action = :stroke)
    @test isapprox(pd[1], Point(-295, -295))
    @test isapprox(pd[2], Point(295, 295))
    tiles = hyperbolic_tiling(3, 7)
    draw_tiling(tiles, steps = 20)
    @test finish() == true
    preview()

    return d
end

function visualtest()
    return @png begin # hide
        background("black")
        sethue("grey5")
        draw_poincare_disk(action = :fill)
        sethue("white")
        setline(2)
        tiles = hyperbolic_tiling(3, 7, hcenter = 0.000001 + 0im, depth = 8)
        setmesh(mesh(box(BoundingBox()), ["red", "green", "yellow"]))
        setfillrule(:even_odd)
        for (tile, _) in tiles
            pc = polycentroid(complex_to_point.(tile))
            poly(complex_to_point.(tile), close = true, :path)
            strokepath()
            d = distance(O, pc)
            circle.(complex_to_point.(tile), rescale(d, 0, 200, 20, 6), :fill)
        end
    end 600 600 "hyperdotty.png"
end
## quick visual test

if get(ENV, "POINCAREDISK_KEEP_TEST_RESULTS", false) == "true"
    cd(mktempdir(cleanup = false))
    @info("...Keeping the results in: $(pwd())")
    visualtest()
    @info("Test images were saved in: $(pwd())")
else
    mktempdir() do tmpdir
        cd(tmpdir) do
            @info("running tests in: $(pwd())")
            @info("but not keeping the results")
            @info("because you didn't do: ENV[\"POINCAREDISK_KEEP_TEST_RESULTS\"] = \"true\"")
            visualtest()

            @info("Test images weren't saved. To see the test images, next time do this before running:")
            @info(" ENV[\"POINCAREDISK_KEEP_TEST_RESULTS\"] = \"true\"")
        end
    end
end
