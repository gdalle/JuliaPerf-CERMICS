### A Pluto.jl notebook ###
# v0.18.4

using Markdown
using InteractiveUtils

# ╔═╡ f5231f65-da94-4ed3-af65-857edb42ee08
begin
	using BenchmarkTools
	using JET
	using PlutoProfile
	using PlutoUI
	using Profile
	using ProfileCanvas
	using ProgressLogging
end

# ╔═╡ 5de2a556-f3af-4a64-a5c6-32d30f758be3
TableOfContents()

# ╔═╡ e1852c8d-4028-409e-8e1a-8253bbd6e6a5
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 1ac5ba38-0eef-41bb-8f9c-3bbf057cae21
VERSION

# ╔═╡ 9331fad2-f29e-11eb-0349-477bd2e7e412
md"""
# Monitoring code performance

Before trying to improve the efficiency of our code, it is essential to analyze it and locate potential improvements.
"""

# ╔═╡ 3d98e7db-c643-4500-987d-4a225e55b2a5
md"""
## Tracking loops

In long-running code, the best way to track loops is not a periodic `println(i)`. There are packages designed for this purpose, such as [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl).
However, since the REPL doesn't work well in Pluto notebooks, we can use the `@progress` macro of [ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl) instead.
"""

# ╔═╡ b4f2a99e-de45-49d2-be86-9f2d03357462
@progress for i in 1:10
	sleep(0.2)
end

# ╔═╡ 068b3e45-5105-48aa-a547-536470f6abda
md"""
Julia also has a built-in [logging system](https://docs.julialang.org/en/v1/stdlib/Logging/) which Pluto natively understands.
"""

# ╔═╡ 7a75c990-46b4-484e-acc4-65e34f41a9f2
for i in 1:10
	if i % 2 == 0
		@info "Even integer" i
	else
		@warn "Odd integer" i
	end
end

# ╔═╡ f7b1b44f-2aa6-4c5c-97a2-ac7037fb48ce
md"""
## Benchmarking

To evaluate the efficiency of a function, we need to know how long it takes and how much memory it uses. Base Julia includes macros for these things:
- `@elapsed` returns the computation time (in seconds)
- `@allocated` returns the allocated memory (in bytes)
- `@time` prints both (in the REPL!) and returns the function result
"""

# ╔═╡ 1fb43343-083b-4b1a-b622-d88c9aa0808c
@elapsed exp(rand(100, 100))

# ╔═╡ a28f7911-3dbb-45fb-a82d-2834d3c8502c
@allocated exp(rand(100, 100))

# ╔═╡ 4da8a7ca-3cea-4629-a66d-44f3b907af09
@time exp(rand(100, 100));

# ╔═╡ c0a7c1fe-457f-4e52-b0ea-2821e40817ea
md"""
When dealing with short-running functions, we get a more accurate evaluation by running them repeatedly. This is what [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) does with the following macros:
- `@belapsed` for time
- `@ballocated` for memory
- `@benchmark` for both
When using them, it is important to [interpolate](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Interpolating-values-into-benchmark-expressions) the external (global) variables with a dollar sign to make sure they don't hurt performance.
"""

# ╔═╡ 834f6172-15bc-4e7d-ae22-e18ef2e8e22b
@benchmark exp(rand(100, 100))

# ╔═╡ 94c78148-c651-4a59-9e62-5c7e9576d1e8
md"""
## Profiling

Often, benchmarking is not enough, and we need to dig deep into the code to figure out what takes time and what.
This is what [profiling](https://docs.julialang.org/en/v1/manual/profile/) is about: all it does is run your function and ping it periodically to figure out in which subroutine it is. The ping count for each nested call gives a good approximation of the time spent in it, and can help you detect bottlenecks.
"""

# ╔═╡ c42e3aa8-48c7-4bb1-bb35-2301476e085b
md"""
Profiling results are easier to analyze with the help of a flame graph.
To generate one, we will use a Pluto adaptation of the `@profview` macro (which is [available in VSCode](https://www.julia-vscode.org/docs/stable/userguide/profiler/)).
Each layer of the flame graph represents one level of the call stack (the nested sequence of functions that are called by your code). The width of a tile is proportional to its execution time.
The first few layers are usually boilerplate code, and we need to scroll down to reach user-defined functions.
Special attention should be paid to the colors:
- blue means everything is fine
- yellow means "garbage collection" (usually a sign of excessive allocations)
- red means "runtime dispatch" (usually a sign of bad typing, we will come back to it).
"""

# ╔═╡ c44f3dc9-ff19-4ba4-9388-73cfaf23f8e8
@plutoprofview exp(rand(500, 500))

# ╔═╡ 0fb6ed33-601c-4392-b7d9-32230c979d39
md"""
# Improving code performance

Once we know which parts of our code take the most time, we can try to optimize them. The primary source for this section is the Julia language manual, more specifically its [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/), but I also used some other inspirations (by increasing order of complexity):
- [Julia for Data Science - performance tips](https://www.juliafordatascience.com/performance-tips/).
- [7 Julia gotchas and how to handle them](https://www.stochasticlifestyle.com/7-julia-gotchas-handle/)
- [What scientists must know about hardware to write fast code](https://viralinstruction.com/posts/hardware/)
"""

# ╔═╡ a6e9da76-1ff0-4b54-9b55-4856ca32b251
md"""
## General advice

- Loops are often faster than vectorized operations, unlike in Python and R
- Avoid global variables (or turn them into constants with the keyword `const`)
"""

# ╔═╡ fa483fea-bf9f-4764-8d4f-c6d33e3336fb
md"""
### Memory allocations

- Prefer in-place operations
- Pre-allocate output memory
- Use views instead of slices (`view(A, :, 1)` instead of `A[:, 1]`) when you need to access sub-arrays without copying their values
"""

# ╔═╡ d3c1a86c-8c8f-4ad6-ac3c-2ba0f838d139
md"""
### Typing

Julia is fast when it can infer the type of each variable at compiletime (i.e. before runtime): we must help type inference when we can:
- Avoid using abstract types in strategic places: container initializations, field declarations
- Write type-stable code (make sure variable types do not change)
- Use `@code_warntype` or (better yet) [JET.jl](https://github.com/aviatesk/JET.jl) to debug type instabilities

"""

# ╔═╡ 43bad028-9d16-426f-9cdb-a37b1ee1a623
md"""
## Iterative workflow

We now illustrate the typical workflow of performance analysis and improvement.
Our goal will be to write function that computes the product $C = AB$ of two matrices $A \in \mathbb{R}^{m \times n}$ and $B \in \mathbb{R}^{n \times p}$, without using linear algebra routines.
Starting from a simple implementation, we will enhance it step by step until we are satisfied with its performance.
"""

# ╔═╡ 857509a7-f07a-4bf0-9383-207984b95faa
A, B = rand(200, 100), rand(100, 300);

# ╔═╡ 7386749b-b2ab-48a7-a1d2-46e7f31e72e3
md"""
### Version 1

Our first attempt aims at the simplest possible correct code, following the famous mantra
> Make it work, make it right, make it fast.
"""

# ╔═╡ 6cd86e7a-9f82-4da1-a8f0-4ed2c1068ab9
begin
	function matmul1(A, B)
		m, p = size(A, 1), size(B, 2)
		C = Matrix{Float64}(undef, m, p)
		for i = 1:m, j = 1:p
			C[i, j] = sum(A[i, :] .* B[:, j])
		end
		return C
	end
	
	@assert matmul1(A, B) ≈ A * B
end;

# ╔═╡ 382517ac-c4f5-45f1-bfe6-120e06c97b1c
md"""
There are two reasons we test our function right after defining it:
1. to ensure correctness
2. to get the compilation time of the first run out of the way, so it does not bias our analysis.
"""

# ╔═╡ 5d10a00b-bfa9-49c7-9f4b-503351fa2842
@benchmark matmul1($A, $B)

# ╔═╡ 38cc6383-c7d8-46b4-8531-251bd196d960
md"""
Is that a good performance? Can we do better? Hard to tell from the benchmark alone, which is why we need profiling.
"""

# ╔═╡ 62163e17-4265-4c97-95bb-29d608e80b07
@plutoprofview matmul1(A, B)

# ╔═╡ 9d8b7e25-c9c6-4aba-a33c-66fd18d804c0
md"""
Scrolling down the flame graph, we see that that `matmul1` spends a lot of time in the `Array` function, which triggers garbage collection.
This is caused by unnecessary allocations: when we do
```julia
C[i,j] = sum(A[i, :] .* B[:, j])
```
we create one copy of the row `A[i, :]`, one copy of the column `B[:, j]`, and a whole new vector to store their componentwise product.
"""

# ╔═╡ fe45168c-8cf1-435e-86fc-16cfffef3ec1
md"""
### Version 2

Our second version remedies this problem by computing the dot product manually.
"""

# ╔═╡ 0400175c-5a3c-44a7-9a8a-c30a4756b88c
begin
	function matmul2(A, B)
		m, n, p = size(A, 1), size(A, 2), size(B, 2)
		C = zeros(Float64, m, p)
		for i = 1:m, j = 1:p
			for k = 1:n
				C[i, j] += A[i, k] * B[k, j]
			end
		end
		return C
	end
	
	@assert matmul2(A, B) ≈ A * B 
end;

# ╔═╡ cd0cc22f-2d4d-4848-8f15-8f0127a4245b
@benchmark matmul2($A, $B)

# ╔═╡ 638de554-1bec-453d-9e30-796247aaa4cc
md"""
The running time is already improved: can we do even better?
"""

# ╔═╡ fd4401cf-69e8-4444-92c3-478035301006
@plutoprofview matmul2(A, B)

# ╔═╡ 23053665-e058-43de-95d9-c688e3a80b0c
md"""
This time we see that the main bottleneck is `setindex!`, which is used to modify components of an array. That is not very satisfying.
"""

# ╔═╡ 9a181530-02e7-47b0-9a86-c191baefac54
md"""
### Version 3

Our third version improves upon the previous one by only updating `C[i,j]` once instead of $n$ times.
"""

# ╔═╡ 159c8baa-fa34-4e9d-af09-774c625194fa
begin
	function matmul3(A, B)
		m, n, p = size(A, 1), size(A, 2), size(B, 2)
		C = Matrix{Float64}(undef, m, p)
		for i = 1:m, j = 1:p
			tmp = 0.
			for k = 1:n
				tmp += A[i, k] * B[k, j]
			end
			C[i, j] = tmp
		end
		return C
	end
	
	@assert matmul3(A, B) ≈ A * B 
end;

# ╔═╡ 610f6d6f-9d37-4f3d-be78-ab9847162f4d
@benchmark matmul3($A, $B)

# ╔═╡ c7b551a0-8c2e-4785-b575-8d58e37c14ec
md"""
Yet another performance gain! How far can we go?
"""

# ╔═╡ 2fabb4c0-5861-45f6-8972-c29e55804ca8
@plutoprofview matmul3(A, B)

# ╔═╡ bd8ab522-457f-4b9c-86b4-fa39b857ccbd
md"""
This last profile is pretty satisfying: most of the time is spent in the iteration and the sum, which is what we would expect. So we will stop there.
"""

# ╔═╡ fe734441-3a46-4b75-aba1-9c3c6519ad64
md"""
Note that this example was only for teaching purposes: of course, you should always use built-in linear algebra routines.
"""

# ╔═╡ 49327d40-31a1-47c8-abc2-4517478ca18f
@benchmark *($A, $B)

# ╔═╡ b186543b-aae1-4c96-a93d-8507a2a54805
md"""
## Other examples
"""

# ╔═╡ 9d1951b4-2bf3-4dd3-9ee2-ec8bb6b953f3
md"""
### Abstract types in containers
"""

# ╔═╡ 1067868e-2ca8-463f-bc55-c444aaf3b37c
md"""
We now illustrate the impact of abstract types within a struct.
"""

# ╔═╡ dacdb662-f46d-4032-a8b8-cdfbaf5317fc
abstract type Point end

# ╔═╡ 22b04135-f762-4331-8091-c8c3fa46655f
struct StupidPoint <: Point
    x::Real
    y::Real
end

# ╔═╡ 40d777cc-7cf0-44f7-b179-fe3abbf4e030
struct CleverPoint <: Point
    x::Float64
    y::Float64
end

# ╔═╡ bb734c3b-d981-4473-aa04-9262206ee746
struct GeniusPoint{CoordType <: Real} <: Point
    x::CoordType
    y::CoordType
end

# ╔═╡ 758b6eb0-f61d-4772-a270-f55fac65d56a
norm(p::Point) = sqrt(p.x^2 + p.y^2)

# ╔═╡ 262f7aa1-5072-4376-92db-4241370ec303
begin
	p_stupid = StupidPoint(1., 2.)
	p_clever = CleverPoint(1., 2.)
	p_genius = GeniusPoint(1., 2.)
end

# ╔═╡ f352b77a-4e83-4c84-bdcb-9d024b25673f
norm(p_stupid); @benchmark norm($p_stupid)

# ╔═╡ 9ce1abc9-5377-4fba-a059-3596cbdd3bcd
norm(p_clever); @benchmark norm($p_clever)

# ╔═╡ 44967cf2-8aff-4b85-aa4a-5833b9b29ab5
norm(p_genius); @benchmark norm($p_genius)

# ╔═╡ c1310939-87c2-405f-94d6-c7d1310ff700
md"""
We see that the last two implementations are almost two orders of magnitude faster, because they tell the compiler what to expect in terms of attribute types. Note that a `GeniusPoint` can have coordinates of any `Real` type, just like a `StupidPoint`, but the parametric typing makes inference easier.
"""

# ╔═╡ 1500ca48-f99c-4ea0-beb7-bcadedf11d23
with_terminal() do
	@code_warntype norm(p_genius)
end

# ╔═╡ 99df78f5-61ac-49b3-b5ad-5fe5cdeffec5
with_terminal() do
	@code_warntype norm(p_stupid)
end

# ╔═╡ 26c9d3a2-a54a-43d7-897e-64c34eeac81f
md"""
In the output of `@code_warntype`, the red annotations indicate types that could not be inferred with sufficient precision. Note that this only works for simple code: if you need to analyse nested functions, you will be better off with the macro `@report_opt` from JET.jl, which works in a similar way.
"""

# ╔═╡ b1d31667-46c8-406a-8d25-19802181f37f
@report_opt norm(p_stupid)

# ╔═╡ 44f17b4d-c498-4126-9647-4eceaa4a3f21
@report_opt norm(p_genius)

# ╔═╡ 5aee27ef-c3cf-43b0-b1fd-e058e90bf112
md"""
### Type instabilities
"""

# ╔═╡ e7c68548-a654-40dd-9b3a-10ce24b6cd5c
md"""
We now demonstrate the impact of type instabilities in functions.
"""

# ╔═╡ 735121ed-1563-4d1b-b5c2-f0c4d80e17a1
with_terminal() do
	@code_warntype matmul1(A, B)
end

# ╔═╡ b47ab7f4-82af-4f09-851e-2352093a0b71
function randsum_unstable(n)
    x = 1
    for i = 1:n
        x += rand()
    end
    return x
end

# ╔═╡ 21e5063b-3d55-4a25-88bb-1dc02322828b
function randsum_stable(n)
    x = 1.0
    for i = 1:n
        x += rand()
    end
    return x
end

# ╔═╡ 72421355-fac2-4c68-b9a3-f2c49a02c986
@benchmark randsum_unstable(100)

# ╔═╡ 908796b8-5880-4cbf-9102-92cbd39cae49
@benchmark randsum_stable(100)

# ╔═╡ 769a8892-1f5a-49ea-947d-dbef2262fd6e
md"""
In the unstable version, the variable `x` starts as an `Int` but becomes a `Float64` in the second loop iteration, which makes the compiler's life harder!
"""

# ╔═╡ 95e7dfdb-0bc0-4cb1-b4ad-f74b006af66c
with_terminal() do
	@code_warntype randsum_stable(1)
end

# ╔═╡ 48ae2243-bf72-4e2f-af0a-17bc377b44e4
with_terminal() do
	@code_warntype randsum_unstable(1)
end

# ╔═╡ b3be8a6e-c00f-413f-858e-aee32f32dd18
md"""
This time, JET.jl would not have caught it, probably since it considers a union type `Union{Float64, Int64}` to be successfully inferred, even though it hurts performance.
"""

# ╔═╡ 2b0f6c30-112e-45bc-a3ea-3da4012922a9
 @report_opt randsum_unstable(1)

# ╔═╡ 5d07342c-d4b4-4f3b-b523-514c0f252813
@report_opt randsum_stable(1)

# ╔═╡ fe04e854-1393-42fc-b6d7-6a4b3848e0ef
md"""
# Going further
"""

# ╔═╡ bc1695e8-12c2-4630-a630-a12c53943eb8
md"""
## Memory profiling

Julia 1.8 (which is still a [beta release](https://discourse.julialang.org/t/julia-v1-8-0-beta3-and-v1-6-6-lts-are-now-available/78820)) introduced many novelties.
One of the most significant is a built-in memory profiler, which mimics the behavior of the temporal profiler shown above.
It is still a bit [hard to use](https://github.com/JuliaLang/julia/issues/45268) but it can help diagnose which lines of code are responsible for the most allocations.
"""

# ╔═╡ ada6d5f4-f5fc-4c5f-9724-d29f4bb2a06a
md"""
## Package latency

A major source of frustration for Julia beginners is the time that elapses from the creation of the REPL until the first useful output, also called "time to first plot".
As a package developer, there are many resources available to help you address this problem:
- Tim Holy's great talk at JuliaCon 2021: [Package latency and what developers can do to reduce it](https://youtu.be/rVBgrWYKLHY)
- Several blog posts:
  - [Analyzing sources of compiler latency in Julia: method invalidations ](https://julialang.org/blog/2020/08/invalidations/)
  - [Tutorial on precompilation](https://julialang.org/blog/2021/01/precompile_tutorial/)
  - [Profiling type inference](https://julialang.org/blog/2021/01/snoopi_deep/)
"""

# ╔═╡ fdf97758-26c1-4157-a5d1-af89578f6277
md"""
## Generic programming

The key feature of Julia is multiple dispatch, which allows the right method to be chosen based on argument types. This is what makes it possible for multiple packages to work together seamlessly, but to achieve that we must remain as generic as possible:
- Do not overspecify input types
- Write smaller dispatchable functions instead of `if - else` blocks

This is explained in great detail by the blog post [Type-Dispatch Design: Post Object-Oriented Programming for Julia](https://www.stochasticlifestyle.com/type-dispatch-design-post-object-oriented-programming-julia/).
"""

# ╔═╡ 22d2d50e-8be2-4e1d-a1f7-8fd8d62b4a47


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
JET = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b"
PlutoProfile = "ee419aa8-929d-45cd-acf6-76bd043cd7ba"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Profile = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
ProfileCanvas = "efd6af41-a80b-495e-886c-e51b0c7d77a3"
ProgressLogging = "33c8b6b6-d38a-422a-b730-caa89a2f386c"

[compat]
BenchmarkTools = "~1.3.1"
JET = "~0.5.14"
PlutoProfile = "~0.3.0"
PlutoUI = "~0.7.38"
ProfileCanvas = "~0.1.0"
ProgressLogging = "~0.1.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "6d4fa04343a7fc9f9cb9cff9558929f3d2752717"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.0.9"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "63d1e802de0c4882c00aee5cb16f9dd4d6d7c59c"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.1"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Configurations]]
deps = ["ExproniconLite", "OrderedCollections", "TOML"]
git-tree-sha1 = "ab9b7c51e8acdd20c769bccde050b5615921c533"
uuid = "5218b696-f38b-4ac9-8b61-a12ec717816d"
version = "0.17.3"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.ExproniconLite]]
git-tree-sha1 = "8b08cc88844e4d01db5a2405a08e9178e19e479e"
uuid = "55351af7-c7e9-48d6-89ff-24e801d99491"
version = "0.6.13"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.FlameGraphs]]
deps = ["AbstractTrees", "Colors", "FileIO", "FixedPointNumbers", "IndirectArrays", "LeftChildRightSiblingTrees", "Profile"]
git-tree-sha1 = "d9eee53657f6a13ee51120337f98684c9c702264"
uuid = "08572546-2f56-4bcf-ba4e-bab62c3a3f89"
version = "0.2.10"

[[deps.FuzzyCompletions]]
deps = ["REPL"]
git-tree-sha1 = "efd6c064e15e92fcce436977c825d2117bf8ce76"
uuid = "fb4132e2-a121-4a70-b8a1-d5b831dcdcc2"
version = "0.5.0"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JET]]
deps = ["InteractiveUtils", "JuliaInterpreter", "LoweredCodeUtils", "MacroTools", "Pkg", "Revise", "Test"]
git-tree-sha1 = "db7e3490a86714a183d5b11576f25340160783ff"
uuid = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b"
version = "0.5.14"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "52617c41d2761cc05ed81fe779804d3b7f14fff7"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.13"

[[deps.LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "b864cb409e8e445688bc478ef87c0afe4f6d1f8d"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.1.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "dedbebe234e06e1ddad435f5c6f4b85cd8ce55f7"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.2.2"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MsgPack]]
deps = ["Serialization"]
git-tree-sha1 = "a8cbf066b54d793b9a48c5daa5d586cf2b5bd43d"
uuid = "99f44e22-a591-53d1-9472-aa23ef4bd671"
version = "1.1.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "1285416549ccfcdf0c50d4997a94331e88d68413"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.Pluto]]
deps = ["Base64", "Configurations", "Dates", "Distributed", "FileWatching", "FuzzyCompletions", "HTTP", "InteractiveUtils", "Logging", "Markdown", "MsgPack", "Pkg", "REPL", "RelocatableFolders", "Sockets", "Tables", "UUIDs"]
git-tree-sha1 = "1302c9385c9e5b47f9872688015927f7929371cb"
uuid = "c3e4b0f8-55cb-11ea-2926-15256bba5781"
version = "0.18.4"

[[deps.PlutoProfile]]
deps = ["AbstractTrees", "FlameGraphs", "Pluto", "Profile", "ProfileCanvas"]
git-tree-sha1 = "d8189132bb02e041f537f96d774de441ccb5af88"
uuid = "ee419aa8-929d-45cd-acf6-76bd043cd7ba"
version = "0.3.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "670e559e5c8e191ded66fa9ea89c97f10376bb4c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.38"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProfileCanvas]]
deps = ["FlameGraphs", "JSON", "Pkg", "Profile", "REPL"]
git-tree-sha1 = "41fd9086187b8643feda56b996eef7a3cc7f4699"
uuid = "efd6af41-a80b-495e-886c-e51b0c7d77a3"
version = "0.1.0"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "307761d71804208c0c62abdbd0ea6822aa5bbefd"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.2.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "4d4239e93531ac3e7ca7e339f15978d0b5149d03"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.3.3"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═f5231f65-da94-4ed3-af65-857edb42ee08
# ╠═5de2a556-f3af-4a64-a5c6-32d30f758be3
# ╟─e1852c8d-4028-409e-8e1a-8253bbd6e6a5
# ╠═1ac5ba38-0eef-41bb-8f9c-3bbf057cae21
# ╟─9331fad2-f29e-11eb-0349-477bd2e7e412
# ╟─3d98e7db-c643-4500-987d-4a225e55b2a5
# ╠═b4f2a99e-de45-49d2-be86-9f2d03357462
# ╟─068b3e45-5105-48aa-a547-536470f6abda
# ╠═7a75c990-46b4-484e-acc4-65e34f41a9f2
# ╟─f7b1b44f-2aa6-4c5c-97a2-ac7037fb48ce
# ╠═1fb43343-083b-4b1a-b622-d88c9aa0808c
# ╠═a28f7911-3dbb-45fb-a82d-2834d3c8502c
# ╠═4da8a7ca-3cea-4629-a66d-44f3b907af09
# ╟─c0a7c1fe-457f-4e52-b0ea-2821e40817ea
# ╠═834f6172-15bc-4e7d-ae22-e18ef2e8e22b
# ╟─94c78148-c651-4a59-9e62-5c7e9576d1e8
# ╟─c42e3aa8-48c7-4bb1-bb35-2301476e085b
# ╠═c44f3dc9-ff19-4ba4-9388-73cfaf23f8e8
# ╟─0fb6ed33-601c-4392-b7d9-32230c979d39
# ╟─a6e9da76-1ff0-4b54-9b55-4856ca32b251
# ╟─fa483fea-bf9f-4764-8d4f-c6d33e3336fb
# ╟─d3c1a86c-8c8f-4ad6-ac3c-2ba0f838d139
# ╟─43bad028-9d16-426f-9cdb-a37b1ee1a623
# ╠═857509a7-f07a-4bf0-9383-207984b95faa
# ╟─7386749b-b2ab-48a7-a1d2-46e7f31e72e3
# ╠═6cd86e7a-9f82-4da1-a8f0-4ed2c1068ab9
# ╟─382517ac-c4f5-45f1-bfe6-120e06c97b1c
# ╠═5d10a00b-bfa9-49c7-9f4b-503351fa2842
# ╟─38cc6383-c7d8-46b4-8531-251bd196d960
# ╠═62163e17-4265-4c97-95bb-29d608e80b07
# ╟─9d8b7e25-c9c6-4aba-a33c-66fd18d804c0
# ╟─fe45168c-8cf1-435e-86fc-16cfffef3ec1
# ╠═0400175c-5a3c-44a7-9a8a-c30a4756b88c
# ╠═cd0cc22f-2d4d-4848-8f15-8f0127a4245b
# ╟─638de554-1bec-453d-9e30-796247aaa4cc
# ╠═fd4401cf-69e8-4444-92c3-478035301006
# ╟─23053665-e058-43de-95d9-c688e3a80b0c
# ╟─9a181530-02e7-47b0-9a86-c191baefac54
# ╠═159c8baa-fa34-4e9d-af09-774c625194fa
# ╠═610f6d6f-9d37-4f3d-be78-ab9847162f4d
# ╟─c7b551a0-8c2e-4785-b575-8d58e37c14ec
# ╠═2fabb4c0-5861-45f6-8972-c29e55804ca8
# ╟─bd8ab522-457f-4b9c-86b4-fa39b857ccbd
# ╟─fe734441-3a46-4b75-aba1-9c3c6519ad64
# ╠═49327d40-31a1-47c8-abc2-4517478ca18f
# ╟─b186543b-aae1-4c96-a93d-8507a2a54805
# ╟─9d1951b4-2bf3-4dd3-9ee2-ec8bb6b953f3
# ╟─1067868e-2ca8-463f-bc55-c444aaf3b37c
# ╠═dacdb662-f46d-4032-a8b8-cdfbaf5317fc
# ╠═22b04135-f762-4331-8091-c8c3fa46655f
# ╠═40d777cc-7cf0-44f7-b179-fe3abbf4e030
# ╠═bb734c3b-d981-4473-aa04-9262206ee746
# ╠═758b6eb0-f61d-4772-a270-f55fac65d56a
# ╠═262f7aa1-5072-4376-92db-4241370ec303
# ╠═f352b77a-4e83-4c84-bdcb-9d024b25673f
# ╠═9ce1abc9-5377-4fba-a059-3596cbdd3bcd
# ╠═44967cf2-8aff-4b85-aa4a-5833b9b29ab5
# ╟─c1310939-87c2-405f-94d6-c7d1310ff700
# ╠═1500ca48-f99c-4ea0-beb7-bcadedf11d23
# ╠═99df78f5-61ac-49b3-b5ad-5fe5cdeffec5
# ╟─26c9d3a2-a54a-43d7-897e-64c34eeac81f
# ╠═b1d31667-46c8-406a-8d25-19802181f37f
# ╠═44f17b4d-c498-4126-9647-4eceaa4a3f21
# ╟─5aee27ef-c3cf-43b0-b1fd-e058e90bf112
# ╟─e7c68548-a654-40dd-9b3a-10ce24b6cd5c
# ╠═735121ed-1563-4d1b-b5c2-f0c4d80e17a1
# ╠═b47ab7f4-82af-4f09-851e-2352093a0b71
# ╠═21e5063b-3d55-4a25-88bb-1dc02322828b
# ╠═72421355-fac2-4c68-b9a3-f2c49a02c986
# ╠═908796b8-5880-4cbf-9102-92cbd39cae49
# ╟─769a8892-1f5a-49ea-947d-dbef2262fd6e
# ╠═95e7dfdb-0bc0-4cb1-b4ad-f74b006af66c
# ╠═48ae2243-bf72-4e2f-af0a-17bc377b44e4
# ╟─b3be8a6e-c00f-413f-858e-aee32f32dd18
# ╠═2b0f6c30-112e-45bc-a3ea-3da4012922a9
# ╠═5d07342c-d4b4-4f3b-b523-514c0f252813
# ╟─fe04e854-1393-42fc-b6d7-6a4b3848e0ef
# ╟─bc1695e8-12c2-4630-a630-a12c53943eb8
# ╟─ada6d5f4-f5fc-4c5f-9724-d29f4bb2a06a
# ╟─fdf97758-26c1-4157-a5d1-af89578f6277
# ╠═22d2d50e-8be2-4e1d-a1f7-8fd8d62b4a47
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
