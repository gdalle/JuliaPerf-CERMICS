function my_matmul(C, A, B)
    @assert size(A, 2) == size(B, 1)
    # C = zeros(eltype(A), size(A, 1), size(B, 2))
    for i = 1:size(A, 1)
        for j = 1:size(B, 2)
            for k = 1:size(A, 2)
                C[i, j] += A[i, k]*B[k, j]
            end
        end
    end
    C
end

BLAS.set_num_threads(1)
function blas_matmul(C, A, B)
    mul!(C, A, B)
end

function flops_f(N, f)
    A = randn(N, N)
    B = randn(N, N)
    C = randn(N, N)
    1 / (@belapsed $f($C, $A, $B) seconds=.1) * N^3 * 2
end

Ns = floor.(Int, 10 .^ range(.5, 3, length=10))

figure()
for f in (my_matmul, blas_matmul)
    loglog(Ns, flops_f.(Ns, f), "-x", label="$f")
end
xlabel("N")
ylabel("flops")
axhline(peakflops(), label="peakflops")
legend()
