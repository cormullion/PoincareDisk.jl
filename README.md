# PoincareDisk.jl

![Monsieur Poincaré](docs/src/assets/mrpoincare.png)

This package is a simple introduction to the Poincaré disk. This is a model of two-dimensional hyperbolic geometry in which all points are inside the unit disk. It was popularized by French mathematician Henri Poincaré (1854–1912).

[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://cormullion.github.io/PoincareDisk.jl/stable) [![Docs workflow Status](https://github.com/cormullion/PoincareDisk.jl/actions/workflows/documentation.yml/badge.svg?branch=master)](https://github.com/cormullion/PoincareDisk.jl/actions/workflows/documentation.yml?query=branch%3Amaster) [![Coverage](https://codecov.io/gh/cormullion/PoincareDisk.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cormullion/PoincareDisk.jl) 

## Quick start

```julia
using PoincareDisk, Luxor
@draw begin
    background("black")
    sethue("grey5")
    draw_poincare_disk(action = :fill)
    setline(2)
    draw_tiling(hyperbolic_tiling(3, 7, depth=12), 
        colors=["black", "white"])
end
```

![simple Poincaré tiling](docs/src/assets/simple-poincare.png)
