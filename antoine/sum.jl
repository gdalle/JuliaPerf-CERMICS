using BenchmarkTools
using PyPlot
using LoopVectorization

function mysum_unstable(a)
    s = 0
    for i = 1:length(a)
        s += a[i]
    end
    s
end
function mysum(a)
    s = zero(eltype(a))
    for i = 1:length(a)
        s += a[i]
    end
    s
end
function mysum_simd(a)
    s = zero(eltype(a))
    @simd for i = 1:length(a)
        s += a[i]
    end
    s
end
function mysum_LV(a)
    s = zero(eltype(a))
    @turbo for i ∈ eachindex(a)
        s += a[i]
    end
    s
end

function flops_f(N, f)
    a = randn(N)
    1 / (@belapsed $f($a) seconds=.1) * N
end

Ns = floor.(Int, 10 .^ (1:8))
Ns = floor.(Int, 10 .^ range(.5, 9, length=20))

figure()
for f in (sum, mysum_unstable, mysum, mysum_simd, mysum_LV)
    loglog(8Ns, flops_f.(Ns, f), "-x", label="$f")
end


BLAS.set_num_threads(1)
loglog(8Ns, peakflops() * ones(length(Ns)), "-k", label="peakflops")

using STREAMBenchmark
bw = memory_bandwidth(write_allocate=false)[1] #MB/s
loglog(8Ns, bw*1e6/8 * ones(length(Ns)), "--k", label="bandwidth")
xlabel("mem")
ylabel("FLOPS")
legend()

# get from sudo dmidecode -t cache
axvline(256*1024)
axvline(1024*1024)
axvline(8192*1024)

# @code_native debuginfo = :none mysum_unstable(randn(10)) 
# @code_native debuginfo = :none mysum(randn(10))
# @code_native debuginfo = :none mysum_simd(randn(10))
# @code_native debuginfo = :none mysum_LV(randn(10))
