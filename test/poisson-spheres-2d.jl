function gencenters(side, λ)
    n = pois_rand(λ * side^2)
    return reduce(hcat, (rand(1:side, 2) for i in 1:n))
end

function gendisks(side, R, λ)
    spheres = zeros(Int8, (side + 2R + 1, side + 2R + 1))
    sphere  = zeros(Int8, (2R + 1, 2R + 1))
    centers = gencenters(side, λ)
    for i in -R:R
        for j in -R:R
            dist = i^2 + j^2
            if dist < R^2
                sphere[j+R+1, i+R+1] = 1
            end
        end
    end
    for center in (centers[:,i] for i in 1:size(centers,2))
        x = center[1]
        y = center[2]
        spheres[x:x + 2R, y:y + 2R] .|= sphere
    end
    return spheres[R+1:end-R-1, R+1:end-R-1]
end

function s2_theory(r, R, λ)
    tmp = r/(2R)
    tmp2 = (r > 2R) ? 2 : 2/π*(π + tmp*sqrt(1 - tmp^2) - acos(tmp))
    η = λ * π * R^2
    return exp(-η*abs(tmp2))
end

function l2_theory(r, R, λ)
    η = λ * π * R^2
    p = exp(-η)
    return p^(1 + 2r/(π*R))
end

function ss_theory(r, R, λ)
    if r < 2R
        A = 4R^2 - r^2
        B = acos(r/(2R))
        part = exp(-λ*(r*sqrt(A)/2 + 2π*R^2 - 2*B*R^2))
        return part * ((4A*B^2 - 8π*A*B + 4*π^2*A)*R^2*λ^2*r + 4*sqrt(A)*R^2*λ) / (A*r)
    else
        return (2π*λ*R)^2*exp(-2π*λ*R^2)
    end
end

function sv_theory(r, R, λ)
     if r < 2R
        A = 4R^2 - r^2
        B = acos(r/(2R))
        return 2R*λ*(π-B)exp(-sqrt(A)*r*λ/2 + 2B*R^2*λ - 2π*R^2*λ)
    else
        return 2π*R*λ*exp(-2π*λ*R^2)
    end
end

function pore_size_theory(r, R, λ)
    s(x) = 2π * x
    v(x) = π * x^2
    η  = v(R) * λ
    p  = exp(-η)
    s1 = s(r + R)
    v1 = v(r + R)
    return λ * s1 * exp(-λ * v1) / p
end

function chord_length_theory(r, R, λ)
    η = λ * π * R^2
    p = exp(-η)
    return 2η/(π*R)*p^(2r/(π*R))
end

mean_chord_length(R, λ) = 1/(2λ*R)

@testset "S2 on random overlapping disks generated by Poisson process" begin
    # Area = S^2, radius of a disk = R
    # Poisson parameter = λ
    S = 7000; R = 40; λ = 5e-5;

    f = mean ∘ s2
    calc = f(gendisks(S, R, λ), 0)
    theory = [s2_theory(r-1, R, λ) for r in 0:length(calc) - 1]

    err = relerr.(calc, theory)
    @test maximum(err) < 0.15
end

@testset "L2 on random overlapping disks generated by Poisson process" begin
    # Area = S^2, radius of a disk = R
    # Poisson parameter = λ
    S = 7000; R = 40; λ = 5e-5; N = 700

    calc = log.(mean(l2(gendisks(S, R, λ), 0; len = N)))
    theory = [(log ∘ l2_theory)(r-1, R, λ) for r in 0:N - 1]

    err = relerr.(calc, theory)
    @test maximum(err) < 0.15
end

@testset "SS on random overlapping disks generated by Poisson process" begin
    # Area = S^2, radius of a disk = R
    # Poisson parameter = λ
    S = 7000; R = 30; λ = 4e-4;

    f = mean ∘ surfsurf
    calc = f(gendisks(S, R, λ), 0)
    theory = [ss_theory(r, R, λ) for r in 0:length(calc) - 1]

    err = relerr.(calc, theory)
    # Surface-surface function with r < 2R has a discontinuity and two
    # points where it goes to +Inf. Do not test it.
    @test maximum(err[2R + 10:end]) < 0.15
end

@testset "Pore size on random overlapping disks generated by Poisson process" begin
    # Area = S^2, radius of a disk = R, Poisson parameter = λ
    S = 7000; R = 50; λ = 5e-5
    disks = gendisks(S, R, λ)

    calc = pore_size(disks; nbins = 20)
    edges = calc.edges[1]
    s = step(edges)
    theory = [integrate(x -> pore_size_theory(x, R, λ), n:0.05:n+s)
              for n in 0:s:s*(length(edges) - 2)]

    # Compare cummulative distributions instead of probability
    # densities because density is almost zero for big radii.
    calc_cdf = scan(calc.weights)
    theory_cdf = scan(theory)

    err = relerr.(calc_cdf, theory_cdf)
    @test maximum(err) < 0.1
end

@testset "Chord length on random overlapping disks generated by Poisson process" begin
    # Area = S^2, radius of a disk = R, Poisson parameter = λ
    S = 7000; R = 60; λ = 1e-4
    disks = gendisks(S, R, λ)

    calc, mc = chord_length(disks, 0; nbins = 35)
    edges = calc.edges[1]
    s = step(edges)
    theory = [integrate(x -> chord_length_theory(x, R, λ), n:0.05:n+s)
              for n in 0:s:s*(length(edges) - 2)]

    # Compare cummulative distributions instead of probability
    # densities because density is almost zero for big lengths.
    calc_cdf = scan(calc.weights)
    theory_cdf = scan(theory)

    err = relerr.(calc_cdf, theory_cdf)
    @test maximum(err) < 0.1
    @test relerr(mc, mean_chord_length(R, λ)) < 0.1
end
