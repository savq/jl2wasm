### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ a2853ccc-97ff-4726-b937-e2f9c1196e5b
using HypertextLiteral: @htl

# ╔═╡ 556d124c-43e2-4a43-9143-6bb02364baa2
using AbstractPlutoDingetjes.Display: published_to_js

# ╔═╡ 7d3d0f58-efd0-11ee-1988-157fbf03d5d6
md"""
# Metaprogramming in Julia

Sergio A. Vargas\
Universidad Nacional de Colombia\
YYYY-MM-DD

### Prerequisites

- Knowledge of recursive data types: lists, trees, etc.
- Good to know: [s-expressions](https://en.wikipedia.org/wiki/S-expression).

!!! note "Nota"
	¡Hagan preguntas! No habrá tiempo de preguntas al final de la presentación.

### Dependencies
"""

# ╔═╡ 96b5c3d2-a79c-4cf5-a830-191afc9758e9
md"""
## 📜 Prelude

We want to create a programming language, but creating a PL is hard…

- One frontend is not enough:
  - compiler
  - linter? language server?
  - editor support? syntax highlighting?


- One backend is not enough:
  - Architecture?
  - OS?
  - Fast code or fast compile times?

Too much work if we only want to try out small things, and develop ideas quickly.


We solve this problem with the same techniques as always:

- Decomposition
- Code reuse

!!! term "Goal"
	Glue an existing compiler frontend to a different compiler backend.
"""

# ╔═╡ c589d6d4-eb72-4fdc-90a8-78bfc7ae12ea
function mermaid(x)
	@htl """
	<html>
		<body>
			<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"/>
			<script>
				mermaid.initialize({ startOnLoad: true });
			</script>
			<pre class="mermaid">
				$x
			</pre>
		</body>
	</html>"""
end;

# ╔═╡ 72e19c3e-7ceb-4c0b-a146-038e50a099c1
mermaid("""
flowchart LR
	A[src] -->|parse| B[AST] -->|lower| IR -->|compile| C[bin] -->|execute| D[result]
""")

# ╔═╡ 04f08045-bcda-4ac4-82e1-c438e4766907
md"""
Figure 1. The life of the program, the job of the compiler
"""

# ╔═╡ a5f78769-af54-4707-abc6-c09f420824e9
md"""
## 🔮 Metaprogramming

- Metaprogramming is the ability to use programs as data.
- In a language with metaprogramming, we get access to the compiler frontend _for free!_

#### Enter Julia

- Algol-like syntax
- Expression based
- Dynamically typed
- Type system with parametric polymorphism
- Multiple dispatch
- JIT compiler backed by [LLVM](https://llvm.org/)
- **Hygenic macro system and metaprogramming**

Today, we'll focus mostly on the metaprogramming.
"""

# ╔═╡ db2740c7-ee68-4aa0-ad16-82769478b596
md"""
### Julia basics
"""

# ╔═╡ 2fb9d1e0-6d09-4bd5-a1c5-58cd04ff2894
# functions

# ╔═╡ a3871e48-5e80-4e60-aa94-0c36bc7df5f8
# control flow

# ╔═╡ 73011791-b887-4810-a090-1fa4845c8d1f
# assignment

# ╔═╡ e06c6eab-ba80-424a-aff6-65f89bc60fe8
# splatting

# ╔═╡ c27a8228-c936-4be9-9f69-06ac4b6c7eb5
# numeric types

# ╔═╡ 9ba88d23-6f9c-481b-92bd-6815c3892da1
# querying types

# ╔═╡ 7ace6c2d-40a8-4af4-85e6-9414d4575d3a
# Types as values

# ╔═╡ 3bed4046-f534-4e39-b7a9-03926f021f8d
# Values as types (Val)

# ╔═╡ 478ee52e-ab77-4a0e-a336-0144493c7a06
md"""
### Parsing Julia code
"""

# ╔═╡ 59fbbfd3-bc0a-4b67-a4fc-62bb395f5616
my_src = ""

# ╔═╡ a1f509c9-302a-4435-bfdf-0fbdc34bca43
Meta.parse(my_src)

# ╔═╡ 192674cf-9e9a-4b6b-9d0e-6bd7f9b840d2
typeof(Meta.parse(my_src))

# ╔═╡ 4185d1b8-457f-4d1d-add6-7bb1b458d134
md"""
#### What?
"""

# ╔═╡ 906c9da5-085b-47cd-ab97-6a23d1a16e46
fieldnames(typeof(my_src))

# ╔═╡ 4ce87be5-6944-4ebd-859b-d642e01c597b
expr1 = Meta.parse(my_src)

# ╔═╡ 4807e9e5-8f75-42c7-9cbd-0c1cd3dcb99f
# expr1.h

# ╔═╡ c047c82e-4c64-435d-a8bf-89f5c0c6cb5c
# expr1.a

# ╔═╡ 6fe85a23-d219-48e7-90a1-4c951618c833
 Meta.dump(expr1)

# ╔═╡ b260ad7b-ee8b-4d35-a30c-88575abb8235
eval(expr1)

# ╔═╡ 141c19a1-6801-4733-adce-0303a031d5d9
# eval(my_src) == my_src    # strings are not programs, Guido!

# ╔═╡ c785abba-e632-4b73-9eb7-35d9f199be55
md"""
#### The leaves of the tree
"""

# ╔═╡ 7065b167-5a71-4e7d-909b-310a89c6e607
:x

# ╔═╡ b92e667e-2a22-4223-a807-d6fa55fc4073
typeof(:x)

# ╔═╡ 1e1261d0-90c5-4e4b-be83-3f2f4ed7273c
:37

# ╔═╡ 548eb784-444e-4a22-a492-8c2753828c50
typeof(:37)

# ╔═╡ ba119dbb-3e97-46f5-b245-9919774bb8c0
md"""!!! note "Digression: Trees and s-expressions" """ # Tablero

# ╔═╡ f1a249a0-2536-4db9-989c-2aba75cf8797
md"""
#### Using `quote` and `:`

Calling `Meta.parse` all the time is inconvenient. We'd like to parse everything at compile time.
"""

# ╔═╡ 4683c39e-6119-4d99-b1ec-ed94e7967628
# block_expr = quote
# 	x = 1
# 	x + 1
# end

# ╔═╡ 5f51e93b-4aee-4d74-b941-09666a7a3670
# Meta.dump(block_expr)

# ╔═╡ 2253b266-9d67-4101-8913-a784c9f5e2db
# expr2 = :()

# ╔═╡ c0454351-2f4f-4f35-bbd1-1b87d704ca2f
#expr1 == expr2

# ╔═╡ ff53a0a5-c11d-4927-ba92-7d81f7ab8b17
# Meta.dump( :(x + 1) )    # side note: Binary operators are calls too!

# ╔═╡ fc07cbeb-038c-4ed3-900d-4e736ba793ab
md"""
### Macros

Macros take one or more expressions as input, and return a new expression.
"""

# ╔═╡ fc624ac1-7b8a-471a-adaa-5770e9d68b72
# Meta.@dump x + 1

# ╔═╡ d6ce3dc5-440a-47b1-aa69-5a7a996b003b
md"""
#### Example: Replace the name of a variable

- Input: an expression `expr` and two symbols `old`, `new`.
- Output: An expression `expr′` that is equal to `expr`, except every instance of `old` was replaced with `new`.


To simplify writing macros, we first define a function on `Expr` and then we wrap it with a macro.
"""

# ╔═╡ 1a0138f6-91bb-4756-acab-960539dc1032
# replace(_) = _

# ╔═╡ 75ea7bff-f458-4160-ab6e-909cdd87d493
# replace(_) = _

# ╔═╡ f7648961-025b-4476-9829-2cb825a27697
# replace(_) = _

# ╔═╡ 345d1baa-cf63-4c99-8fbe-7a2827cd4b0b
#=
# Cheat sheet, in case I forget.
begin
	replace(id::Symbol, old, new) = id == old ? new : id
	replace((; head, args)::Expr, old, new) = Expr(head, replace.(args, old, new)...)
	replace(token, _, _) = token # ignore non-symbol tokens
end
=#

# ╔═╡ c4e71a1b-df3f-498b-adce-ab6cc309c0a0
macro replace_id(expr, old, new)
	replace(expr, old, new)
end

# ╔═╡ 46b540f5-21be-4a15-8691-a4eaec50c214
# x

# ╔═╡ bd5b69b0-155a-4fc8-9ad7-511b2c4c5aa4
y = 3

# ╔═╡ 50a234de-eb44-4189-972a-eed02642d26f
# @replace_id(x + 2, x, y)

# ╔═╡ 4c652c6e-1f2e-47e4-8c93-984ed2d5475e
# replace( :(x+2), :x, :y )

# ╔═╡ c5d31600-b8f0-41e2-b2e9-3625a6a1159a
# @macroexpand @replace_id(x + 2, x, y)

# ╔═╡ a4c82a82-1ff8-431a-876b-f2cf2fa9ff32
## const prop!?

# ╔═╡ a1d7d2fa-962c-4dc0-bfa4-e616fdc0d4b1
md"""
### Summary

- `Expr` is a tree-like data structure
- `Expr` represents the Abstract Syntax Tree (AST) of a program
- `Symbol` and other literals are the leaves of the tree
- `quote` gives us a shorthand to construct `Expr`
- `:` gives an even shorter shorthand to `quote`
- Macros quote things automatically
- Tree transversal on an `Expr` is a practical way to transform a program
"""

# ╔═╡ e32d59cf-3d6f-4ba7-95ee-280b55998a54
md"""
## References

- [Julia Manual: Metaprogramming](https://docs.julialang.org/en/v1/manual/metaprogramming/)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractPlutoDingetjes = "6e696c72-6542-2067-7265-42206c756150"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"

[compat]
AbstractPlutoDingetjes = "~1.3.0"
HypertextLiteral = "~0.9.5"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.3"
manifest_format = "2.0"
project_hash = "db3fea90f2289263fb4a03381179734283635cb5"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0f748c81756f2e5e6854298f11ad8b2dfae6911a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─7d3d0f58-efd0-11ee-1988-157fbf03d5d6
# ╠═a2853ccc-97ff-4726-b937-e2f9c1196e5b
# ╠═556d124c-43e2-4a43-9143-6bb02364baa2
# ╟─96b5c3d2-a79c-4cf5-a830-191afc9758e9
# ╟─c589d6d4-eb72-4fdc-90a8-78bfc7ae12ea
# ╟─72e19c3e-7ceb-4c0b-a146-038e50a099c1
# ╟─04f08045-bcda-4ac4-82e1-c438e4766907
# ╟─a5f78769-af54-4707-abc6-c09f420824e9
# ╟─db2740c7-ee68-4aa0-ad16-82769478b596
# ╠═2fb9d1e0-6d09-4bd5-a1c5-58cd04ff2894
# ╠═a3871e48-5e80-4e60-aa94-0c36bc7df5f8
# ╠═73011791-b887-4810-a090-1fa4845c8d1f
# ╠═e06c6eab-ba80-424a-aff6-65f89bc60fe8
# ╠═c27a8228-c936-4be9-9f69-06ac4b6c7eb5
# ╠═9ba88d23-6f9c-481b-92bd-6815c3892da1
# ╠═7ace6c2d-40a8-4af4-85e6-9414d4575d3a
# ╠═3bed4046-f534-4e39-b7a9-03926f021f8d
# ╟─478ee52e-ab77-4a0e-a336-0144493c7a06
# ╠═59fbbfd3-bc0a-4b67-a4fc-62bb395f5616
# ╠═a1f509c9-302a-4435-bfdf-0fbdc34bca43
# ╠═192674cf-9e9a-4b6b-9d0e-6bd7f9b840d2
# ╟─4185d1b8-457f-4d1d-add6-7bb1b458d134
# ╠═906c9da5-085b-47cd-ab97-6a23d1a16e46
# ╠═4ce87be5-6944-4ebd-859b-d642e01c597b
# ╠═4807e9e5-8f75-42c7-9cbd-0c1cd3dcb99f
# ╠═c047c82e-4c64-435d-a8bf-89f5c0c6cb5c
# ╠═6fe85a23-d219-48e7-90a1-4c951618c833
# ╠═b260ad7b-ee8b-4d35-a30c-88575abb8235
# ╠═141c19a1-6801-4733-adce-0303a031d5d9
# ╟─c785abba-e632-4b73-9eb7-35d9f199be55
# ╠═7065b167-5a71-4e7d-909b-310a89c6e607
# ╠═b92e667e-2a22-4223-a807-d6fa55fc4073
# ╠═1e1261d0-90c5-4e4b-be83-3f2f4ed7273c
# ╠═548eb784-444e-4a22-a492-8c2753828c50
# ╟─ba119dbb-3e97-46f5-b245-9919774bb8c0
# ╟─f1a249a0-2536-4db9-989c-2aba75cf8797
# ╠═4683c39e-6119-4d99-b1ec-ed94e7967628
# ╠═5f51e93b-4aee-4d74-b941-09666a7a3670
# ╠═2253b266-9d67-4101-8913-a784c9f5e2db
# ╠═c0454351-2f4f-4f35-bbd1-1b87d704ca2f
# ╠═ff53a0a5-c11d-4927-ba92-7d81f7ab8b17
# ╟─fc07cbeb-038c-4ed3-900d-4e736ba793ab
# ╠═fc624ac1-7b8a-471a-adaa-5770e9d68b72
# ╟─d6ce3dc5-440a-47b1-aa69-5a7a996b003b
# ╠═1a0138f6-91bb-4756-acab-960539dc1032
# ╠═75ea7bff-f458-4160-ab6e-909cdd87d493
# ╠═f7648961-025b-4476-9829-2cb825a27697
# ╠═345d1baa-cf63-4c99-8fbe-7a2827cd4b0b
# ╠═c4e71a1b-df3f-498b-adce-ab6cc309c0a0
# ╠═46b540f5-21be-4a15-8691-a4eaec50c214
# ╠═bd5b69b0-155a-4fc8-9ad7-511b2c4c5aa4
# ╠═50a234de-eb44-4189-972a-eed02642d26f
# ╠═4c652c6e-1f2e-47e4-8c93-984ed2d5475e
# ╠═c5d31600-b8f0-41e2-b2e9-3625a6a1159a
# ╠═a4c82a82-1ff8-431a-876b-f2cf2fa9ff32
# ╟─a1d7d2fa-962c-4dc0-bfa4-e616fdc0d4b1
# ╟─e32d59cf-3d6f-4ba7-95ee-280b55998a54
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
