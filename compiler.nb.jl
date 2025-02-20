### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 493a3465-d6ee-4dbd-8450-863a2a9e5ae1
struct CompilerError <: Exception
	msg::String
end

# ╔═╡ 22c17393-eca3-44cb-bde6-ef78d2e337a5
Base.showerror(io::IO, e::CompilerError) = print(io, "(wasm2jl) ", e.msg)

# ╔═╡ 916914b0-861d-472e-ab21-6ec3f915986a
struct TypeMismatchError <: Exception
	msg::String
end

# ╔═╡ 2078ff46-b3d9-4e3b-a9a3-4c7115412584
Base.showerror(io::IO, e::TypeMismatchError) =
	print(io, "(wasm2jl) Type mismatch: ", e.msg)

# ╔═╡ b05e6426-2c26-455e-b18c-12676e25ba2b
struct Env
	var_types::Dict{Symbol, Symbol}
	func_types::Dict{Symbol, Any}
	
	function Env()
		new(Dict(), Dict())
	end
	
	function Env(pairs...)
		new(Dict(pairs...), Dict())
	end

	Env(super::Env) = new(copy(super.var_types), copy(super.func_types))
end

# ╔═╡ f7ee1048-42e1-4c29-98ca-b0486cfad4ac
Base.in(var, env::Env) = var in keys(env.var_types)

# ╔═╡ 1c653ada-e4fe-4531-b63c-80a2fa349383
Base.getindex(env::Env, var::Symbol) = env.var_types[var]

# ╔═╡ 713a951e-eef7-11ef-1d65-b975371b6ab6
md"""
# TO DO (compilador nuevo)

- [ ] Introducción
- [ ] Mini-Julia
- [ ] Explicación análisis sintáctico
- [ ] WebAssembly
- [ ] Análisis semántico
  - [ ] Resolución de variables
  - [ ] Verificación de tipos
  - [ ] Normalización (lowering/desugaring)
  - [ ] Errores
- [ ] Compilación
- [ ] Referencias
- [ ] Presentación
  - [ ] Table of Contents
  - [ ] GitHub pages
  - [ ] Video
"""

# ╔═╡ bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
md"""
## Fuente: subset de julia...

- modulos
- variables
- funciones
- tipos de dato: booleanos, enteros, números de coma flotante
- condicionales
"""

# ╔═╡ 49d328d5-a16d-4510-b07b-a9cc908c8310
md"""
## Análisis sintáctico en Julia

Metaprogramación...
quote...
Expr...
"""

# ╔═╡ 3083b769-a9af-4831-ab78-e07671db4a80
md"""
## Objeto: WebAssembly
"""

# ╔═╡ b68ac919-095d-40f8-9bd9-a3a5ee62c484
md"""
## Análisis semántico

- [ ] Resolución de variables
- [ ] Verificación de tipos
- [ ] Normalización (lowering/desugaring)
- [ ] Errores
"""

# ╔═╡ 8c77097c-5179-49d9-90b9-1068ed57205b
function Base.setindex!(env::Env, t::Symbol, var::Symbol)
	if var in keys(env.var_types)
		throw(CompilerError("Variable is already defined: ", var))
	else
		env.var_types[var] = t
	end
	return
end;

# ╔═╡ 376fabca-a483-4cc8-b852-eb79a4f85b66
md"""
# Analysis
"""

# ╔═╡ 465fb73a-65d4-4dad-aa50-a5e6d2907f3a
"""
static analysis...
mutate env...
return type...
"""
# function analyze end

# ╔═╡ 8815bd45-6159-4efd-bffc-654e8857cf59
analyze(expr::Expr, env=Env()) = analyze(Val(expr.head), expr.args, env);

# ╔═╡ 90098ad7-5e9c-4e78-b310-4c83f039d448
analyze(::Val{S}, _args, env) where S = @warn("Form not implemented: $S");

# ╔═╡ 7968e313-e222-49f3-b3b4-958a33c85acf
function analyze(var::Symbol, env)
	if var ∉ env
		throw(CompilerError("Undefined variable: $var"))
	else
		env[var]
	end
end;

# ╔═╡ 1410504f-af8c-498f-9966-7402d2d4abf3
analyze(n::Number, _) = nameof(typeof(n));

# ╔═╡ 22836a67-35da-44db-acd6-a6dae22de054
analyze(::LineNumberNode, _) = nothing; # ignore

# ╔═╡ 9b39f2b3-f304-4ca5-b978-138d581b6131
analyze(::Val{:block}, exprs, env) = last(map(e -> analyze(e, env), exprs));

# ╔═╡ 80cf9e1a-0001-4326-8529-6b0a552a6983
"check patterns like x::T"
function type_pattern(pat::Expr)
	if pat.head == :(::)
		(var, type) = pat.args
		return (var, type)
	else
		throw(CompilerError("Unexpected pattern: `$pat`"))
	end
end;

# ╔═╡ ae62d583-5d18-4638-8d15-1dc712251172
function analyze(::Val{:(=)}, args, env)
	(lhs, rhs) = args
	
	rtype = analyze(rhs, env)
	
	if lhs isa Symbol
		if lhs in env 							# Existing variable. Compare types.
			if env[lhs] != rtype
				ltype = env[lhs]
				throw(TypeMismatchError(
					"""
					Variable `$lhs` has type `$ltype`, but was assigned an expression of type `$rtype`.
					"""
				))
			end
		else
			env[lhs] = rtype 					# New variable. Infer type.
		end
	elseif lhs isa Expr && lhs.head == :call 	# Short function
		analyze(Expr(:function, lhs, Expr(:block, rhs)))
	else
		(var, type) = type_pattern(lhs)			
		env[var] = ltype						# New variable. Assert type.
	end
	return rtype
end;

# ╔═╡ 081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
function analyze_signature(sig::Expr, env::Env)
	if sig.head == :(::)
		(fname, _, pnames, ptypes) = analyze_signature(sig.args[1], env)
		ret_type = sig.args[2]
	elseif sig.head == :call
		fname = sig.args[1]
		# array of tuples to tuple of arrays
		(pnames, ptypes) = collect(splat(zip)(map(type_pattern, sig.args[2:end])))
		map((p, t) -> env[p] = t, pnames, ptypes)
		ret_type = :Nothing
	end

	return (fname, ret_type, pnames, ptypes)
end;

# ╔═╡ 0779191f-61c2-405a-804b-a09063599d92
function analyze(::Val{:function}, args, env)
	(sig, body) = args
	fenv = Env(env)

	(fname, ret_type, pnames, ptypes) = analyze_signature(sig, fenv)
	env.func_types[fname] = fenv.func_types[fname] = (ptypes, ret_type)

	last_type = analyze(body, fenv)

	if ret_type != last_type
		throw(TypeMismatchError(
			"""
			Function `$fname` has return type `$ret_type`, but last expression has type `$last_type`.
			"""
		))
	end

	var_decls = [:(local $v::$t) for (v, t) in pairs(fenv.var_types) if v ∉ pnames]
	prepend!(body.args, var_decls)
	return last_type
end;

# ╔═╡ 29c7ed38-3eca-4d59-aa83-4acfd25ffa26
function analyze(::Val{:call}, args, env)
	fname = args[1]
	fargs = args[2:end]

	argument_types = map(a -> analyze(a, env), fargs)
	if fname in keys(env.func_types)
		(param_types, ret_type) = env.func_types[fname]
		if !all(param_types .== argument_types)
			throw(TypeMismatchError(
				"Function `$fname` expected `$param_types`, but got $argument_types"
			))
		end
		return ret_type
	else
		throw(CompilerError("Undefined function: `$fname`"))
	end
end;

# ╔═╡ 2905c457-1d80-440e-b046-9ca1cb420e81
md"# TODO: ARITHMETIC"

# ╔═╡ 2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
i_bin_op = (
	+ = :add,
	- = :sub,
	* = :mul,
	/ = :div,
	% = :rem,
	
	== = :eq,
	!= = :ne,
	< = :lt,
	> = :ge,
	<= = :lt,
	>= = :ge,
);

# ╔═╡ 7162fa35-ee10-49f8-837f-881a5a5928e3
f_bin_op = (
	+ = :add,
	- = :sub,
	* = :mul,
	/ = :div,
);

# ╔═╡ bd431f34-9ef3-4892-87c1-c0a1b87ef0d9
f_un_op = (
	- = :neg,
	√ = :sqrt,
	abs = :abs,
	neg = :neg,
	sqrt = :sqrt,
	ceil = :ceil,
	floor = :floor,
	trunc = :trunc,
	nearest = :nearest,
);

# ╔═╡ 41c29c01-6af6-4b2d-bcc8-60e44a99ce34
abstract type NumericOp end

# ╔═╡ bec5b494-4361-480d-af54-5c40b2515214
struct BinaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ b0649857-c064-4308-90ba-b2732d5646a7
struct UnaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ 4834f3ed-eb2a-4ec3-9575-8fd3777d248e
function Base.show(io::IO, cop::NumericOp)
	# Note: Use subscript `p` because Unicode doesn't have subscript `f`
	subscripts = (
		Float32 = "ₚ₃₂",
		Float64 = "ₚ₆₄",
		Int32 = "ᵢ₃₂",
		Int64 = "ᵢ₆₄",
		UInt32 = "ᵤ₃₂",
		UInt64 = "ᵤ₆₄",
	)
	write(io, "$(cop.op)$(subscripts[cop.t])")
	return
end

# ╔═╡ 23370e6c-bc0a-44e6-b434-aa6ff21d5875
md"# tests"

# ╔═╡ 639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
let ex = quote
	function g(y::Int64)::Float64
		1.0
	end
	
	function f(x::Int64)::Float64
		g(x)
	end
end
	analyze(ex)
	ex
end

# ╔═╡ Cell order:
# ╠═713a951e-eef7-11ef-1d65-b975371b6ab6
# ╟─bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
# ╟─49d328d5-a16d-4510-b07b-a9cc908c8310
# ╟─3083b769-a9af-4831-ab78-e07671db4a80
# ╟─b68ac919-095d-40f8-9bd9-a3a5ee62c484
# ╠═493a3465-d6ee-4dbd-8450-863a2a9e5ae1
# ╠═22c17393-eca3-44cb-bde6-ef78d2e337a5
# ╠═916914b0-861d-472e-ab21-6ec3f915986a
# ╠═2078ff46-b3d9-4e3b-a9a3-4c7115412584
# ╠═b05e6426-2c26-455e-b18c-12676e25ba2b
# ╠═f7ee1048-42e1-4c29-98ca-b0486cfad4ac
# ╠═1c653ada-e4fe-4531-b63c-80a2fa349383
# ╠═8c77097c-5179-49d9-90b9-1068ed57205b
# ╟─376fabca-a483-4cc8-b852-eb79a4f85b66
# ╠═465fb73a-65d4-4dad-aa50-a5e6d2907f3a
# ╠═8815bd45-6159-4efd-bffc-654e8857cf59
# ╠═90098ad7-5e9c-4e78-b310-4c83f039d448
# ╠═7968e313-e222-49f3-b3b4-958a33c85acf
# ╠═1410504f-af8c-498f-9966-7402d2d4abf3
# ╠═22836a67-35da-44db-acd6-a6dae22de054
# ╠═9b39f2b3-f304-4ca5-b978-138d581b6131
# ╠═ae62d583-5d18-4638-8d15-1dc712251172
# ╠═80cf9e1a-0001-4326-8529-6b0a552a6983
# ╠═0779191f-61c2-405a-804b-a09063599d92
# ╠═081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
# ╠═29c7ed38-3eca-4d59-aa83-4acfd25ffa26
# ╟─2905c457-1d80-440e-b046-9ca1cb420e81
# ╠═2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
# ╠═7162fa35-ee10-49f8-837f-881a5a5928e3
# ╠═bd431f34-9ef3-4892-87c1-c0a1b87ef0d9
# ╠═41c29c01-6af6-4b2d-bcc8-60e44a99ce34
# ╠═bec5b494-4361-480d-af54-5c40b2515214
# ╠═b0649857-c064-4308-90ba-b2732d5646a7
# ╠═4834f3ed-eb2a-4ec3-9575-8fd3777d248e
# ╟─23370e6c-bc0a-44e6-b434-aa6ff21d5875
# ╠═639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
