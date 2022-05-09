using BenchmarkTools
using PyPlot
using LoopVectorization

function mysum_LV(a)
    s = zero(eltype(a))
    @turbo for i ∈ eachindex(a)
        s += a[i]
    end
    s
end
function mysum_LV_f(a)
    s = zero(eltype(a))
    @turbo for i ∈ eachindex(a)
        s += exp(cos(sin(cos(exp(a[i])))))
    end
    s
end

function mysum_threads(a, nthreads=Threads.nthreads(), sum_fun=mysum_LV)
    N = length(a)
    chunk_length = cld(N, nthreads)
    s_arr = zeros(eltype(a), nthreads)
    @sync for (ichunk, chunk) in enumerate(Iterators.partition(1:N, chunk_length))
        Threads.@spawn begin
            s_arr[ichunk] = sum_fun(@views a[chunk])
        end
    end
    sum(s_arr)
end
mysum_nothreads(a) = mysum_threads(a, 1)
mysum_threads_f(a) = mysum_threads(a, Threads.nthreads(), mysum_LV_f)
mysum_nothreads_f(a) = mysum_threads(a, 1, mysum_LV_f)

function flops_f(N, f)
    println("$f $N")
    a = randn(N)
    1 / (@belapsed $f($a) seconds=.1) * N
end

Ns = floor.(Int, 10 .^ (1:8))
Ns = floor.(Int, 10 .^ range(.5, 9, length=20))

for funs in ((mysum_LV, mysum_threads, mysum_nothreads), (mysum_LV_f, mysum_threads_f, mysum_nothreads_f))
    figure()
    for f in funs
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
end
