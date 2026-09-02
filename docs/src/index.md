```@meta
CurrentModule = PoincareDisk
```

```@raw html
---
layout: home

hero:
  name: PoincareDisk.jl
  text: exploring the Poincaré Disk
  tagline: hyperbolic graphics on the Poincaré disk
  actions:
    - theme: brand
      text: Basic usage
      link: /basics.html
    - theme: alt
      text: View on GitHub
      link: https://github.com/cormullion/PoincareDisk.jl
  image:
    src: /assets/logo.png
    alt: logo; hyperbolic tiling on the Poincare disk
    dark: /assets/logo.png # optional: a variant for dark themes

features:
  - icon:
      light: /assets/icon1.svg
      dark: /assets/icon1.svg
      alt: graphic
      wrap: true
    title: Draw hyperbolic graphics
    details: "Draw various hyperbolic graphics on the Poincaré disk. Use Luxor.jl to control the appearance and style of the output."
    link: /basics.html
  - icon:
      light: /assets/icon2.svg
      dark: /assets/icon2.svg
      alt: colorful graphic
      wrap: true
    title: Hyperbolic lines, circles, and polygons
    details: "You can draw various kinds of hyperbolic graphics - lines, circles, and polygons."
    link: /basics.html
  - icon:
      light: /assets/icon3.svg
      dark: /assets/icon3.svg
      alt: hyperbolic graphics
      wrap: true
    title: Hyperbolic tilings
    details: "Draw various hyperbolic tilings on the disk."
    link: /tiling.html
---
```

# Introduction

[PoincareDisk](https://github.com/cormullion/PoincareDisk.jl) is a little Julia package that lets you draw graphics on the Poincaré disk. It uses [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl) to make graphics. 

# Installation

This package isn't registered. Install by typing this in the Julia REPL:

```julia-repl
julia> import("Pkg")
julia> Pkg.add("https://github.com/cormullion/PoincareDisk")
```

## Documentation

This documentation was built using [Documenter.jl](https://github.com/JuliaDocs).

```@example
using Dates # hide
println("Documentation built $(Dates.now()) with Julia $(VERSION) on $(Sys.KERNEL)") # hide
```
