struct Params_SV{ComplexArray,Total,KF}
    # boundary conditions
    periodic::Bool
    # normalization
    total::Total


    # algorithm-specific
    # gradient kernel
    kernelfactor::KF

    # fft buffers
    complex_surface::ComplexArray
    complex_void::ComplexArray
end


function Params_SV(img; periodic::Bool=true, kernelfactor=KernelFactors.sobel)
    box = size(img)
    complex_box = periodic ? box : box .* 2

    # scale factor
    total = cnt_total(img, periodic)

    p = Params_SV(
        periodic,
        total,
        kernelfactor,
        similar(img, ComplexF32, complex_box),
        similar(img, ComplexF32, complex_box)
    )
    cf_type = :full
    p, cf_type
end


"""
    correllation_function!(res, img, params::Params_SV)

Compute surface-void correlation function in positive directions
"""
function correllation_function!(res, img, params::Params_SV)
    ix = CartesianIndices(img)

    f = params.complex_surface .= 0
    g = params.complex_void .= 0
    v_f = view(f, ix)
    v_g = view(g, ix)
    v_f .= gradient_norm(img, params.kernelfactor)
    v_g .= img .== 0

    cross_correlation!(f, g)

    res .= real.(v_f) ./ params.total
end


"""
    surfvoid(image; periodic = false)

Calculate `Fsv(x)` (surface-void) correlation function map
for the N-dimensional image and return a `CFMap` object.

The `image` contains the probability of the voxel being in the correct phase.

# Examples
```jldoctest
julia> surfvoid([1 0; 0 1]; periodic=true).result
3×3 Matrix{Float32}:
 0.176777  0.176777  0.176777
 0.176777  0.176777  0.176777
 0.176777  0.176777  0.176777
```
"""
function surfvoid(image; periodic::Bool=false, kernelfactor=KernelFactors.sobel)
    corr_function_map(image, Params_SV; periodic, kernelfactor)
end


function surfvoid(image, phase::Int; periodic::Bool=false, kernelfactor=KernelFactors.sobel)
    one_phase_img = image .== phase
    corr_function_map(one_phase_img, Params_SV; periodic, kernelfactor)
end