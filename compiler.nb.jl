### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 2a00780f-4322-455f-af3e-eba952abf64b
begin
	using HypertextLiteral: @htl
	using AbstractPlutoDingetjes.Display: published_to_js;
end

# ╔═╡ 493a3465-d6ee-4dbd-8450-863a2a9e5ae1
struct CompilerError <: Exception
	msg::String
end

# ╔═╡ 22c17393-eca3-44cb-bde6-ef78d2e337a5
Base.showerror(io::IO, err::CompilerError) = print(io, "(wasm2jl) ", err.msg)

# ╔═╡ bdba6817-5fe4-4dd5-941b-d4c57535244e
macro compiler_error(msg)
	esc(:(throw(CompilerError($msg))))
end

# ╔═╡ 916914b0-861d-472e-ab21-6ec3f915986a
struct TypeMismatchError <: Exception
	msg::String
end

# ╔═╡ 2078ff46-b3d9-4e3b-a9a3-4c7115412584
Base.showerror(io::IO, e::TypeMismatchError) =
	print(io, "(wasm2jl) Type mismatch: ", e.msg)

# ╔═╡ 59edf6b6-498f-480f-8cca-4dfc0d54ad00
macro type_mismatch(msg)
	esc(:(throw(TypeMismatchError($msg))))
end

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

- [ ] Tests (hacen más fácil demostrar cada celda)
- [ ] Referencias
- [ ] Presentación
  - [ ] Table of Contents
  - [ ] GitHub pages
  - [ ] Video
"""

# ╔═╡ b11c9b3a-d108-4cd1-ad2a-16064d15482d
md"""
# Introducción ...
"""

# ╔═╡ 3083b769-a9af-4831-ab78-e07671db4a80
md"""
# Lenguaje Objeto: WebAssembly ...
"""

# ╔═╡ bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
md"""
# Lenguaje Fuente: Mini-Julia ...

- Modulos
- Funciones
- Condicionales
- Variables
- Tipos de dato: booleanos, enteros, números de coma flotante
"""

# ╔═╡ 49d328d5-a16d-4510-b07b-a9cc908c8310
md"""
# Análisis sintáctico ...

Metaprogramación...
quote...
Expr...
sintaxis límitada, poco "syntax sugar" ...
"""

# ╔═╡ b68ac919-095d-40f8-9bd9-a3a5ee62c484
md"""
# Análisis semántico ...

- Resolución de variables
- Verificación de tipos
- Normalización (lowering/desugaring)
- Errores
"""

# ╔═╡ 5e819f03-b27b-4190-9043-af88e031b9bd
md"## Errores de compilación ..."

# ╔═╡ 497bf2a9-1e6b-4519-9ce7-36ff5a945214
md"""
errores de tipos
"""

# ╔═╡ 0b71a7f1-86cc-4034-98ba-9aa1bb32c3cb
md"""
## Entorno ...
"""

# ╔═╡ 8c77097c-5179-49d9-90b9-1068ed57205b
function Base.setindex!(env::Env, t::Symbol, var::Symbol)
	if var in keys(env.var_types)
		@type_mismatch("Variable is already defined: $var")
	else
		env.var_types[var] = t
	end
	return
end;

# ╔═╡ 376fabca-a483-4cc8-b852-eb79a4f85b66
md"""
## Análisis semántico (2) ...
"""

# ╔═╡ 465fb73a-65d4-4dad-aa50-a5e6d2907f3a
"""
static analysis...
mutate env...
return type...

functions below debugging
"""
# function analyze end

# ╔═╡ 8815bd45-6159-4efd-bffc-654e8857cf59
function analyze(expr::Expr, env=Env())
	# @debug(expr)
	analyze(Val(expr.head), filter!(x -> !(x isa LineNumberNode), expr.args), env)
end;

# ╔═╡ 90098ad7-5e9c-4e78-b310-4c83f039d448
analyze(::Val{S}, _args, env) where S = @warn("Form not implemented: $S");

# ╔═╡ e57e7a76-1dad-4a58-8ac1-8031c969da24
md"""
## Análisis de terminales ...


representación de números...
"""

# ╔═╡ 7968e313-e222-49f3-b3b4-958a33c85acf
function analyze(var::Symbol, env)
	if var ∉ env
		throw(CompilerError("Undefined variable: $var"))
	else
		env[var]
	end
end;

# ╔═╡ b6a962ea-29fe-4b84-892c-2cffd06fc776
analyze(::Z, _) where {Z <: Integer} = nameof(promote_type(Int32, Z));

# ╔═╡ 1410504f-af8c-498f-9966-7402d2d4abf3
analyze(::R, _) where {R <: AbstractFloat} = nameof(promote_type(Float32, R));

# ╔═╡ 2558d535-9611-4f52-b23c-fd2ba6c3dab0
md"""
## Modulos ...

encontrar nombres exportados, verificar que existen...
"""

# ╔═╡ 73c32ba9-3558-4157-b578-eb4b39f3d9df
function analyze(::Val{:module}, args, env)
	(_, mname, body) = args

	exports = Symbol[]
	exprs = []

	for ex in body.args
		if ex isa Expr && ex.head == :export
			append!(exports, ex.args)
		elseif ex isa LineNumberNode
			# drop
		else
			push!(exprs, ex)
		end
	end

	analyze(Expr(:block, exprs...), env)

	for export_name in exports
		if export_name ∉ keys(env.func_types)
			@compiler_error("Undefined export: `$export_name`")
		end
	end
	args[3] = Expr(:block, map(name -> :(export $name), exports)..., exprs...)

	return
end;

# ╔═╡ 9b39f2b3-f304-4ca5-b978-138d581b6131
function analyze(::Val{:block}, exprs, env)
	type = last(map(e -> analyze(e, env), exprs))
	something(type, :Nothing)
end

# ╔═╡ 8560e6c3-086c-4d43-ab44-c8373df867ab
md"""
### Asignaciones ...
"""

# ╔═╡ 80cf9e1a-0001-4326-8529-6b0a552a6983
"check patterns like x::T"
function type_pattern(pat::Expr)
	if pat.head == :(::)
		(var, type) = pat.args
		return (var, type)
	else
		@compiler_error("Unexpected pattern: `$pat`")
	end
end;

# ╔═╡ 368cd41d-a4ab-4cc3-bc23-1e699acbddb4
type_pattern(any) = @compiler_error("Unexpected pattern: `$pat`")

# ╔═╡ ae62d583-5d18-4638-8d15-1dc712251172
function analyze(::Val{:(=)}, args, env)
	(lhs, rhs) = args

	rtype = analyze(rhs, env)

	if lhs isa Symbol
		if lhs in env 							# Existing variable. Compare types.
			if env[lhs] != rtype
				ltype = env[lhs]
				@type_mismatch(
					"""
					Variable `$lhs` has type `$ltype`, but was assigned expression of type `$rtype`.
					"""
				)
			end
		else
			env[lhs] = rtype 					# New variable. Infer type.
		end
	else
		(var, ltype) = type_pattern(lhs)		# New variable. Assert type.
		if ltype == rtype
			env[var] = ltype							
			args[1] = var
		else
			@type_mismatch(
				"""
				Variable `$lhs` has type `$ltype`, but was assigned expression of type `$rtype`.
				"""
			)
		end
	end
	return :Nothing 							# Assignments are statements.
end;

# ╔═╡ 8a44508f-5d71-4ac5-8859-2055274b8f9f
md"""
### Definición de functiones
"""

# ╔═╡ 081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
function analyze_signature(sig::Expr, env)
	if sig.head == :(::)
		(fname, _, pnames, ptypes) = analyze_signature(sig.args[1], env)
		ret_type = sig.args[2]
	elseif sig.head == :call
		fname = sig.args[1]
		# array of tuples to tuple of arrays
		fparams = sig.args[2:end]
		if length(fparams) > 0
			(pnames, ptypes) = collect(splat(zip)(map(type_pattern, fparams)))
		else
			(pnames, ptypes) = ([], [])
		end
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
		@type_mismatch(
			"""
			Function `$fname` has return type `$ret_type`, but last expression has type `$last_type`.
			"""
		)
	end

	var_decls = [:(local $v::$t) for (v, t) in pairs(fenv.var_types) if v ∉ pnames]
	prepend!(body.args, var_decls)
	return last_type
end;

# ╔═╡ ade2233f-5253-43da-a95f-84682d9299b4
md"""
### Llamados a funciones ...
"""

# ╔═╡ 8fa0fc6a-fb9e-4737-9888-98571f322e97
md"""
## Aritmética ...
"""

# ╔═╡ 41c29c01-6af6-4b2d-bcc8-60e44a99ce34
struct NumInstr
	instr::Symbol
	type::Symbol
end

# ╔═╡ 4834f3ed-eb2a-4ec3-9575-8fd3777d248e
Base.show(io::IO, op::NumInstr) = write(io, op.type, ".", op.instr)

# ╔═╡ 001f39f8-c254-48a3-acc2-d64a8344b5dd
isfloat(t) = t == :Float32 || t == :Float64;

# ╔═╡ dfddc124-afd3-4934-8cfc-3c3596e9854d
isint(t) = t == :Int32 || t == :Int64;

# ╔═╡ 8d7a8f03-5a48-439b-8012-1165ae470f3d
f_un_ops = (
	abs     = :abs,
	-       = :neg,
	sqrt    = :sqrt,
	√       = :sqrt,
)

# ╔═╡ 348cec8f-2002-4972-ad32-932fe3ac4e15
f_bin_ops = (
	+ = :add,
	- = :sub,
	* = :mul,
	/ = :div,
	min      = :min,
	max      = :max,
	copysign = :copysign,

)

# ╔═╡ 2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
i_bin_ops = (
   +  = :add,
   -  = :sub,
   *  = :mul,
   /  = :div,
   %  = :rem,
);

# ╔═╡ c578e254-2171-4803-b03e-4f910ef655b8
rel_ops = (
	== = :eq,
	!= = :ne,
	<  = :lt,
	>  = :gt,
	<= = :le,
	>= = :gt,
)

# ╔═╡ 80379f3b-4c3a-46cd-b1a1-fc14f67052a0
builtins = union(keys.([f_un_ops, f_bin_ops, i_bin_ops, rel_ops])...)

# ╔═╡ 9d6afbad-e03f-46e7-8fd6-24817016ad81
md"### TODO: Conversiones"

# ╔═╡ 24c850c6-e9b9-47fb-8d40-34cafc0a5ac0
md"""
## Condicionales
"""

# ╔═╡ 85b863bc-8091-43b4-ab31-fc406b86b6ed
function desugar_conditional!(ex::Expr)
	if ex.head == :elseif
		ex.head = :if
	end
	if ex.head == :if && isodd(length(ex.args))
		desugar_conditional!(ex.args[3])
	end
end

# ╔═╡ 3436fac4-a083-499d-a48c-4b95c431a797
desugar_conditional!(_) = nothing;

# ╔═╡ 635f057b-c0f9-4d34-82f6-87b92f7a909f
function analyze(::Val{:if}, args, env)
	desugar_conditional!.(args)
	(condition, consequent, alternative) = args

	ctype = analyze(condition, env)
	if !isint(ctype)
		@type_mismatch(
			"""
			Condition expected expression of type `Int*`, got type `$ctype`.
			"""
		)
	end

	then_type = analyze(consequent, env)
	else_type = analyze(alternative, env)

	if then_type == else_type
		push!(args, then_type)		# Hack!
		return then_type
	else
		@type_mismatch(
			"""
			Expected conditional branches of the same type, but got different types `$then_type` and `$else_type`.
			"""
		)
	end
end;

# ╔═╡ 55716561-84d0-4eab-b081-eea439411e7a
md"""
# Compilación ...
"""

# ╔═╡ eb287d52-7375-4226-bd2a-97f4c2a435bd
value_types = (
	Int32 = :i32,
	Int64 = :i64,
	Float32 = :f32,
	Float64 = :f64,
)

# ╔═╡ fb7b2997-731c-4a92-b359-82f17b8db299
function analyze_builtins(op, types)
	arity = length(types)
	if arity == 1 && op in keys(f_un_ops)
		if isfloat(types[1])
			return (types[1], UnaryOp(op, types[1]))
		else
			@type_mismatch(
				"Operator `$op` expected a `Float*` type, but got type `$type`."
			)
		end
	elseif arity == 2
		(ltype, rtype) = types
		if ltype == rtype
			(instr, t) =
				if op in keys(rel_ops)
					 (rel_ops[op], :Int32)
				elseif isfloat(ltype) && op in keys(f_bin_ops)
					(f_bin_ops[op], ltype)
				elseif isint(ltype) && op in keys(i_bin_ops)
					(i_bin_ops[op], ltype)
				else
					@type_mismatch(
						"Operator `$op` is not defined for type: `$ltype`."
					)
				end
			return (NumInstr(instr, value_types[ltype]), t) 
		else
			@type_mismatch(
				"Operator `$op` got different types: `$ltype` and `$rtype`."
			)
		end
	else
		@type_mismatch(
			"Unexpected number of arguments for `$op`."
		)
	end
end;

# ╔═╡ 29c7ed38-3eca-4d59-aa83-4acfd25ffa26
function analyze(::Val{:call}, args, env)
	fname = args[1]
	fargs = args[2:end]

	fargs_types = map(a -> analyze(a, env), fargs)
	if fname in keys(env.func_types)
		(param_types, ret_type) = env.func_types[fname]
		if !all(param_types .== fargs_types)
			@type_mismatch(
				"Function `$fname` expected types $param_types, but got types $fargs_types"
			)
		end
		return ret_type
	elseif fname in builtins
		(concrete_op, ret_type) = analyze_builtins(fname, fargs_types)
		args[1] = concrete_op
		return ret_type
	else
		@debug fname
		throw(CompilerError("Undefined function: `$fname`"))
	end
end;

# ╔═╡ 21e1e640-7f99-479e-9c5d-8367752ad694
macro an(ex)
	analyze(ex)
	@debug ex
	return
end

# ╔═╡ 0e9b8f09-cdbd-48b6-a81b-5fc04e55ab56
ident(id::Symbol) = string('$', id);

# ╔═╡ 5aea4283-8366-4028-b2ad-0227e7b2d9c5
sexpr(xs...; sep=" ") = string("(", join(xs, sep), ")");

# ╔═╡ 02915b1b-fcba-4d59-a9cd-2f07cf2b6d98
begin
	compile(expr::Expr) = compile(Val(expr.head), expr.args)
	compile(id::Symbol) = sexpr("local.get", ident(id))
	# FIXME
	compile(n::Number) = sexpr("$(value_types[analyze(n, Env())]).const", string(n))
	compile(::Val{:block}, args) = join(compile.(args), '\n')
end;

# ╔═╡ 83d4c742-7618-4a53-81c8-1db498559d01
function compile(::Val{:module}, args)
	sexpr(:module, compile.(args[3].args)...; sep='\n')
end;

# ╔═╡ 09224b80-0cde-4b46-868e-38d8ee891d3f
function compile(::Val{:export}, args)
	name = args[1]
	sexpr(:export, "\"$name\"", sexpr(:func, ident(name)))
end;

# ╔═╡ b04ba764-f39b-4a7b-ad8b-b0f3a793645e
function compile_signature(sig)
	if sig.head == :(::)
		(fname, fparams, _ret) = compile_signature(sig.args[1])
		ret = sexpr(:result, value_types[sig.args[2]])
		(fname, fparams, ret)
	elseif sig.head == :call
		(sig.args[1], sig.args[2:end], "")
	end
end;

# ╔═╡ ea7f10a3-9469-4207-a9ed-de244c56b73a
function compile(::Val{:function}, args)
	(sig, body) = args
	(fname, params, ret) = compile_signature(sig)
	compile_param((p, t)) = sexpr(:param, ident(p), value_types[t])
	sexpr(
		:func,
		ident(fname),
		map(param -> compile_param(param.args), params)...,
		ret,
		'\n',
		compile(body),
	)
end;

# ╔═╡ 589c8a1b-f246-476d-8e6e-b7e321829b1b
function compile(::Val{:if}, args)
	(condition, consequent, alternative) = compile.(args[1:3])
	ret = sexpr(:result, value_types[args[4]])				# hack!
	join([
		condition,
		:if,
		ret,
		consequent,
		:else,
		alternative,
		:end,
	], '\n')
end;

# ╔═╡ 2ba9d8d3-247e-4ac3-82b4-e914076203a9
function compile(::Val{:local}, args)
	(name, t) = args[1].args
	sexpr(:local, ident(name), value_types[t])
end;

# ╔═╡ 0f63e48e-6458-4ec9-9e6d-f437e0d33ada
function compile(::Val{:(=)}, args)
	join([compile(args[2]), '\n', sexpr("local.set", ident(args[1]))])
end;

# ╔═╡ 06d20a34-7576-4691-8fb7-555eb68cfc89
function compile(::Val{:call}, args) 
	compile_func(fname::Symbol) = sexpr(:call, ident(fname))
	compile_func(op::NumInstr) = op
	
	join([compile.(args[2:end])..., compile_func(args[1])], ' ')
end;

# ╔═╡ 37b6e4fb-f177-4acb-ac58-a3abc04c12da
md"""
## Execution ...
"""

# ╔═╡ 0f6d4436-c7ea-495f-957a-848613de460f
assemble(wat) = read(pipeline(IOBuffer(wat), `wasm-tools parse`));

# ╔═╡ 2f91fb69-8b01-4e9e-87dd-dc2876bf1ec0
function run_wasm(bin, main=:main)
	x = gensym()
	@htl(
		"""
		<script>
			const wasmCode = $(published_to_js(bin));
			const wasmModule = new WebAssembly.Module(wasmCode);
			const wasmInstance = new WebAssembly.Instance(wasmModule);
		
			const main = wasmInstance.exports.$main;
			document.getElementById("$x").innerHTML = main();
		</script>
		<p>
			<span id="$x">?</span>
		</p>
		"""
	)
end;

# ╔═╡ 5b015e2e-d1d0-46ef-97e7-9f57cc0ed654
macro wasm(expr)
	analyze(expr)
	wat = compile(expr)
	@debug wat
	assemble(wat)
end;

# ╔═╡ 639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
bin = @wasm module _
	export main

	function sign(x::Float64)::Float64
		if x == 0.0
			0.0
		elseif x < 0.0
			-1.0
		else
			1.0
		end
	end

	function addsign(x::Float64)::Float64
		x + sign(x)
	end

	function main()::Float64
		x::Float64 = -2.5
		addsign(x)
	end
end

# ╔═╡ 08f6685f-f27f-455a-a31b-db2b37f9fb54
run_wasm(bin)

# ╔═╡ ef86e977-6d6c-4954-82f8-54e79a64f995
md"""
## Examples
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
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

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
# ╠═713a951e-eef7-11ef-1d65-b975371b6ab6
# ╠═b11c9b3a-d108-4cd1-ad2a-16064d15482d
# ╠═2a00780f-4322-455f-af3e-eba952abf64b
# ╠═3083b769-a9af-4831-ab78-e07671db4a80
# ╠═bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
# ╠═49d328d5-a16d-4510-b07b-a9cc908c8310
# ╠═b68ac919-095d-40f8-9bd9-a3a5ee62c484
# ╠═5e819f03-b27b-4190-9043-af88e031b9bd
# ╠═493a3465-d6ee-4dbd-8450-863a2a9e5ae1
# ╠═22c17393-eca3-44cb-bde6-ef78d2e337a5
# ╠═bdba6817-5fe4-4dd5-941b-d4c57535244e
# ╠═497bf2a9-1e6b-4519-9ce7-36ff5a945214
# ╠═916914b0-861d-472e-ab21-6ec3f915986a
# ╠═2078ff46-b3d9-4e3b-a9a3-4c7115412584
# ╠═59edf6b6-498f-480f-8cca-4dfc0d54ad00
# ╠═0b71a7f1-86cc-4034-98ba-9aa1bb32c3cb
# ╠═b05e6426-2c26-455e-b18c-12676e25ba2b
# ╠═f7ee1048-42e1-4c29-98ca-b0486cfad4ac
# ╠═1c653ada-e4fe-4531-b63c-80a2fa349383
# ╠═8c77097c-5179-49d9-90b9-1068ed57205b
# ╠═376fabca-a483-4cc8-b852-eb79a4f85b66
# ╠═21e1e640-7f99-479e-9c5d-8367752ad694
# ╠═465fb73a-65d4-4dad-aa50-a5e6d2907f3a
# ╠═8815bd45-6159-4efd-bffc-654e8857cf59
# ╠═90098ad7-5e9c-4e78-b310-4c83f039d448
# ╠═e57e7a76-1dad-4a58-8ac1-8031c969da24
# ╠═7968e313-e222-49f3-b3b4-958a33c85acf
# ╠═b6a962ea-29fe-4b84-892c-2cffd06fc776
# ╠═1410504f-af8c-498f-9966-7402d2d4abf3
# ╠═2558d535-9611-4f52-b23c-fd2ba6c3dab0
# ╠═73c32ba9-3558-4157-b578-eb4b39f3d9df
# ╠═9b39f2b3-f304-4ca5-b978-138d581b6131
# ╠═8560e6c3-086c-4d43-ab44-c8373df867ab
# ╠═ae62d583-5d18-4638-8d15-1dc712251172
# ╠═80cf9e1a-0001-4326-8529-6b0a552a6983
# ╠═368cd41d-a4ab-4cc3-bc23-1e699acbddb4
# ╠═8a44508f-5d71-4ac5-8859-2055274b8f9f
# ╠═0779191f-61c2-405a-804b-a09063599d92
# ╠═081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
# ╠═ade2233f-5253-43da-a95f-84682d9299b4
# ╠═29c7ed38-3eca-4d59-aa83-4acfd25ffa26
# ╠═8fa0fc6a-fb9e-4737-9888-98571f322e97
# ╠═fb7b2997-731c-4a92-b359-82f17b8db299
# ╠═41c29c01-6af6-4b2d-bcc8-60e44a99ce34
# ╠═4834f3ed-eb2a-4ec3-9575-8fd3777d248e
# ╠═001f39f8-c254-48a3-acc2-d64a8344b5dd
# ╠═dfddc124-afd3-4934-8cfc-3c3596e9854d
# ╠═8d7a8f03-5a48-439b-8012-1165ae470f3d
# ╠═348cec8f-2002-4972-ad32-932fe3ac4e15
# ╠═2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
# ╠═c578e254-2171-4803-b03e-4f910ef655b8
# ╠═80379f3b-4c3a-46cd-b1a1-fc14f67052a0
# ╟─9d6afbad-e03f-46e7-8fd6-24817016ad81
# ╠═24c850c6-e9b9-47fb-8d40-34cafc0a5ac0
# ╠═635f057b-c0f9-4d34-82f6-87b92f7a909f
# ╠═85b863bc-8091-43b4-ab31-fc406b86b6ed
# ╠═3436fac4-a083-499d-a48c-4b95c431a797
# ╠═55716561-84d0-4eab-b081-eea439411e7a
# ╠═eb287d52-7375-4226-bd2a-97f4c2a435bd
# ╠═0e9b8f09-cdbd-48b6-a81b-5fc04e55ab56
# ╠═5aea4283-8366-4028-b2ad-0227e7b2d9c5
# ╠═02915b1b-fcba-4d59-a9cd-2f07cf2b6d98
# ╠═83d4c742-7618-4a53-81c8-1db498559d01
# ╠═09224b80-0cde-4b46-868e-38d8ee891d3f
# ╠═ea7f10a3-9469-4207-a9ed-de244c56b73a
# ╠═b04ba764-f39b-4a7b-ad8b-b0f3a793645e
# ╠═589c8a1b-f246-476d-8e6e-b7e321829b1b
# ╠═2ba9d8d3-247e-4ac3-82b4-e914076203a9
# ╠═0f63e48e-6458-4ec9-9e6d-f437e0d33ada
# ╠═06d20a34-7576-4691-8fb7-555eb68cfc89
# ╠═37b6e4fb-f177-4acb-ac58-a3abc04c12da
# ╠═0f6d4436-c7ea-495f-957a-848613de460f
# ╠═5b015e2e-d1d0-46ef-97e7-9f57cc0ed654
# ╠═2f91fb69-8b01-4e9e-87dd-dc2876bf1ec0
# ╠═ef86e977-6d6c-4954-82f8-54e79a64f995
# ╠═639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
# ╠═08f6685f-f27f-455a-a31b-db2b37f9fb54
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
