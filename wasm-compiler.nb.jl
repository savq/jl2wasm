### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ fe569a9c-e7af-48a2-9d65-d86628a53833
begin
	using HypertextLiteral: @htl
	using AbstractPlutoDingetjes.Display: published_to_js;
end

# ╔═╡ 2310ed18-eecd-11ef-24f5-4da7ab1a78e5
md"""
# Compiling to WebAssembly

Sergio A. Vargas\
Universidad Nacional de Colombia\
YYYY-MM-DD

### Prerequisites

- Knowledge of Julia metaprogramming (see other notebook).
- Knowledge of recursive data types: lists, trees, etc.
- Knowledge of stack machines.


### Dependencies
"""

# ╔═╡ bff6407f-e555-4087-ab83-b7771f141d20
md"""
### External dependencies

- [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools)
"""

# ╔═╡ aeb429e4-fe6b-43a5-97ac-0fa5bc1082c2
# TODO: Add citation https://webassembly.org/
md"""
## ⚙️ WebAssembly

> WebAssembly (abbreviated Wasm) is a binary instruction format for a stack-based virtual machine. Wasm is designed as a portable compilation target for programming languages, enabling deployment on the web for client and server applications.

#### Why Wasm?
- Fast*
- Portable
- Hype?
"""

# ╔═╡ 1a8245e3-6a4b-4f3a-9e1f-79eb95e30d60
md"""!!! note "Digression: Stack machines" """ # Tablero

# ╔═╡ 1f02d138-f6d6-4289-baab-e7192824d59e
md"""
### WebAssembly Text Format (wat)

For simplicity, we'll use wat instead of writing wasm binary code directly.

wat uses an s-expression based syntax, but it's nothing like Lisp.
"""

# ╔═╡ ee2ffb80-694c-4139-b45c-15a7fb084e44
sample_wat_program = raw"""
;; Comments start with double semicolons

(module                                      ;; All wasm binaries are modules

  ;; Basic example:
  (func $add1 (param i32) (result i32)       ;; Function definition
    (local.get 0)                            ;; Push the 0th parameter
    (i32.const 1)                            ;; Push a 1 (integer of 32 bits)
    (i32.add)
    (return))

  ;; Syntax sugar example:
  (func $add2 (param $x i32) (result i32)    ;; Named parameters
    (i32.add (local.get $x) (i32.const 2)))  ;; Folded instructions

  (func (export "main") (result i32)         ;; Exported name (callable from JS)
    (i32.const 39)
    (call $add1)
    (call $add2))
)
""";

# ╔═╡ 94a1733b-ee20-4cbe-b9e4-0a78d586a1dc
md"""
We'll use named parameters, but not folded instructions.

Also note:

- Structured control flow instead of `goto`
- Static type system
"""

# TODO: Mention local variables

# ╔═╡ 80ae73c3-7a4d-4d9c-a61b-4c466a26d618
md"""
### Running Wasm

1. Call `wasm-tools` to convert our `wat` code to the wasm binary format.
2. Pass the binary to JavaScript
3. ???
4. PROFIT!
"""

# ╔═╡ 9bd601f8-e187-41b4-994f-a6919f6761f1
assemble(wat) = read(pipeline(IOBuffer(wat), `wasm-tools parse`));

# ╔═╡ 12efccbe-66c2-4a44-81f7-839484b62a13
sample_wasm = assemble(sample_wat_program)

# ╔═╡ 5e3b3b5d-b527-4792-8ad4-c066d72b5ae3
@htl("""
<script>
	const wasmCode = $(published_to_js(sample_wasm));
	const wasmModule = new WebAssembly.Module(wasmCode);
	const wasmInstance = new WebAssembly.Instance(wasmModule);

	const main = wasmInstance.exports.main;
	document.getElementById("output1").innerHTML = main().toString();
</script>
<p>
	The output of function <code>main</code> is:
	<span id="output1">?</span>
</p>
""")

# ╔═╡ 14f940db-1a5e-4aac-8e59-e24121074ec4
md"""
## 🐉 Compiling to WebAssembly

Define a subset of Julia:

- Modules
  - only one symbol per `export`
- Functions
  - Signatures must be fully annotated
  - No mutually recursive functions
  - No short function definitions
- Integers and floats
- Arithmetic
- Comparisons # TODO
- Conditionals # TODO

This mini-Julia is still Turing-complete because we have recursion in Wasm, but in practice we'll only be able to write very basic numerical algorithms.

#### Problems

- Name resolution?
- Type checking?
"""

# ╔═╡ bfb29b63-21b5-4963-ba63-bc472ef4c209
src = :(
	module _
		export main

		function sign(n::Float64)::Float64
			if n == 0.0
				0.0
			elseif n < 0.0
				-1.0
			else
				1.0
			end
		end

		function addsign(n::Float64)::Float64
			return n + sign(n)
		end

		function main()::Float64
			x::Float64 = -7.5
			return addsign(x)
		end
	end
);

# ╔═╡ c62cf6eb-dd4d-43b7-b8fa-e5f7fa767e57
@info raw"""
;; Expected output:
(module
  (export "main" (func $main))
  (func $sign (param $n f64) (result f64)
        (local.get $n)
        (f64.const 0.0)
        f64.eq
        if (result f64)
            (f64.const 0.0)
        else
            (local.get $n)
            (f64.const 0.0)
            f64.lt
            if (result f64)
                (f64.const -1.0)
            else
                (f64.const 1.0)
            end
        end)

  (func $addsign (param $n f64) (result f64)
        (local.get $n)
        (local.get $n)
        (call $sign)
        f64.add
        return)

  (func $main (result f64) (local $x f64)
        (f64.const -7.5)
        (local.set $x)
        (local.get $x)
        (call $addsign)
        return))
""";

# ╔═╡ d49be5c4-430c-4aaa-83ea-06b65135756f
md"""
### Compilation strategy
- Dispatch based on the `head` of `Expr`
- Create a list of lists, then write it as an s-expression
- When in doubt, stick the computation in a function and deal with it later
- Assume code is typed correctly (see below)


First, we need an entry point for our compiler, and some helper functions for the kinds of expressions we don't know how to compile:
"""

# ╔═╡ 6c69348f-d845-40ca-80d8-c9b80aa2c6e3
function compile(expr_kind, args; env)
	@warn("$expr_kind is not implemented.")
	return [expr_kind, compile.(args; env)...]
end;

# ╔═╡ 38184d17-d192-45ba-bc11-3a4af3f99992
function compile(token; env)
	@debug("$(typeof(token)) is not implemented.")
	return token
end;

# ╔═╡ 45d5970b-bc46-483a-bd86-d098163c8dc6
md"Now, we can run `compile` and see what we need to implement:"

# ╔═╡ 0d5e29cd-ef82-4e3b-9795-0823cdb8dea2
md"""#### Expressions"""

# ╔═╡ a92481b2-8585-4a72-964a-bb28caff3ce0
function compile(::Val{:block}, args; env)
	return (compile.(args; env)...,)
end;

# ╔═╡ b06939e9-0438-4e24-b35a-f18b77fbfc6d
function compile(::Val{:module}, args; env)
	body = args[3]
	return [:module, compile.(body.args; env)...]
end;

# ╔═╡ 69c1a4f3-e550-42e5-b3c0-962307309386
compile_signature(sig; env) = compile_signature(Val(sig.head), sig.args; env);

# ╔═╡ 4392fdc4-7744-461c-990e-654e470c9cb8
compile(::Val{:return}, args; env) = (compile(args[1]; env), :return);

# ╔═╡ c8a52a23-6b1c-4305-873d-a23e40f3ddc6
function compile(::Val{:if}, args; env)
	result_type = args[1]             # NOTE: We injected type info when type checking
	condition = compile(args[2]; env)
	consequent = compile(args[3]; env)
	alternative = length(args) >= 4 ? compile(args[4]; env) : ()
	return (
		condition,
		:if,
		result_type,
		consequent,
		:else,
		alternative,
		:end
	)
end;

# ╔═╡ 103dde9b-9cc0-4bc1-97d4-bd7e48c254b3
## Ignore
compile(::LineNumberNode; env) = nothing;

# ╔═╡ 4721d683-ba9a-43e5-b50a-851c40fcb819
md"""
#### Identifiers

We need to distinguish identifiers from instructions. Can't use `Symbol` for both.
"""

# ╔═╡ 187a29db-effe-4685-8d27-4ea28332164e
struct WasmId
	id::Symbol
end

# ╔═╡ ff119986-b435-43a5-8c99-af4773521f24
function compile(::Val{:export}, args; env)
	if length(args) > 1
		error("Only one symbol per export")
	end
	name = args[1]
	function()
		[:export, String(name), [env.types[name], WasmId(name)]]    # type of export?
	end
end;

# ╔═╡ 0451dc0f-a25a-4fe5-a237-6ee69b70de40
compile(id::Symbol; env) = [Symbol("local.get"), WasmId(id)];

# ╔═╡ 0bb22905-13cb-475c-a22e-997f2d8c2e29
md"""#### Numbers"""

# ╔═╡ 29fac0f3-b3df-4d7a-86ad-711739aaf941
WasmValtype = Union{Int32, Int64, Float32, Float64};

# ╔═╡ 5fa49ebd-7561-4ef3-800a-9a1e3b5d1db7
## FIXME: This might fail for large unsigned values
compile(n::N; env) where {N <: Integer} = compile(convert(Int32, n); env);

# ╔═╡ b494d7cd-4047-4d8e-aacf-2941a0985684
compile_type(t::DataType) = compile_type(Symbol(t));

# ╔═╡ fb19f261-0a38-4991-96d9-04dc4fab220e
function compile_type(t::Symbol)
	value_types = (
		Bool = :i32,
		Int = :i32,
		Int32 = :i32,
		Int64 = :i64,
		Float32 = :f32,
		Float64 = :f64,
	)
	return value_types[t]
end;

# ╔═╡ af62e62b-f431-4633-9aef-08554ab7d3d0
function compile_signature(::Val{:call}, args; env) # Signature without return type
	(fname, jl_params...) = args
	env.types[fname] = :func                  # Update environment
	params = map(jl_params) do pt
		(p, t) = pt.args                      # p::t
		[:param, WasmId(p), compile_type(t)]  # (param $p t)
	end
	return (WasmId(fname), params...)
end;

# ╔═╡ 1706efe8-7eb0-4142-996d-5ab16abb1f2d
function compile_signature(::Val{:(::)}, args; env) # Signature with return type
	(c, return_type) = args
	return (
		compile_signature(c; env)...,
		[:result, compile_type(return_type)]
	)
end;

# ╔═╡ 2b9a44e5-512f-479a-8119-5ce83c4b0dd3
function compile(::Val{:(=)}, args; env)
	(lhs, rhs) = args
	if lhs isa Symbol                           # Regular assignment
		name = lhs
	elseif lhs isa Expr && lhs.head == :(::)    # Typed declaration
		(name, t) = lhs.args
		env.types[name] = compile_type(t)
	end
	push!(env.vars, name)                       # Update environment
	return (
		compile(rhs; env),
		[Symbol("local.set"), WasmId(name)]
	)
end;

# ╔═╡ 30a23149-7b1a-4b4a-8e7e-8e86f1ba28e8
compile(n::WasmValtype; env) = [Symbol("$(compile_type(typeof(n))).const"), n];

# ╔═╡ c6645ecb-fd0b-423e-999c-b6e5558dd501
md"""
### Resolving identifiers

We need to declare local variables before using them, and list imports before defining functions (which is basically the same problem).

Use the information collected in the environment to "fill in the blanks".

In a proper compiler, we'd do this in a separate phase _before_ code-gen.
"""

# ╔═╡ b60c12f9-aea0-4bc0-9e52-da975864df36
begin
	struct Env
		vars::Set{Symbol}
		types::Dict
	end
	Env() = Env(Set(), Dict())
	Env(super_env::Env) = Env(Set(), copy(super_env.types))
end

# ╔═╡ e675bae3-c4c2-458e-96e0-072bb0b13bc5
function compile(expr::Expr; env=Env())    # Ignore `env`, we'll talk about it later
	kind = Val(expr.head)                  # Dispatch on head
	return compile(kind, expr.args; env)
end

# ╔═╡ 32b1cbda-aa48-46b4-a6fe-b9e45b4d5f95
function get_locals(env)
	locals = tuple(env.vars...)
	map(locals) do l
		[:local, WasmId(l), get(env.types, l, :i32)] # FIXME
	end
end;

# ╔═╡ 807100e6-557a-4377-acdd-4724caa9249a
function compile(::Val{:function}, args; env)
	(sig, body) = args
	fenv = Env()                        # Inner environment for local variables
	return [
		:func,
		compile_signature(sig; env)...,
		function()
			get_locals(fenv)            # Declare locals at the start of the function
		end,
		compile.(body.args; env=fenv)...,
	]
end;

# ╔═╡ ee2d36a7-7f3d-4637-8eb8-515c1cdb4dd8
resolve(ir_program::Vector) = resolve.(ir_program);

# ╔═╡ 4bb71680-4be7-4ad1-a68f-3c2e9a58a294
resolve(f::F) where {F<:Function} = f();

# ╔═╡ 7265c0b1-da34-4343-8457-3be560d4cc62
resolve(x) = x;

# ╔═╡ 24b382c1-e720-401f-be4e-185eb77c4179
md"Note that `resolve` itself doesn't take `env` as argument."

# ╔═╡ 3cdd8bfa-7eb8-459e-84dc-20be08f4232a
md"""
### Type checking (skip)

- This section was written after the code-gen part, so there's a lot of duplication and hacks.
- Not that interesting. Same idea of traversing the tree.
- The main reason we want this is for polymorphic operators (see `NumericOp` below).
"""

# ╔═╡ 244551c8-9a01-47e1-8dd2-667a3abb5aad
function type_check end

# ╔═╡ 81781a60-50d9-4b73-883a-e1e5947a565e
begin
	type_check(expr::Expr; env=Env()) = type_check(Val(expr.head), expr.args; env)
	type_check(::Val{:block}, args; env) = type_check.(args; env)[end]
	type_check(::Val{:module}, args; env) = type_check(args[3]; env)
	type_check(::Val{:export}, _a; env) = nothing
	type_check(::Val{:return}, args; env) = type_check(args[1]; env)
	type_check(id::Symbol; env) = env.types[id]
	type_check(n::N; env) where {N <: WasmValtype} = Symbol(N)
	type_check(n::N; env) where {N <: Integer} = Symbol(promote_type(Int32, N))
	type_check(::LineNumberNode; env) = nothing
end

# ╔═╡ 0fe8eba8-4ccb-4665-ac4a-d5498d25b178
function type_check_signature(sig; fenv)
	if sig.head == :(::)
		(fname, param_types, _) = type_check_signature(sig.args[1]; fenv)
		return_type = sig.args[2]
	elseif sig.head == :call
		fname = sig.args[1]
		param_types = map(sig.args[2:end]) do pt
			(p, t) = pt.args
			fenv.types[p] = t
		end
		return_type = Nothing
	end
	fenv.types[fname] = (param_types, return_type) # For recursion
	return (fname, param_types, return_type)
end;

# ╔═╡ e68c3170-d091-47eb-b478-a57294a6904c
function type_check(::Val{:function}, args; env)
	(sig, body) = args
	fenv = Env(env)
	(fname, _, return_type) = type_check_signature(sig; fenv)
	env.types[fname] = fenv.types[fname]
	body_types = type_check.(body.args; env=fenv)
	last_type = body_types[end]
	if last_type != return_type
		error("Type of last expression $last_type doesn't match return type $return_type")
	end
end;

# ╔═╡ e7b3c3d6-d10c-4df1-bdee-41586c76498e
function type_check(::Val{:(=)}, args; env)
	(lhs, rhs) = args
	right_type = type_check(rhs; env)

	if lhs isa Expr && lhs.head == :(::)
		(name, left_type) = lhs.args
		if left_type == right_type
			env.types[name] = left_type
		else
			error("Incompatible types: $left_type and $right_type")
		end
	elseif lhs isa Symbol
		right_t = type_check(rhs; env)
		env.types[lhs] = Symbol(right_t)
	end
end;

# ╔═╡ ad7e86f7-fb75-4ce4-9f18-0d2532be337e
function type_check(::Val{:if}, args; env)
	condition = args[1]
	consequent = args[2]

	type_check(condition; env) # TODO: Check Bool

	if length(args) >= 3
		alternative = args[3]

		if alternative.head == :elseif # FIXME
			alternative.head = :if
		end

		left_type = type_check(consequent; env)
		right_type = type_check(alternative; env)
		if left_type == right_type
			t = left_type
		else
			error("Incompatible types: $left_type and $right_type")
		end
	else
		t = type_check(consequent; env)
	end

	# Horrible hack to handle typed `if`
	pushfirst!(args, [:result, compile_type(t)])

	return t
end;

# ╔═╡ 74c4bde6-3225-49bc-9be0-f162fedb885e
md"""
### Concrete numeric instructions (skip)
"""

# ╔═╡ 456ad27a-d0a4-496e-945b-81d879400244
abstract type NumericOp end

# ╔═╡ 08ff7d44-2d5c-46f1-b999-7dbfe2e1c167
function compile(::Val{:call}, args; env)
	(f, arguments...) = args
	return (
		compile.(arguments; env)...,
		f isa NumericOp ? f : [:call, WasmId(f)]    # operators are functions!
	)
end;

# ╔═╡ 6d42458e-ae45-483f-9ce6-a6c17bc2b702
compile(src)

# ╔═╡ b0224516-ce68-46f9-b4a0-e2c5f611f608
## Example
compile(false; env=Env())

# ╔═╡ 2b0b2c57-9f2e-494e-b368-e5d9cb4b22e6
## Example
let Γ = Env(Set(), Dict(:foo => :func, :bar => :func))
	expr = :(module _
		export foo
		export bar
	end)
	ir = compile(expr; env=Γ)
	resolve(ir)
end

# ╔═╡ e1dda7f8-43ef-4217-b55d-facecaf7d496
struct BinaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ 441ad797-20fe-41fc-94aa-910f46da723f
struct UnaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ e811e550-5d41-439a-b8a9-d3ec618cb5e7
function Base.show(io::IO, cop::NumericOp)
	# Note: Use subscript `p` because Unicode doesn't have subscript `f`
	subscripts = (
		Int32 = "ᵢ₃₂",
		Int64 = "ᵢ₆₄",
		Float32 = "ₚ₃₂",
		Float64 = "ₚ₆₄",
	)
	write(io, "$(cop.op)$(subscripts[cop.t])")
	return
end

# ╔═╡ d3314156-dd45-4a36-8999-588a25be2f93
md"""### Writing wat"""

# ╔═╡ b61d5b5a-bebc-4dab-a34b-367a14352b27
# FIXME
binary_ops = (
	+ = :add,
	* = :mul,
	- = :sub,
	/ = :div, # only for floats!
	== = :eq,
	!= = :ne,
	< = :lt, # f
	> = :ge, # f
);

# ╔═╡ ced6d559-5da3-48ff-935a-a25dc87690e0
unary_ops = (
	- = :neg,
	√ = :sqrt,
);

# ╔═╡ 3ae65c37-587f-4f43-afd0-435e81b33769
function type_check(::Val{:call}, args; env)
	fname = args[1]
	if fname in keys(binary_ops) && length(args) == 3
		# Check types match
		(left_type, right_type) = type_check.(args[2:3]; env)
		if left_type == right_type
			# Replace generic function with concrete instance
			args[1] = BinaryOp(fname, left_type)
			return left_type
		else
			error("Incompatible types: $left_type and $right_type")
		end
	elseif fname in keys(unary_ops) && length(args) == 2
		t = type_check(args[2]; env)
		args[1] = UnaryOp(fname, t)
		return t
	else
		# Check arguments against signature
		(param_types, return_type) = env.types[fname]
		argument_types = type_check.(args[2:end]; env)
		if !all(param_types .== argument_types)
			error("Incompatible types: $param_types and $argument_types")
		end
		return return_type
	end
end;

# ╔═╡ fe5c4da8-514a-45e3-9190-820943c8492a
begin
	sexpr(xs::Vector) = "(" * join(sexpr.(xs), " ") * ")"
	sexpr(xs::Tuple) = join(sexpr.(xs), "\n ")
	sexpr((; id)::WasmId) = "\$$id"
	sexpr(num_op::BinaryOp) = "$(compile_type(num_op.t)).$(binary_ops[num_op.op])"
	sexpr(num_op::UnaryOp) = "$(compile_type(num_op.t)).$(unary_ops[num_op.op])"
	sexpr(str::String) = "\"$str\""
	sexpr(::Nothing) = "\n"
	sexpr(literal) = string(literal)
end

# ╔═╡ 8a0a43da-548c-4d1e-911f-3c99ed85adc0
md"### Putting it all together"

# ╔═╡ fbc06018-434e-4be0-b91e-ae63e300f3c2
function compile_to_wat(expr)
	type_check(expr)
	ir = compile(expr)
	rir = resolve(ir)
	wat = sexpr(rir)
	return wat
end

# ╔═╡ f6b6507c-3093-488c-a736-642a34a8ce32
macro wasm(expr)
	wat = compile_to_wat(expr)
	return :(assemble($wat))
end

# ╔═╡ d90bab84-a196-425c-ad06-12134332efc0
program = @wasm module _
	export main

	# ...

	function main()::Int32
		if false
			0x1
		elseif true
			0x2
		else
			0x3
		end
	end
end

# ╔═╡ af107520-4c06-4f22-8542-5404bc005e74
@htl("""
<script>
	const wasmCode = $(published_to_js(program));
	const wasmModule = new WebAssembly.Module(wasmCode);
	const wasmInstance = new WebAssembly.Instance(wasmModule);

	const main = wasmInstance.exports.main;
	document.getElementById("output2").innerHTML = main().toString();
</script>
<p>
	The output of function <code>main</code> is:
	<span id="output2">?</span>
</p>
""")

# ╔═╡ bab62fb9-b816-4403-ba87-d2493e3a4ffa
md"""
## TO DO

This compiler could be improved in an infinite number of ways, including:

- **Type checking:**
  - Written after the code-gen part, so there's a lot of unnecessary duplication.

- **Error handling:**
  - Didn't pay any attention to `LineNumberNode`, but we could've used that for better error messages, just like the real Julia compiler.
  - Could've created our own `Exception` subtype

- **Compilation:**
  - Use [MacroTools.jl](https://github.com/FluxML/MacroTools.jl) to normalise expressions
"""

# ╔═╡ ee2c3d4f-8fe8-4cb8-a6e5-f303ed3f7529
md"""
## References
- Wingo, A. [Compiling to WebAssembly.](https://www.youtube.com/watch?v=0WpplI0dd7w) FOSDEM 2021. ([source](https://github.com/wingo/compiling-to-webassembly))
- [WebAssembly Core Specification](https://www.w3.org/TR/wasm-core-1/). W3C recommendation
- [Understanding the WebAssembly text format](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format). MDN web docs
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
# ╟─2310ed18-eecd-11ef-24f5-4da7ab1a78e5
# ╠═fe569a9c-e7af-48a2-9d65-d86628a53833
# ╠═bff6407f-e555-4087-ab83-b7771f141d20
# ╟─aeb429e4-fe6b-43a5-97ac-0fa5bc1082c2
# ╟─1a8245e3-6a4b-4f3a-9e1f-79eb95e30d60
# ╟─1f02d138-f6d6-4289-baab-e7192824d59e
# ╠═ee2ffb80-694c-4139-b45c-15a7fb084e44
# ╟─94a1733b-ee20-4cbe-b9e4-0a78d586a1dc
# ╠═80ae73c3-7a4d-4d9c-a61b-4c466a26d618
# ╠═9bd601f8-e187-41b4-994f-a6919f6761f1
# ╠═12efccbe-66c2-4a44-81f7-839484b62a13
# ╟─5e3b3b5d-b527-4792-8ad4-c066d72b5ae3
# ╟─14f940db-1a5e-4aac-8e59-e24121074ec4
# ╠═bfb29b63-21b5-4963-ba63-bc472ef4c209
# ╟─c62cf6eb-dd4d-43b7-b8fa-e5f7fa767e57
# ╟─d49be5c4-430c-4aaa-83ea-06b65135756f
# ╠═e675bae3-c4c2-458e-96e0-072bb0b13bc5
# ╠═6c69348f-d845-40ca-80d8-c9b80aa2c6e3
# ╠═38184d17-d192-45ba-bc11-3a4af3f99992
# ╟─45d5970b-bc46-483a-bd86-d098163c8dc6
# ╠═6d42458e-ae45-483f-9ce6-a6c17bc2b702
# ╟─0d5e29cd-ef82-4e3b-9795-0823cdb8dea2
# ╠═a92481b2-8585-4a72-964a-bb28caff3ce0
# ╠═b06939e9-0438-4e24-b35a-f18b77fbfc6d
# ╠═ff119986-b435-43a5-8c99-af4773521f24
# ╠═807100e6-557a-4377-acdd-4724caa9249a
# ╠═69c1a4f3-e550-42e5-b3c0-962307309386
# ╠═af62e62b-f431-4633-9aef-08554ab7d3d0
# ╠═1706efe8-7eb0-4142-996d-5ab16abb1f2d
# ╠═2b9a44e5-512f-479a-8119-5ce83c4b0dd3
# ╠═08ff7d44-2d5c-46f1-b999-7dbfe2e1c167
# ╠═4392fdc4-7744-461c-990e-654e470c9cb8
# ╠═c8a52a23-6b1c-4305-873d-a23e40f3ddc6
# ╠═103dde9b-9cc0-4bc1-97d4-bd7e48c254b3
# ╟─4721d683-ba9a-43e5-b50a-851c40fcb819
# ╠═187a29db-effe-4685-8d27-4ea28332164e
# ╠═0451dc0f-a25a-4fe5-a237-6ee69b70de40
# ╟─0bb22905-13cb-475c-a22e-997f2d8c2e29
# ╠═29fac0f3-b3df-4d7a-86ad-711739aaf941
# ╠═30a23149-7b1a-4b4a-8e7e-8e86f1ba28e8
# ╠═5fa49ebd-7561-4ef3-800a-9a1e3b5d1db7
# ╠═b494d7cd-4047-4d8e-aacf-2941a0985684
# ╠═fb19f261-0a38-4991-96d9-04dc4fab220e
# ╠═b0224516-ce68-46f9-b4a0-e2c5f611f608
# ╟─c6645ecb-fd0b-423e-999c-b6e5558dd501
# ╠═b60c12f9-aea0-4bc0-9e52-da975864df36
# ╠═32b1cbda-aa48-46b4-a6fe-b9e45b4d5f95
# ╠═ee2d36a7-7f3d-4637-8eb8-515c1cdb4dd8
# ╠═4bb71680-4be7-4ad1-a68f-3c2e9a58a294
# ╠═7265c0b1-da34-4343-8457-3be560d4cc62
# ╟─24b382c1-e720-401f-be4e-185eb77c4179
# ╠═2b0b2c57-9f2e-494e-b368-e5d9cb4b22e6
# ╟─3cdd8bfa-7eb8-459e-84dc-20be08f4232a
# ╠═244551c8-9a01-47e1-8dd2-667a3abb5aad
# ╠═81781a60-50d9-4b73-883a-e1e5947a565e
# ╠═e68c3170-d091-47eb-b478-a57294a6904c
# ╠═3ae65c37-587f-4f43-afd0-435e81b33769
# ╠═0fe8eba8-4ccb-4665-ac4a-d5498d25b178
# ╠═e7b3c3d6-d10c-4df1-bdee-41586c76498e
# ╠═ad7e86f7-fb75-4ce4-9f18-0d2532be337e
# ╟─74c4bde6-3225-49bc-9be0-f162fedb885e
# ╠═456ad27a-d0a4-496e-945b-81d879400244
# ╠═e1dda7f8-43ef-4217-b55d-facecaf7d496
# ╠═441ad797-20fe-41fc-94aa-910f46da723f
# ╠═e811e550-5d41-439a-b8a9-d3ec618cb5e7
# ╟─d3314156-dd45-4a36-8999-588a25be2f93
# ╠═b61d5b5a-bebc-4dab-a34b-367a14352b27
# ╠═ced6d559-5da3-48ff-935a-a25dc87690e0
# ╠═fe5c4da8-514a-45e3-9190-820943c8492a
# ╟─8a0a43da-548c-4d1e-911f-3c99ed85adc0
# ╠═fbc06018-434e-4be0-b91e-ae63e300f3c2
# ╠═f6b6507c-3093-488c-a736-642a34a8ce32
# ╠═d90bab84-a196-425c-ad06-12134332efc0
# ╟─af107520-4c06-4f22-8542-5404bc005e74
# ╟─bab62fb9-b816-4403-ba87-d2493e3a4ffa
# ╟─ee2c3d4f-8fe8-4cb8-a6e5-f303ed3f7529
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
