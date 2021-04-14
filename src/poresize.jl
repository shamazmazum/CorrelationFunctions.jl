"""
    pore_size(array[, phase]; nbins = 10)

Calculate pore size correlation function for the multiphase system
`array`. Pore size correlation function `P(x)` equals to probability
of inserting a ball with radius `R ∈ [x, x + δx]` into a system so
that it lies entirely in the phase `phase`.

This implementation divides the range of possible radii into `nbins`
subranges and returns a normalized histogram of radii.

This is roughly equal to integrating `P(x)` for each subrange.
"""
function pore_size(array :: AbstractArray,
                   phase = 0;
                   nbins :: Integer = 10)
    indicator = map(x -> x != phase, array)
    distances = indicator |> feature_transform |> distance_transform
    distances = filter(x -> x != 0, distances)
    hist = fit(Histogram, distances; nbins = nbins)
    return normalize(hist; mode = :probability)
end
