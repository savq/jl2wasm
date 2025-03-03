### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 2a00780f-4322-455f-af3e-eba952abf64b
begin
	using Test
	using HypertextLiteral: @htl
	using AbstractPlutoDingetjes.Display: published_to_js;
	using PlutoUI: TableOfContents
end

# ╔═╡ d5d9447f-c0db-4810-89d7-0e4ce1566e86
TableOfContents()

# ╔═╡ 4acb880b-60a0-42d6-bfea-26935426b30c
run(`type wasm-tools`);

# ╔═╡ 2163ebda-6741-4390-b79c-4d3fe6fc9b4b
:x

# ╔═╡ 24534cd6-a102-4d5e-80c6-f75e158e4fbf
typeof(:x)

# ╔═╡ 1096a6cc-636d-486b-8ccd-5309ae231efa
let e = :(f(x) + 1)
	@debug sprint(dump, e) # Get verbose representation
end

# ╔═╡ b05e6426-2c26-455e-b18c-12676e25ba2b
struct Env
	var_types::Dict{Symbol, Symbol}					# V => T
	func_types::Dict{Symbol, Tuple{Tuple, Symbol}}	# F => (Tₚ, ...) -> Tᵣₑₜ

	# Constructors
	Env() = new(Dict(), Dict())
	Env(vars, funcs) = new(vars, funcs)
	Env(vars...) = new(Dict(vars...), Dict())
	Env(super::Env) = new(copy(super.var_types), copy(super.func_types))
end

# ╔═╡ f7ee1048-42e1-4c29-98ca-b0486cfad4ac
Base.in(var, env::Env) = var in keys(env.var_types)

# ╔═╡ 1c653ada-e4fe-4531-b63c-80a2fa349383
Base.getindex(env::Env, var::Symbol) = env.var_types[var]

# ╔═╡ 33d906e5-23be-4eba-a682-4ddb776b9bad
md"""
# jl2wasm
_A compiler from a subset of Julia to WebAssembly_

Sergio Alejandro Vargas Q.\
savargasqu@unal.edu.co

Compiladores 2024-II\
Universidad Nacional de Colombia
"""

# ╔═╡ 2b15644f-7898-4373-947f-719055d6ce48
md"""
# Dependencies

A couple of package to load our wasm binary in the browser.
"""

# ╔═╡ 222c8445-0ca9-42e1-b26a-12953a3c910f
md"""
### External depencencies

- [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools): To convert wasm text format to binary format.
"""

# ╔═╡ a5a3c821-f111-4951-bf69-56b1bb70d4bb
md"""
# Target Language: WebAssembly

WebAssembly is neither web nor assembly... Instead:

- Binary instruction format
- Stack-based virtual machine
- Structured control flow (no `goto`)
- Static type system
- Not just for the web! (cloud, embedded, etc)

We'll compile to WebAssembly Text Format (**wat**), not directly to binary.

```wat
;; wat uses an s-expression based syntax

(module                                     ;; All wasm binaries are modules

  (export "inc" $inc)

  (func $inc (param $x i32) (result i32)    ;; Define function
    (local.get $x)                          ;; Push x
    (i32.const 1)                           ;; Push 1 (integer of 32 bits)
    (i32.add)))
```
"""

# ╔═╡ bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
md"""
# Source language: Mini-Julia

Take a very small subset of Julia:

- Modules
- Functions
- Conditionals
- Variables
- Static type system (!)
- Numeric data types: integers and floats


Mini-Julia is Turing-complete, but we'll only be able to write very basic numerical algorithms.

```julia
module _
	export inc

	function inc(x::Int32)::Int32
		x + 1
	end
end
```
"""

# ╔═╡ 49d328d5-a16d-4510-b07b-a9cc908c8310
md"""
# Parsing

Use Julia metaprogramming to get parsing for free.

Julia represents its own source code using the `Expr` and `Symbol` types.

`quote` or `:` return the AST of an expression.
"""

# ╔═╡ aeee5645-eead-40d5-af78-e8cdae89376b
md"""
Symbols represent identifiers.
"""

# ╔═╡ 3b824756-e098-452a-aeac-4b07088834c1
md"""
`Expr` represents expressions. Every `Expr` has
- A `head` indicating the kind of expression it is (definition, call, etc.)
- An `args` vector pointing to the child nodes of the expression.
"""

# ╔═╡ b68ac919-095d-40f8-9bd9-a3a5ee62c484
md"""
# Semantic Analysis

Walk the AST to check:

- Variable resolution
- Type checking
- Lowering/desugaring

We'll do all three in a single pass.

If any of these steps fails, report the error and exit.
"""

# ╔═╡ 0b71a7f1-86cc-4034-98ba-9aa1bb32c3cb
md"""
## Environments

Define a data structure to store information about variables and their types.

Every environment has two namespaces (no first-class functions).

Environments don't keep a reference to their parent environments, When we need nested environments, copy the parent environment.
"""

# ╔═╡ 3a7d3660-8e3f-40f1-a08f-06cf1b5762d7
md"""
Define a few helper functions to query and update the variables' table.

No helper methods for the functions' table, tho.

Note the syntax sugar.
"""

# ╔═╡ 5e819f03-b27b-4190-9043-af88e031b9bd
md"""
## Compilation Errors

Define error types for the compiler (to distinguish them from other Julia errors).
"""

# ╔═╡ 493a3465-d6ee-4dbd-8450-863a2a9e5ae1
struct CompilerError <: Exception
	msg::String
end

# ╔═╡ 916914b0-861d-472e-ab21-6ec3f915986a
struct TypeMismatchError <: Exception
	msg::String
end

# ╔═╡ 91875dd9-ebc5-4463-8d8b-a5c19ae06b81
md"Customize the error message that gets printed when the error is raised."

# ╔═╡ 22c17393-eca3-44cb-bde6-ef78d2e337a5
Base.showerror(io::IO, err::CompilerError) = print(io, "(wasm2jl) ", err.msg)

# ╔═╡ 2078ff46-b3d9-4e3b-a9a3-4c7115412584
Base.showerror(io::IO, e::TypeMismatchError) =
	print(io, "(wasm2jl) Type mismatch: ", e.msg)

# ╔═╡ aa9787e9-ed71-4a23-becc-e959bb9b5047
md"""
Use a macros to throw error more easily.

(If we used functions they'd show up in the call stack!)
"""

# ╔═╡ bdba6817-5fe4-4dd5-941b-d4c57535244e
macro compiler_error(msg)
	esc(:(throw(CompilerError($msg))))
end;

# ╔═╡ 8c77097c-5179-49d9-90b9-1068ed57205b
function Base.setindex!(env::Env, t::Symbol, var::Symbol)
	if var in keys(env.var_types)
		@compiler_error "Variable is already defined: $var"
	else
		env.var_types[var] = t
	end
	return
end;

# ╔═╡ 59edf6b6-498f-480f-8cca-4dfc0d54ad00
macro type_mismatch(msg)
	esc(:(throw(TypeMismatchError($msg))))
end;

# ╔═╡ 799a5edc-86e2-4d04-aaef-be3d273ecf0e
md"""
## Walking the AST

Define a function `analyze!` to handle all the semantic analysis of the compiler.

Walk tree in post-order: The type of an expression is based on the type of its subexpressions.

`analyze!` will return the type of the expression.

The entry point of our analysis will be a method that takes an arbitrary expression,
and then dispatchs on the head (the kind of expression).

Use `Val` to turn the `head` symbol into a type that Julia can dispatch on.
"""

# ╔═╡ 8815bd45-6159-4efd-bffc-654e8857cf59
function analyze!(expr::Expr, env=Env())
	kind = Val(expr.head)
	filter!(e -> !(e isa LineNumberNode), expr.args) # Ignore me!
	analyze!(kind, expr.args, env)
end;

# ╔═╡ d2d39793-9862-4109-88bd-e4fab2a1196f
md"""
Not all Julia syntax is valid in our compiler.

Log an error for the forms the compiler doesn't understand.

(this was really helpful for writing the compiler iteratively!)
"""

# ╔═╡ 90098ad7-5e9c-4e78-b310-4c83f039d448
function analyze!(::Val{S}, _args, env) where {S}
	@error "Form not implemented: $S"
end;

# ╔═╡ 91d7dad5-ee47-4e56-8722-e471fcf42b5e
md"For example,"

# ╔═╡ e9e27ccf-693b-4911-84ff-f7d8c11e910d
md"""
## Variables

The type of a variable is whatever we have in the environment.

If the variable is not in the environment, it's undefined.
"""

# ╔═╡ 7968e313-e222-49f3-b3b4-958a33c85acf
function analyze!(var::Symbol, env)
	if var in env
		env[var]
	else
		@compiler_error "Undefined variable: $var"
	end
end

# ╔═╡ 744ea5d8-98a7-42e0-9f8f-0f5ac43509e8
md"For example,"

# ╔═╡ cc7854e7-8b01-4e34-9c70-2ac58d80d06d
md"""
## Numbers

Numbers are stored directly in the AST (not as symbols).

Wasm only has integers and floats of 32 and 64 bits. Smaller numbers need to be promoted.
"""

# ╔═╡ b6a962ea-29fe-4b84-892c-2cffd06fc776
function analyze!(::Z, _) where {Z <: Integer}
	nameof(promote_type(Z, Int32))
end;

# ╔═╡ 1410504f-af8c-498f-9966-7402d2d4abf3
function analyze!(::R, _) where {R <: AbstractFloat}
	nameof(promote_type(R, Float32))
end;

# ╔═╡ f3ecbf76-9fac-4c88-a8f8-cc90cb5ab798
md"""
### A note on booleans

In wasm, 32 bit integers serve as booleans (like in C).

In Julia, `Bool <: Integer`. Using the method above, we got booleans for free 🤷

For example,
"""

# ╔═╡ 2558d535-9611-4f52-b23c-fd2ba6c3dab0
md"""
## Blocks and Modules

```julia
module MyModule
	...
end
```
"""

# ╔═╡ 9b39f2b3-f304-4ca5-b978-138d581b6131
function analyze!(::Val{:block}, args, env)
	if length(args) > 0
		last(map(e -> analyze!(e, env), args))
	else
		:Nothing
	end
end;

# ╔═╡ 73c32ba9-3558-4157-b578-eb4b39f3d9df
function analyze!(::Val{:module}, args, env)
	(_, mname, body) = args

	# Find exports and functions
	exports = Symbol[]
	exprs = []

	for e in body.args
		if e isa Expr && e.head == :export
			append!(exports, e.args)
		elseif e isa LineNumberNode # Ignore me!
		else
			push!(exprs, e)
		end
	end

	# Analyze every function
	analyze!(Expr(:block, exprs...), env)

	# Resolve exports
	for export_name in exports
		if export_name ∉ keys(env.func_types)
			@compiler_error "Undefined export: `$export_name`"
		end
	end

	# Rewrite body of module so exports are listed first
	args[3] = Expr(
		:block,
		map(name -> :(export $name), exports)...,
		exprs...
	)

	return :Nothing
end;

# ╔═╡ 8560e6c3-086c-4d43-ab44-c8373df867ab
md"""
## Assignments

```julia
x = ...
x::T = ...
```
"""

# ╔═╡ 80cf9e1a-0001-4326-8529-6b0a552a6983
"check patterns like x::T"
function type_pattern(pat::Expr)
	if pat.head == :(::)
		(pat.args...,)
	else
		@compiler_error "Unexpected pattern: `$pat`"
	end
end;

# ╔═╡ 368cd41d-a4ab-4cc3-bc23-1e699acbddb4
type_pattern(pat) = @compiler_error "Unexpected pattern: `$pat`";

# ╔═╡ ae62d583-5d18-4638-8d15-1dc712251172
function analyze!(::Val{:(=)}, args, env)
	(lhs, rhs) = args
	rtype = analyze!(rhs, env)

	if lhs isa Symbol
		if lhs ∉ env						# New variable. Infer type.
			env[lhs] = rtype
		elseif env[lhs] != rtype			# Existing variable. Compare types.
			ltype = env[lhs]
			@type_mismatch(
				"""
				Variable `$lhs` of type `$ltype` was assigned expression of type `$rtype`.
				"""
			)
		end
	else
		(var, ltype) = type_pattern(lhs)	# New variable. Assert type.
		if ltype == rtype
			env[var] = ltype
			args[1] = var
		else
			@type_mismatch(
				"""
				Variable `$lhs` of type `$ltype`, was assigned expression of type `$rtype`.
				"""
			)
		end
	end
	return :Nothing							# Assignments are statements.
end;

# ╔═╡ 8a44508f-5d71-4ac5-8859-2055274b8f9f
md"""
## Function Definitions

```julia
function f(x::T, ...)::T
	...
end
```

"""

# ╔═╡ 081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
function analyze_signature(sig::Expr, fenv)
	if sig.head == :call
		fname = sig.args[1]

		# Extract parameter types
		params = sig.args[2:end]

		# Vector{Tuple} to Tuple{Vector}
		(pnames, ptypes) = splat(zip)(map(type_pattern, params))

		# Add parameters to function environment
		map((p, t) -> fenv[p] = t, pnames, ptypes)

		ret_type = :Nothing

	elseif sig.head == :(::)
		(fname, _, pnames, ptypes) = analyze_signature(sig.args[1], fenv)
		ret_type = sig.args[2]
	end

	return (fname, ret_type, pnames, ptypes)
end;

# ╔═╡ 0779191f-61c2-405a-804b-a09063599d92
function analyze!(::Val{:function}, args, env)
	(sig, body) = args

	# Create environment for function
	fenv = Env(env)

	# Analyze signature
	(fname, ret_type, pnames, ptypes) = analyze_signature(sig, fenv)

	# Update outer and inner environment
	env.func_types[fname] = fenv.func_types[fname] = (ptypes, ret_type)

	# Assert return type
	last_type = analyze!(body, fenv)

	if last_type != ret_type
		@type_mismatch(
			"""
			Function `$fname` has return type `$ret_type`, but last expression has type `$last_type`.
			"""
		)
	end

	# Write local variable declarations
	var_decls = [:(local $v::$t) for (v, t) in pairs(fenv.var_types) if v ∉ pnames]
	prepend!(body.args, var_decls)

	return
end;

# ╔═╡ 92344bda-acba-417c-8d32-1e2a6ed1341d
let sig = :( g(x::Int32, y::Int32)::Int32 )
	@debug analyze_signature(sig, Env())
end

# ╔═╡ ade2233f-5253-43da-a95f-84682d9299b4
md"""
## Function Calls

```julia
f(x, ...)
```
"""

# ╔═╡ 8fa0fc6a-fb9e-4737-9888-98571f322e97
md"""
## Numeric Operations

Define a struct for numeric operations. (this will make compilation a bit easier.)
"""

# ╔═╡ 41c29c01-6af6-4b2d-bcc8-60e44a99ce34
struct NumOp
	instr::Symbol
	type::Symbol
end

# ╔═╡ 4834f3ed-eb2a-4ec3-9575-8fd3777d248e
Base.show(io::IO, op::NumOp) = write(io, op.type, '.', op.instr)

# ╔═╡ 01a65ca7-8423-467f-ae1a-d61f6cc86391
md"""
Map Julia types to wasm value types.
"""

# ╔═╡ 001f39f8-c254-48a3-acc2-d64a8344b5dd
float_types = Dict(
	:Float32 => :f32,
	:Float64 => :f64,
);

# ╔═╡ 56220b2d-7ee4-4118-8f88-aef5d7478534
int_types = Dict(
	:Int32 => :i32,
	:Int64 => :i64,
);

# ╔═╡ eb287d52-7375-4226-bd2a-97f4c2a435bd
value_types = Dict(union(float_types, int_types))

# ╔═╡ 35622d1b-0167-4e87-beca-9ae83476fe41
md"""
Map Julia operators to wasm instructions.
"""

# ╔═╡ 8d7a8f03-5a48-439b-8012-1165ae470f3d
f_un_ops = (
	abs  = :abs,
	-    = :neg,
	sqrt = :sqrt,
	√    = :sqrt,
);

# ╔═╡ 348cec8f-2002-4972-ad32-932fe3ac4e15
f_bin_ops = (
	+ = :add,
	- = :sub,
	* = :mul,
	/ = :div,
	min      = :min,
	max      = :max,
	copysign = :copysign,
);

# ╔═╡ 2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
i_bin_ops = (
	+  = :add,
	-  = :sub,
	*  = :mul,
	/  = :div_s,
	%  = :rem_s,
	/ᵤ = :div_u,
	%ᵤ = :rem_u,

	(&) = :and,
	|   = :or,
	^   = :xor,
	⊻   = :xor,
	<<  = :shl,
	>>  = :shr_s,
	>>ᵤ = :shr_u,
);

# ╔═╡ c578e254-2171-4803-b03e-4f910ef655b8
rel_ops = (
	== = :eq,
	!= = :ne,
	<  = :lt,
	>  = :gt,
	<= = :le,
	>= = :gt,
);

# ╔═╡ 80379f3b-4c3a-46cd-b1a1-fc14f67052a0
operators = union(keys.([f_un_ops, f_bin_ops, i_bin_ops, rel_ops])...)

# ╔═╡ 5accfa8f-0ef2-4960-8a4a-7f4a50798756
md"""
## Binary Operators

In binary expressions, both sides need to be of the same type.
"""

# ╔═╡ fb7b2997-731c-4a92-b359-82f17b8db299
function analyze_binary(op, ltype, rtype)
	if ltype == rtype
		if op in keys(rel_ops)
			ret_type = :Int32 		# Comparisons return "boolean"
			instr = rel_ops[op]
		else
			ret_type = ltype		# Other ops return the same type as operands

			if ltype in keys(float_types) && op in keys(f_bin_ops)
				instr = f_bin_ops[op]
			elseif ltype in keys(int_types) && op in keys(i_bin_ops)
				instr = i_bin_ops[op]
			else
				@type_mismatch("Operator `$op` is not defined for type: `$ltype`.")
			end
		end
		return (instr, ltype, ret_type)
	else
		@type_mismatch("Operator `$op` got different types: `$ltype` and `$rtype`.")
	end
end;

# ╔═╡ 4cc4abf2-98a7-4d1c-b8b6-aec96ac04637
md"""
## Unary Operators
"""

# ╔═╡ 7427d9fc-e910-4c97-a2ae-704180dd206e
function analyze_unary(op, t)
	if t in keys(float_types)
		instr = f_un_ops[op]
		return (instr, t, t)
	else
		@type_mismatch("Operator `$op` is not defined for type: `$t`.")
	end
end;

# ╔═╡ 29c7ed38-3eca-4d59-aa83-4acfd25ffa26
function analyze!(::Val{:call}, args, env)
	fname = args[1]
	fargs = args[2:end]

	arg_types = map(a -> analyze!(a, env), fargs)	# Analyze arguments

	if fname in keys(env.func_types)				# Check user defined function
		(param_types, ret_type) = env.func_types[fname]
		if any(arg_types .!= param_types)
			@type_mismatch(
				"Function `$fname` expected types $param_types, but got types $arg_types"
			)
		end
		return ret_type

	elseif fname in operators 						# Check built-in operator
		arity = length(arg_types)
		if arity == 1
			(op, op_type, ret_type) = analyze_unary(fname, arg_types[1])
		elseif arity == 2
			(op, op_type, ret_type) = analyze_binary(fname, arg_types...)
		end

		args[1] = NumOp(op, value_types[op_type])	# Rewrite op
		return ret_type
	else
		@compiler_error "Undefined function: `$fname`"
	end
end;

# ╔═╡ 24c850c6-e9b9-47fb-8d40-34cafc0a5ac0
md"""
## Conditionals

```julia
if cond₁
	consequent₁
elseif cond₂
	consequent₂
else
	alternative
end
```
Always include `else`.

Rewrite `elseif`s into nested `if`s.

The result type of the conditional needs to be written in the wasm code.
"""

# ╔═╡ 85b863bc-8091-43b4-ab31-fc406b86b6ed
function desugar_conditional!(expr::Expr)
	if expr.head == :elseif
		expr.head = :if
	end
	if expr.head == :if
		if isodd(length(expr.args))
			desugar_conditional!(expr.args[3])	# check for `elseif`
		else
			push!(expr.args, Expr(:block))		# add `else`
		end
	end
end;

# ╔═╡ 3436fac4-a083-499d-a48c-4b95c431a797
desugar_conditional!(_) = nothing;

# ╔═╡ 635f057b-c0f9-4d34-82f6-87b92f7a909f
function analyze!(::Val{:if}, args, env)
	desugar_conditional!.(args)

	if iseven(length(args))
		push!(args, Expr(:block))	# Add `else`
	end

	(condition, consequent, alternative) = args

	t_cond = analyze!(condition, env)
	if t_cond !== :Int32
		@type_mismatch(
			"""
			Expected condition expression of type `Int32`, but got type `$t_cond`.
			"""
		)
	end

	t_then = analyze!(consequent, env)
	t_else = analyze!(alternative, env)

	if t_then == t_else
		push!(args, t_then)		# Hack!
	else
		@type_mismatch(
			"""
			Expected conditional branches of the same type, but got different types `$t_then` and `$t_else`.
			"""
		)
	end

	return t_then
end;

# ╔═╡ b6233b2c-0916-4699-9d7a-8f61a8ad3dbc
analyze!(:(1 + 1))

# ╔═╡ b1990a23-a756-41c8-b595-64c374062e6f
analyze!(:[x for x in xs])

# ╔═╡ 46831b43-9d3a-4171-9db0-2410a610d889
let Γ = Env(:x => :Float32)
	@debug "x: " analyze!(:x, Γ)

	try
		analyze!(:y, Γ)
	catch err
		@error "y: " err
	end
end

# ╔═╡ b69ab174-ceef-4c9d-ad85-522c914cf628
let Γ = Env()
	@debug analyze!(3.14, Γ)
	@debug analyze!(0xFF, Γ), typeof(0xFF)
	@debug analyze!(false, Γ)
end

# ╔═╡ 9ce27d00-622e-42ed-a226-99e0921f32ad
@testset begin
	@test analyze!(quote
		x::Int64 = 1
		x = 2
		x
	end) == :Int64

	@test_throws TypeMismatchError analyze!(quote
			x::Int64 = 1
			x = 2.0
			x
	end)

	@test_throws CompilerError analyze!(quote
			x::Int64 = 1
			x::Float64 = 2.0
	end)
end

# ╔═╡ e20fa141-bad9-4e8c-95f7-e22080b26386
let e = :(function f()::Int64
			a = 1
			b = 2
			a + b
		end)

	analyze!(e, Env())
	e
end

# ╔═╡ d0374658-917b-412a-a23a-c02f46c30403
let Γ = Env(
		Dict(:a => :Int32, :b => :Int32),
		Dict(:f => ((:Int32, :Int32), :Float64))
	),
	e = :(f(a, b))

	@test analyze!(e, Γ) == :Float64
end

# ╔═╡ 8bc1257e-67f9-4234-a956-bf19b7dab1b7
let e₁ = :(1 + 2)
	@test analyze!(e₁) == :Int64
	@debug e₁

	e₂ = :(3.14 * 2.0)
	@test analyze!(e₂) == :Float64
	@debug e₂

	e₃ = :(4.20 < 5.0)
	@test analyze!(e₃) == :Int32
	@debug e₃
end

# ╔═╡ 3eda0e11-488f-4b31-a5a0-6be2740e830d
let e₁ = :(√2.0)
	analyze!(e₁)
	@debug e₁

	e₂ = :(√2.0f0)
	analyze!(e₂)
	@debug e₂
end

# ╔═╡ e6978e8b-b7f9-416b-b934-d425c01ab582
let e = quote
		if x > 0
			1.0
		elseif x == 0
			0.0
		else
			-1.0
		end
	end
	@test analyze!(e, Env(:x => :Int64)) == :Float64
end

# ╔═╡ 55716561-84d0-4eab-b081-eea439411e7a
md"""
# Compilation

Define a function `compile` that return a string with the wat represention of a program.

Exactly the same strategy as `analyze!`
- Walk the tree
- Dispatch on `head`

`analyze!` did all the hard work, so this is mostly mechanical.
"""

# ╔═╡ e4a0cc0f-5f35-4289-9270-148e4be99c32
compile(expr::Expr) = compile(Val(expr.head), expr.args);

# ╔═╡ 277870c7-e4fb-4232-9170-3b69c3200121
md"""
Define helper functions to help with wat conventions, and to make output somewhat readable.
"""

# ╔═╡ 5aea4283-8366-4028-b2ad-0227e7b2d9c5
sexpr(xs...) = string('(', join(xs, ' '), ')');

# ╔═╡ 3eaab51d-a4db-4779-a8e1-a93e54ecfa0b
joinln(xs...) = join(xs, '\n');

# ╔═╡ 0e9b8f09-cdbd-48b6-a81b-5fc04e55ab56
ident(id::Symbol) = string('$', id);

# ╔═╡ 4dcd5268-6194-4628-a874-c569ac0daaf5
compile(::LineNumberNode) = '\n';

# ╔═╡ 378a2523-85eb-4273-89dd-108722793228
md"""
## Compiling Terminals
```wasm
(i64.const 1)

(local.set $x)
```
"""

# ╔═╡ bd00b805-32e7-4ea8-8305-e17a0331fd5b
md"Using a variable becomes a `get` instruction."

# ╔═╡ 7c38261d-7cdb-4801-a2c5-259ea58282d6
compile(id::Symbol) = sexpr("local.get", ident(id));

# ╔═╡ 72cb168f-a908-496e-9e7e-02faad98e98f
md"Assigning to a variable becomes a `set` instruction."

# ╔═╡ 0f63e48e-6458-4ec9-9e6d-f437e0d33ada
function compile(::Val{:(=)}, args)
	(lhs, rhs) = args
	joinln(compile(rhs), sexpr("local.set", ident(lhs)))
end;

# ╔═╡ 4cd8ff6c-4c73-4e45-88e1-f7c09ca81454
md"Numbers become `const` instructions."

# ╔═╡ 5daede5f-5fc7-4533-8ee7-004074573c05
function compile(n::Number)
	t = value_types[analyze!(n, Env())]
	sexpr("$t.const", string(n))
end;

# ╔═╡ 0aad810b-5f99-41dc-b1fe-dc3cef26cc70
md"""
## Compiling Blocks and Modules


```wasm
(module
	...)
```
"""

# ╔═╡ e1c68c54-c57f-444c-84d0-44419f3e280e
compile(::Val{:block}, args) = joinln(compile.(args)...);

# ╔═╡ 83d4c742-7618-4a53-81c8-1db498559d01
compile(::Val{:module}, args) = sexpr(:module, '\n' * compile(args[3]));

# ╔═╡ 09224b80-0cde-4b46-868e-38d8ee891d3f
function compile(::Val{:export}, args)
	name = args[1]
	sexpr(:export, "\"$name\"", sexpr(:func, ident(name)))
end;

# ╔═╡ caeab89c-5bf0-45af-b89c-1690c0d2d352
md"The simplest wasm program is the empty module:"

# ╔═╡ b398f64c-9464-4818-a545-abb352eb4f04
md"""
## Compiling Function Definitions

```wasm
(func $f (param $x i32) (result i32)
	(local $a i32)
	...)
```
"""

# ╔═╡ b04ba764-f39b-4a7b-ad8b-b0f3a793645e
function compile_signature(sig)
	if sig.head == :call
		(fname, fparams...) = sig.args
		ret_type = ""
	elseif sig.head == :(::)
		(fname, fparams, _) = compile_signature(sig.args[1])
		ret_type = value_types[sig.args[2]]
	end
	(fname, fparams, ret_type)
end;

# ╔═╡ 7c805a4e-75ae-403c-a12f-f9aa1e27f441
function compile_param(param::Expr)
	(p, t) = param.args
	sexpr(:param, ident(p), value_types[t])
end;

# ╔═╡ ea7f10a3-9469-4207-a9ed-de244c56b73a
function compile(::Val{:function}, args)
	(sig, body) = args
	(fname, fparams, ret_type) = compile_signature(sig)
	sexpr(
		:func,
		ident(fname),
		map(compile_param, fparams)...,
		sexpr(:result, ret_type),
		'\n' * compile(body),
	)
end;

# ╔═╡ 2ba9d8d3-247e-4ac3-82b4-e914076203a9
function compile(::Val{:local}, args)
	(name, t) = args[1].args
	sexpr(:local, ident(name), value_types[t])
end;

# ╔═╡ 938e7247-030a-4fe0-aa46-1ee50141a21a
md"""
## Compiling Function Calls

```wasm
...
(call $f)

...
i64.add
```

`NumOp` already has a string representation.

Wasm is a stack machine, write arguments in post-order.
"""

# ╔═╡ c5a9ca3c-08ae-4477-8ca6-6b6c2dfbcb29
compile_func(fname::Symbol) = sexpr(:call, ident(fname));

# ╔═╡ c9dd4aee-64dc-4fe7-8abb-de59bd7d6d9e
compile_func(op::NumOp) = op;

# ╔═╡ 06d20a34-7576-4691-8fb7-555eb68cfc89
compile(::Val{:call}, args) = joinln(
	compile.(args[2:end])...,
	compile_func(args[1]),
);

# ╔═╡ 3e34769b-ac84-44cb-b8c7-86bb35344ae6
md"""
## Compiling Conditionals

```wasm
... ;; condition
if
(result i32)
	...
else
	...
end
```
"""

# ╔═╡ 589c8a1b-f246-476d-8e6e-b7e321829b1b
function compile(::Val{:if}, args)
	(condition, consequent, alternative) = compile.(args[1:3])

	if args[4] !== :Nothing
		result_type = sexpr(:result, value_types[args[4]]) # Hack... again!
	else
		result_type = ""
	end

	joinln(
		condition,
		:if,
		result_type,
		consequent,
		:else,
		alternative,
		:end,
	)
end;

# ╔═╡ cc71a919-3a1f-47a0-a3d5-02d812e0bdc0
let e = :(x = y)
	@debug compile(e)
end

# ╔═╡ c9cd462e-e7df-43dc-b2e6-10e78da8e725
let e = :(module _; end)
	@debug compile(e)
end

# ╔═╡ 37b6e4fb-f177-4acb-ac58-a3abc04c12da
md"""
# Assembly

Define helper function to send wat to `wasm-tools`.

Define helper `@wasm` macro to perform all stages of compilation.
"""

# ╔═╡ 0f6d4436-c7ea-495f-957a-848613de460f
assemble(wat) = read(pipeline(IOBuffer(wat), `wasm-tools parse`));

# ╔═╡ 5b015e2e-d1d0-46ef-97e7-9f57cc0ed654
macro wasm(expr)
	analyze!(expr)
	# @debug expr

	wat = compile(expr)
	@debug wat

	assemble(wat)
end;

# ╔═╡ 13b3d646-db95-4779-8766-167626827ec9
@wasm module HelloWasm
	function inc(x::Int64)::Int64
		x + 1
	end
end

# ╔═╡ ef86e977-6d6c-4954-82f8-54e79a64f995
md"""
# Examples
"""

# ╔═╡ 639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
bin =
	@wasm module _
		export fibo, gcd, dist

		function my_abs(n::Int64)::Int64
		    mask = (n >> 63)
		    (n ⊻ mask) - mask
		end

		function gcd(a::Int64, b::Int64)::Int64
			a = my_abs(a)
			b = my_abs(b)
		    if b == 0
		        a
			else
		    	gcd(b, a % b)
			end
		end

		function fibo(n::Int64)::Int64
			if (n == 0) | (n == 1)
				1
			else
				fibo(n - 1) + fibo(n - 2)
			end
		end

		function dist(x::Float32, y::Float32)::Float32
			√(x*x + y*y)
		end
	end

# ╔═╡ d3671958-852b-49a8-b37f-1f28de9257d9
md"Write some JavaScript glue to import our wasm module."

# ╔═╡ e10088c0-2b3c-47bc-bae9-4dff51ada111
@htl("""
	<script>
		const wasmModule = new WebAssembly.Module($(published_to_js(bin)));
		window.wasmInstance = new WebAssembly.Instance(wasmModule);
	</script>
""")

# ╔═╡ 69d67f14-8f4b-44fb-bcf0-4d8e7afe0cc2
let elem = gensym()
	@htl("""
		<script>
			const func = wasmInstance.exports['gcd'];

			let result = func(20n, 25n);

			let output = `<p>gcd(20, 25) = \${result}</p>`;

			document.getElementById('$elem').innerHTML = output;
		</script>
		<span id="$elem"></span>
	""")
end

# ╔═╡ 9133dfb7-4518-4922-b16f-5dd95f0d6888
let elem = gensym()
	@htl("""
		<script>
			const func = wasmInstance.exports['fibo'];

			let result;

			let output = "";

			for (let x = 0n; x < 10n; x += 1n) {
			 	result = func(x);
				output += `<p>F_\${x} = \${result}</p>`;
			}

			document.getElementById('$elem').innerHTML = output;
		</script>
		<span id="$elem"></span>
	""")
end

# ╔═╡ 74f3d8ec-cd0e-4850-8e91-efcb9ea6b175
let elem = gensym()
	@htl("""
		<script>
			const func = wasmInstance.exports['dist'];

			let result = func(1.0, 1.0);

			let output = `<p>\${result}</p>`;

			document.getElementById('$elem').innerHTML = output;
		</script>
		<span id="$elem"></span>
	""")
end

# ╔═╡ ef3d2e83-d331-4379-a53d-bfe3bfe59ca7
md"""
# Improvements

- Use more Wasm features to implement a bigger subset of Julia:
  - Loops!
  - Convertions between integers and floats
  - Linear memory for arrays or structs
  - Indirect calls and function tables for anonymous functions or methods

- Add another pass for optimizations?

- Use `LineNumberNode` for better error messages, just like the real Julia compiler.

"""

# ╔═╡ b3120fe8-ddeb-46e9-82ea-33a5ba91722e
md"""
# References
- Andy Wingo. [_Compiling To Web Assembly._](https://www.youtube.com/watch?v=0WpplI0dd7w) FOSDEM 2021.

- MDN Web Docs. [_Understanding WebAssembly text format._](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Understanding_the_text_format)

- W3C. [_WebAssembly Core Specification._](https://www.w3.org/TR/wasm-core-1/)

- The Julia Language Manual. [_Metaprogramming._](https://docs.julialang.org/en/v1/manual/metaprogramming/)
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractPlutoDingetjes = "6e696c72-6542-2067-7265-42206c756150"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
AbstractPlutoDingetjes = "~1.3.0"
HypertextLiteral = "~0.9.5"
PlutoUI = "~0.7.61"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.3"
manifest_format = "2.0"
project_hash = "3623ad0e4378dffccc8988d0e0a38f34e4800850"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

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

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

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

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "1833212fd6f580c20d4291da9c1b4e8a655b128e"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.0.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "7e71a55b87222942f0f9337be62e26b1f103d3e4"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.61"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

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

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

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
# ╟─33d906e5-23be-4eba-a682-4ddb776b9bad
# ╟─2b15644f-7898-4373-947f-719055d6ce48
# ╠═2a00780f-4322-455f-af3e-eba952abf64b
# ╠═d5d9447f-c0db-4810-89d7-0e4ce1566e86
# ╟─222c8445-0ca9-42e1-b26a-12953a3c910f
# ╠═4acb880b-60a0-42d6-bfea-26935426b30c
# ╟─a5a3c821-f111-4951-bf69-56b1bb70d4bb
# ╟─bee64a4a-0b1b-449d-bc9a-2844f4ff3b36
# ╟─49d328d5-a16d-4510-b07b-a9cc908c8310
# ╟─aeee5645-eead-40d5-af78-e8cdae89376b
# ╠═2163ebda-6741-4390-b79c-4d3fe6fc9b4b
# ╠═24534cd6-a102-4d5e-80c6-f75e158e4fbf
# ╟─3b824756-e098-452a-aeac-4b07088834c1
# ╠═1096a6cc-636d-486b-8ccd-5309ae231efa
# ╟─b68ac919-095d-40f8-9bd9-a3a5ee62c484
# ╟─0b71a7f1-86cc-4034-98ba-9aa1bb32c3cb
# ╠═b05e6426-2c26-455e-b18c-12676e25ba2b
# ╟─3a7d3660-8e3f-40f1-a08f-06cf1b5762d7
# ╠═f7ee1048-42e1-4c29-98ca-b0486cfad4ac
# ╠═1c653ada-e4fe-4531-b63c-80a2fa349383
# ╠═8c77097c-5179-49d9-90b9-1068ed57205b
# ╟─5e819f03-b27b-4190-9043-af88e031b9bd
# ╠═493a3465-d6ee-4dbd-8450-863a2a9e5ae1
# ╠═916914b0-861d-472e-ab21-6ec3f915986a
# ╟─91875dd9-ebc5-4463-8d8b-a5c19ae06b81
# ╠═22c17393-eca3-44cb-bde6-ef78d2e337a5
# ╠═2078ff46-b3d9-4e3b-a9a3-4c7115412584
# ╟─aa9787e9-ed71-4a23-becc-e959bb9b5047
# ╠═bdba6817-5fe4-4dd5-941b-d4c57535244e
# ╠═59edf6b6-498f-480f-8cca-4dfc0d54ad00
# ╟─799a5edc-86e2-4d04-aaef-be3d273ecf0e
# ╠═8815bd45-6159-4efd-bffc-654e8857cf59
# ╟─d2d39793-9862-4109-88bd-e4fab2a1196f
# ╠═90098ad7-5e9c-4e78-b310-4c83f039d448
# ╟─91d7dad5-ee47-4e56-8722-e471fcf42b5e
# ╠═b6233b2c-0916-4699-9d7a-8f61a8ad3dbc
# ╠═b1990a23-a756-41c8-b595-64c374062e6f
# ╟─e9e27ccf-693b-4911-84ff-f7d8c11e910d
# ╠═7968e313-e222-49f3-b3b4-958a33c85acf
# ╟─744ea5d8-98a7-42e0-9f8f-0f5ac43509e8
# ╠═46831b43-9d3a-4171-9db0-2410a610d889
# ╟─cc7854e7-8b01-4e34-9c70-2ac58d80d06d
# ╠═b6a962ea-29fe-4b84-892c-2cffd06fc776
# ╠═1410504f-af8c-498f-9966-7402d2d4abf3
# ╟─f3ecbf76-9fac-4c88-a8f8-cc90cb5ab798
# ╠═b69ab174-ceef-4c9d-ad85-522c914cf628
# ╟─2558d535-9611-4f52-b23c-fd2ba6c3dab0
# ╠═9b39f2b3-f304-4ca5-b978-138d581b6131
# ╠═73c32ba9-3558-4157-b578-eb4b39f3d9df
# ╟─8560e6c3-086c-4d43-ab44-c8373df867ab
# ╠═ae62d583-5d18-4638-8d15-1dc712251172
# ╠═80cf9e1a-0001-4326-8529-6b0a552a6983
# ╠═368cd41d-a4ab-4cc3-bc23-1e699acbddb4
# ╠═9ce27d00-622e-42ed-a226-99e0921f32ad
# ╟─8a44508f-5d71-4ac5-8859-2055274b8f9f
# ╠═0779191f-61c2-405a-804b-a09063599d92
# ╠═081eb9fc-4a0e-42fa-8e76-b4d8bbcc8bca
# ╠═e20fa141-bad9-4e8c-95f7-e22080b26386
# ╠═92344bda-acba-417c-8d32-1e2a6ed1341d
# ╟─ade2233f-5253-43da-a95f-84682d9299b4
# ╠═29c7ed38-3eca-4d59-aa83-4acfd25ffa26
# ╠═d0374658-917b-412a-a23a-c02f46c30403
# ╟─8fa0fc6a-fb9e-4737-9888-98571f322e97
# ╠═41c29c01-6af6-4b2d-bcc8-60e44a99ce34
# ╠═4834f3ed-eb2a-4ec3-9575-8fd3777d248e
# ╟─01a65ca7-8423-467f-ae1a-d61f6cc86391
# ╠═001f39f8-c254-48a3-acc2-d64a8344b5dd
# ╠═56220b2d-7ee4-4118-8f88-aef5d7478534
# ╠═eb287d52-7375-4226-bd2a-97f4c2a435bd
# ╟─35622d1b-0167-4e87-beca-9ae83476fe41
# ╠═8d7a8f03-5a48-439b-8012-1165ae470f3d
# ╠═348cec8f-2002-4972-ad32-932fe3ac4e15
# ╠═2d399f80-ec50-4b71-89a2-2e4e8ecf19e6
# ╠═c578e254-2171-4803-b03e-4f910ef655b8
# ╠═80379f3b-4c3a-46cd-b1a1-fc14f67052a0
# ╟─5accfa8f-0ef2-4960-8a4a-7f4a50798756
# ╠═fb7b2997-731c-4a92-b359-82f17b8db299
# ╠═8bc1257e-67f9-4234-a956-bf19b7dab1b7
# ╟─4cc4abf2-98a7-4d1c-b8b6-aec96ac04637
# ╠═7427d9fc-e910-4c97-a2ae-704180dd206e
# ╠═3eda0e11-488f-4b31-a5a0-6be2740e830d
# ╟─24c850c6-e9b9-47fb-8d40-34cafc0a5ac0
# ╠═635f057b-c0f9-4d34-82f6-87b92f7a909f
# ╠═85b863bc-8091-43b4-ab31-fc406b86b6ed
# ╠═3436fac4-a083-499d-a48c-4b95c431a797
# ╠═e6978e8b-b7f9-416b-b934-d425c01ab582
# ╟─55716561-84d0-4eab-b081-eea439411e7a
# ╠═e4a0cc0f-5f35-4289-9270-148e4be99c32
# ╟─277870c7-e4fb-4232-9170-3b69c3200121
# ╠═5aea4283-8366-4028-b2ad-0227e7b2d9c5
# ╠═3eaab51d-a4db-4779-a8e1-a93e54ecfa0b
# ╠═0e9b8f09-cdbd-48b6-a81b-5fc04e55ab56
# ╠═4dcd5268-6194-4628-a874-c569ac0daaf5
# ╟─378a2523-85eb-4273-89dd-108722793228
# ╟─bd00b805-32e7-4ea8-8305-e17a0331fd5b
# ╠═7c38261d-7cdb-4801-a2c5-259ea58282d6
# ╟─72cb168f-a908-496e-9e7e-02faad98e98f
# ╠═0f63e48e-6458-4ec9-9e6d-f437e0d33ada
# ╟─4cd8ff6c-4c73-4e45-88e1-f7c09ca81454
# ╠═5daede5f-5fc7-4533-8ee7-004074573c05
# ╠═cc71a919-3a1f-47a0-a3d5-02d812e0bdc0
# ╟─0aad810b-5f99-41dc-b1fe-dc3cef26cc70
# ╠═e1c68c54-c57f-444c-84d0-44419f3e280e
# ╠═83d4c742-7618-4a53-81c8-1db498559d01
# ╠═09224b80-0cde-4b46-868e-38d8ee891d3f
# ╟─caeab89c-5bf0-45af-b89c-1690c0d2d352
# ╠═c9cd462e-e7df-43dc-b2e6-10e78da8e725
# ╟─b398f64c-9464-4818-a545-abb352eb4f04
# ╠═ea7f10a3-9469-4207-a9ed-de244c56b73a
# ╠═b04ba764-f39b-4a7b-ad8b-b0f3a793645e
# ╠═7c805a4e-75ae-403c-a12f-f9aa1e27f441
# ╠═2ba9d8d3-247e-4ac3-82b4-e914076203a9
# ╟─938e7247-030a-4fe0-aa46-1ee50141a21a
# ╠═c5a9ca3c-08ae-4477-8ca6-6b6c2dfbcb29
# ╠═c9dd4aee-64dc-4fe7-8abb-de59bd7d6d9e
# ╠═06d20a34-7576-4691-8fb7-555eb68cfc89
# ╟─3e34769b-ac84-44cb-b8c7-86bb35344ae6
# ╠═589c8a1b-f246-476d-8e6e-b7e321829b1b
# ╟─37b6e4fb-f177-4acb-ac58-a3abc04c12da
# ╠═0f6d4436-c7ea-495f-957a-848613de460f
# ╠═5b015e2e-d1d0-46ef-97e7-9f57cc0ed654
# ╠═13b3d646-db95-4779-8766-167626827ec9
# ╟─ef86e977-6d6c-4954-82f8-54e79a64f995
# ╠═639fc9ea-f5f0-44e5-b2a5-2bb206e4a334
# ╟─d3671958-852b-49a8-b37f-1f28de9257d9
# ╠═e10088c0-2b3c-47bc-bae9-4dff51ada111
# ╠═69d67f14-8f4b-44fb-bcf0-4d8e7afe0cc2
# ╠═9133dfb7-4518-4922-b16f-5dd95f0d6888
# ╠═74f3d8ec-cd0e-4850-8e91-efcb9ea6b175
# ╟─ef3d2e83-d331-4379-a53d-bfe3bfe59ca7
# ╟─b3120fe8-ddeb-46e9-82ea-33a5ba91722e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
