using BenchmarkTools
function compute!(x)
    for i in 1:length(x)
        @inbounds x[i] = 1.1*i*i + 2.2*i + 3.3
    end
end
function compute_2!(x)
    Z = 1.1+2.2
    Y = 3.3
    for i in 1:length(x)
        @inbounds x[i] = Y
        Y += Z
        Z += 2.2
    end
end

x = randn(1_000_000)
@btime compute!(x)
@btime compute_2!(x)
