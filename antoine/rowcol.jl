function sum_row(A)
    total_sum = 0.0
    for i = 1:size(A, 1)
        partial_sum = 0.0
        @simd for j = 1:size(A, 2)
            partial_sum += A[i, j]
        end
        total_sum += partial_sum
    end
    total_sum
end
function sum_col(A)
    total_sum = 0.0
    for j = 1:size(A, 2)
        partial_sum = 0.0
        @simd for i = 1:size(A, 1)
            partial_sum += A[i, j]
        end
        total_sum += partial_sum
    end
    total_sum
end

function flops_f(N, f)
    A = randn(N, N)
    1 / (@belapsed $f($A) seconds=.1) * N*N
end

Ns = floor.(Int, 10 .^ range(.5, 4, length=10))

figure()
for f in (sum_row, sum_col)
    loglog(Ns, flops_f.(Ns, f), "-x", label="$f")
end
xlabel("N")
ylabel("flops")
legend()
