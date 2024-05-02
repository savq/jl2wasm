### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ a2853ccc-97ff-4726-b937-e2f9c1196e5b
using HypertextLiteral: @htl

# ╔═╡ 556d124c-43e2-4a43-9143-6bb02364baa2
using AbstractPlutoDingetjes.Display: published_to_js

# ╔═╡ 7d3d0f58-efd0-11ee-1988-157fbf03d5d6
md"""
# Metaprogramming & Compiling to WebAssembly

Sergio A. Vargas\
Universidad Nacional de Colombia\
2024-04-05

### Prerequisites

- Knowledge of recursive data structures: lists, trees
- Good to know: s-exprs, stack machines

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

# ╔═╡ 04f08045-bcda-4ac4-82e1-c438e4766907
md"""
Figure 1. The life of the program, the job of the compiler
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

# ╔═╡ bdf3f885-7735-49b7-a440-81160e4b7087
md"""
## ⚙️ WebAssembly

> WebAssembly (abbreviated Wasm) is a binary instruction format for a stack-based virtual machine. Wasm is designed as a portable compilation target for programming languages, enabling deployment on the web for client and server applications.

#### Why Wasm?
- Fast*
- Portable
- Hype?
"""

# ╔═╡ 3088c1a3-a8ff-48c1-a211-2904a625be6d
md"""!!! note "Digression: Stack machines" """ # Tablero

# ╔═╡ cacbf954-38a1-46ae-a03f-b23b14282ac4
md"""
### WebAssembly text format (wat)

For simplicity, we'll use wat instead of writing binary directly.

wat uses an s-expression based syntax, but it's nothing like Lisp.
"""

# ╔═╡ 062604a9-b053-42ad-8041-4f5d0d23dba5
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

# ╔═╡ 3762cc84-3ccd-4d4f-9459-357d851c42a6
md"""
We'll use named parameters, but not folded instructions.

Also note:

- Structured control flow instead of `goto`
- Static type system
"""

# TODO: Mention local variables

# ╔═╡ c31b07c1-4ddf-4a65-b182-631d90494ba3
md"""
### Running Wasm

1. Call [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools) to convert our `wat` code to the wasm binary format.
2. Pass the binary to JavaScript
3. ???
4. PROFIT
"""

# ╔═╡ b743ce85-06ea-41f7-becb-37c42266809b
assemble(wat) = read(pipeline(IOBuffer(wat), `wasm-tools parse`));

# ╔═╡ 8225601a-c091-40d4-93bd-829ce5c001fd
sample_wasm = assemble(sample_wat_program)

# ╔═╡ 062bc743-9784-41e0-b7ae-017c8d821ecb
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

# ╔═╡ 141cae9d-8d3e-4006-8a34-169d7d512891
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

# ╔═╡ 6b1dec74-b4c7-44e5-9cf0-f8d47aa828b9
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

# ╔═╡ 40025535-5866-47e6-8885-ba0b5b896eb5
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

# ╔═╡ 39ff7a57-74cc-491e-9d5d-2dd7e7283a8e
md"""
### Compilation strategy
- Dispatch based on the `head` of `Expr`
- Create a list of lists, then write it as an s-expression
- When in doubt, stick the computation in a function and deal with it later
- Assume code is typed correctly (see below)


First, we need an entry point for our compiler, and some helper functions for the kinds of expressions we don't know how to compile:
"""

# ╔═╡ b674d672-790b-4ab6-a631-d7ecb79de9ce
function compile(expr_kind, args; env)
	@warn("$expr_kind is not implemented.")
	return [expr_kind, compile.(args; env)...]
end;

# ╔═╡ db056c9f-421f-4544-adff-ca322285c473
function compile(token; env)
	@debug("$(typeof(token)) is not implemented.")
	return token
end;

# ╔═╡ 83a91b7b-a4b2-492e-b6e1-03dd98251451
md"Now, we can run `compile` and see what we need to implement:"

# ╔═╡ 5e6da7d9-eb09-494e-b154-8f06bc43aa4f
md"""#### Expressions"""

# ╔═╡ 9eacab37-e42d-438e-86ba-c19c783f5d51
function compile(::Val{:block}, args; env)
	return (compile.(args; env)...,)
end;

# ╔═╡ be8c3c92-21e2-4087-8794-64b2e50c3073
function compile(::Val{:module}, args; env)
	body = args[3]
	return [:module, compile.(body.args; env)...]
end;

# ╔═╡ 55cdd2e5-b3ff-463f-aa7a-cb6c86a877df
compile_signature(sig; env) = compile_signature(Val(sig.head), sig.args; env);

# ╔═╡ 1d6adaeb-44c0-4965-8470-1fe04c5c8d45
compile(::Val{:return}, args; env) = (compile(args[1]; env), :return);

# ╔═╡ 5b11f30a-ad11-4548-93bb-8dfa41304d0c
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

# ╔═╡ b6d9e7c8-4a12-43e8-9fda-64fca44fc2c3
## Ignore
compile(::LineNumberNode; env) = nothing;

# ╔═╡ 043e284d-36b3-4fbe-b3fa-5ad315858545
md"""
#### Identifiers

We need to distinguish identifiers from instructions. Can't use `Symbol` for both.
"""

# ╔═╡ d35e9e2a-8d2b-48dd-b3cb-837f7edcabfb
struct WasmId
	id::Symbol
end

# ╔═╡ 92adb2eb-5e4f-464a-a049-7ccbe7429ebb
function compile(::Val{:export}, args; env)
	if length(args) > 1
		error("Only one symbol per export")
	end
	name = args[1]
	function()
		[:export, String(name), [env.types[name], WasmId(name)]]    # type of export?
	end
end;

# ╔═╡ 92d3e5cd-df38-4a03-bd8d-4dd6d4ad6408
compile(id::Symbol; env) = [Symbol("local.get"), WasmId(id)];

# ╔═╡ 0b473545-7ed1-41ee-a709-f2ecb1d7dca0
md"""#### Numbers"""

# ╔═╡ c4e64b48-81a4-4ee8-8b50-74f805e0a07c
WasmValtype = Union{Int32, Int64, Float32, Float64};

# ╔═╡ 4214237d-88e1-4d04-a79b-11e431958140
## FIXME: This might fail for large unsigned values
compile(n::N; env) where {N <: Integer} = compile(convert(Int32, n); env);

# ╔═╡ 7ae4968d-6f13-4f7b-8972-3279e7b53a40
compile_type(t::DataType) = compile_type(Symbol(t));

# ╔═╡ 70ddc4b5-913a-4353-b82b-e88d0aeed47a
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

# ╔═╡ 3633227a-a4af-4a47-bb3f-2cdd994a9f4c
function compile_signature(::Val{:call}, args; env) # Signature without return type
	(fname, jl_params...) = args
	env.types[fname] = :func                  # Update environment
	params = map(jl_params) do pt
		(p, t) = pt.args                      # p::t
		[:param, WasmId(p), compile_type(t)]  # (param $p t)
	end
	return (WasmId(fname), params...)
end;

# ╔═╡ 8f5fa10b-12a6-422f-a7aa-27a4adeba52e
function compile_signature(::Val{:(::)}, args; env) # Signature with return type
	(c, return_type) = args
	return (
		compile_signature(c; env)...,
		[:result, compile_type(return_type)]
	)
end;

# ╔═╡ 33c17ceb-30fa-4efe-8d3b-7e997eb03051
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

# ╔═╡ a5c3e5f2-449d-40dd-bd9a-3de1d7c10333
compile(n::WasmValtype; env) = [Symbol("$(compile_type(typeof(n))).const"), n];

# ╔═╡ 0b0b16eb-453b-48fd-a021-eeb523f4de46
md"""
### Resolving identifiers

We need to declare local variables before using them, and list imports before defining functions (which is basically the same problem).

Use the information collected in the environment to "fill in the blanks".

In a proper compiler, we'd do this in a separate phase _before_ code-gen.
"""

# ╔═╡ ee7ad653-3aa2-43ae-b33b-6bc1d271034c
begin
	struct Env
		vars::Set{Symbol}
		types::Dict
	end
	Env() = Env(Set(), Dict())
	Env(super_env::Env) = Env(Set(), copy(super_env.types))
end

# ╔═╡ 35d36acf-bf53-4b86-8198-8d04d79293ba
function compile(expr::Expr; env=Env())    # Ignore `env`, we'll talk about it later
	kind = Val(expr.head)                  # Dispatch on head
	return compile(kind, expr.args; env)
end

# ╔═╡ a947381a-474b-41e6-9ae5-a040c031ba55
function get_locals(env)
	locals = tuple(env.vars...)
	map(locals) do l
		[:local, WasmId(l), get(env.types, l, :i32)] # FIXME
	end
end;

# ╔═╡ a7bb0e43-16ac-430e-9a19-8931a542dd28
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

# ╔═╡ a4f44e51-ed7f-41cd-8355-36e6dee81bda
resolve(ir_program::Vector) = resolve.(ir_program);

# ╔═╡ a5b3d387-1a4d-4380-b530-57a97a591dc1
resolve(f::F) where {F<:Function} = f();

# ╔═╡ d91a1d83-8482-42ef-83df-f441f7319bc7
resolve(x) = x;

# ╔═╡ 16f16a87-db3e-40b9-9777-434b49fe30ff
md"Note that `resolve` itself doesn't take `env` as argument."

# ╔═╡ 56949924-16cb-4ebc-a64d-e9d1d8244112
md"""
### Type checking (skip)

- This section was written after the code-gen part, so there's a lot of duplication and hacks.
- Not that interesting. Same idea of traversing the tree.
- The main reason we want this is for polymorphic operators (see `NumericOp` below).
"""

# ╔═╡ 7653c5e6-a194-4615-af2b-0150819752e9
function type_check end

# ╔═╡ 859a21c2-1ad0-4703-9166-99bd51778870
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

# ╔═╡ 297f2cba-738d-4c08-8383-f2bad4299a2c
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

# ╔═╡ b5dfddbe-5270-48f6-a5bf-da2a0a2a303d
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

# ╔═╡ df50ef26-2e73-42a8-8c5e-92f0791a7fa8
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

# ╔═╡ 97aec902-fb0f-47d7-9561-907fd8a66ebe
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

# ╔═╡ 7af37747-c304-445e-94dc-61e389c09c42
md"""
### Concrete numeric instructions (skip)
"""

# ╔═╡ 6ca3e3d4-3db3-43db-8972-b44635bf0268
abstract type NumericOp end

# ╔═╡ 65164fda-88b5-496b-8b68-23f0767cbf23
function compile(::Val{:call}, args; env)
	(f, arguments...) = args
	return (
		compile.(arguments; env)...,
		f isa NumericOp ? f : [:call, WasmId(f)]    # operators are functions!
	)
end;

# ╔═╡ a93e8255-1858-430b-af7b-aeeeb5affdfd
compile(src)

# ╔═╡ 4dc3b2da-f81d-4e1d-a670-86b1f17f4f71
## Example
compile(false; env=Env())

# ╔═╡ 6946f89f-afbd-48a9-86d3-6279ceb22eba
## Example
let Γ = Env(Set(), Dict(:foo => :func, :bar => :func))
	expr = :(module _
		export foo
		export bar
	end)
	ir = compile(expr; env=Γ)
	resolve(ir)
end

# ╔═╡ cfb60e48-42d7-40e3-972c-e6b78330af77
struct BinaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ 94f9e424-8e44-4822-8c1d-7c2e60ff3404
struct UnaryOp <: NumericOp
	op::Symbol
	t::Symbol
end

# ╔═╡ ec4813b6-a566-49f4-b2f3-addbbddff12f
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

# ╔═╡ e6e939c9-1e29-41b5-9f93-54771a80700d
md"""### Writing wat"""

# ╔═╡ 694a6085-6de6-473e-999c-4e0ac7cf36b3
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

# ╔═╡ 0cfaf31b-126a-4983-ba61-11ce6c508b27
unary_ops = (
	- = :neg,
	√ = :sqrt,
);

# ╔═╡ 3a2afa7e-9140-44b2-8869-8ce09d0c4365
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

# ╔═╡ e033c912-7136-4f58-8492-933fbb92c68f
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

# ╔═╡ 9e64c70a-8862-47be-b4e0-6e52cc20a20d
md"### Putting it all together"

# ╔═╡ 68e37ea6-387c-4618-ae23-3c071b566a65
function compile_to_wat(expr)
	type_check(expr)
	ir = compile(expr)
	rir = resolve(ir)
	wat = sexpr(rir)
	return wat
end

# ╔═╡ 051a3a6d-14b2-41ce-9669-61d54b10e020
macro wasm(expr)
	wat = compile_to_wat(expr)
	return :(assemble($wat))
end

# ╔═╡ db9845bb-f385-4be8-a18e-5e434e58fc49
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

# ╔═╡ 3e899a0f-1aeb-4f3c-adfe-cb25bc248e44
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

# ╔═╡ af3bbee4-f567-4210-8b1c-b85471a825e7
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

# ╔═╡ 3da302df-033e-4f13-9c05-36b742f7d06a
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

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "e624b7324ac95a09b031bbba021826571a46149f"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "0f748c81756f2e5e6854298f11ad8b2dfae6911a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

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

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

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
# ╟─72e19c3e-7ceb-4c0b-a146-038e50a099c1
# ╟─04f08045-bcda-4ac4-82e1-c438e4766907
# ╟─c589d6d4-eb72-4fdc-90a8-78bfc7ae12ea
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
# ╟─bdf3f885-7735-49b7-a440-81160e4b7087
# ╟─3088c1a3-a8ff-48c1-a211-2904a625be6d
# ╟─cacbf954-38a1-46ae-a03f-b23b14282ac4
# ╠═062604a9-b053-42ad-8041-4f5d0d23dba5
# ╟─3762cc84-3ccd-4d4f-9459-357d851c42a6
# ╟─c31b07c1-4ddf-4a65-b182-631d90494ba3
# ╠═b743ce85-06ea-41f7-becb-37c42266809b
# ╠═8225601a-c091-40d4-93bd-829ce5c001fd
# ╟─062bc743-9784-41e0-b7ae-017c8d821ecb
# ╟─141cae9d-8d3e-4006-8a34-169d7d512891
# ╠═6b1dec74-b4c7-44e5-9cf0-f8d47aa828b9
# ╟─40025535-5866-47e6-8885-ba0b5b896eb5
# ╟─39ff7a57-74cc-491e-9d5d-2dd7e7283a8e
# ╠═35d36acf-bf53-4b86-8198-8d04d79293ba
# ╠═b674d672-790b-4ab6-a631-d7ecb79de9ce
# ╠═db056c9f-421f-4544-adff-ca322285c473
# ╟─83a91b7b-a4b2-492e-b6e1-03dd98251451
# ╠═a93e8255-1858-430b-af7b-aeeeb5affdfd
# ╟─5e6da7d9-eb09-494e-b154-8f06bc43aa4f
# ╠═9eacab37-e42d-438e-86ba-c19c783f5d51
# ╠═be8c3c92-21e2-4087-8794-64b2e50c3073
# ╠═92adb2eb-5e4f-464a-a049-7ccbe7429ebb
# ╠═a7bb0e43-16ac-430e-9a19-8931a542dd28
# ╠═55cdd2e5-b3ff-463f-aa7a-cb6c86a877df
# ╠═3633227a-a4af-4a47-bb3f-2cdd994a9f4c
# ╠═8f5fa10b-12a6-422f-a7aa-27a4adeba52e
# ╠═33c17ceb-30fa-4efe-8d3b-7e997eb03051
# ╠═65164fda-88b5-496b-8b68-23f0767cbf23
# ╠═1d6adaeb-44c0-4965-8470-1fe04c5c8d45
# ╠═5b11f30a-ad11-4548-93bb-8dfa41304d0c
# ╠═b6d9e7c8-4a12-43e8-9fda-64fca44fc2c3
# ╟─043e284d-36b3-4fbe-b3fa-5ad315858545
# ╠═d35e9e2a-8d2b-48dd-b3cb-837f7edcabfb
# ╠═92d3e5cd-df38-4a03-bd8d-4dd6d4ad6408
# ╟─0b473545-7ed1-41ee-a709-f2ecb1d7dca0
# ╠═c4e64b48-81a4-4ee8-8b50-74f805e0a07c
# ╠═a5c3e5f2-449d-40dd-bd9a-3de1d7c10333
# ╠═4214237d-88e1-4d04-a79b-11e431958140
# ╠═7ae4968d-6f13-4f7b-8972-3279e7b53a40
# ╠═70ddc4b5-913a-4353-b82b-e88d0aeed47a
# ╠═4dc3b2da-f81d-4e1d-a670-86b1f17f4f71
# ╟─0b0b16eb-453b-48fd-a021-eeb523f4de46
# ╠═ee7ad653-3aa2-43ae-b33b-6bc1d271034c
# ╠═a947381a-474b-41e6-9ae5-a040c031ba55
# ╠═a4f44e51-ed7f-41cd-8355-36e6dee81bda
# ╠═a5b3d387-1a4d-4380-b530-57a97a591dc1
# ╠═d91a1d83-8482-42ef-83df-f441f7319bc7
# ╟─16f16a87-db3e-40b9-9777-434b49fe30ff
# ╠═6946f89f-afbd-48a9-86d3-6279ceb22eba
# ╟─56949924-16cb-4ebc-a64d-e9d1d8244112
# ╠═7653c5e6-a194-4615-af2b-0150819752e9
# ╠═859a21c2-1ad0-4703-9166-99bd51778870
# ╠═b5dfddbe-5270-48f6-a5bf-da2a0a2a303d
# ╠═3a2afa7e-9140-44b2-8869-8ce09d0c4365
# ╠═297f2cba-738d-4c08-8383-f2bad4299a2c
# ╠═df50ef26-2e73-42a8-8c5e-92f0791a7fa8
# ╠═97aec902-fb0f-47d7-9561-907fd8a66ebe
# ╟─7af37747-c304-445e-94dc-61e389c09c42
# ╠═6ca3e3d4-3db3-43db-8972-b44635bf0268
# ╠═cfb60e48-42d7-40e3-972c-e6b78330af77
# ╠═94f9e424-8e44-4822-8c1d-7c2e60ff3404
# ╠═ec4813b6-a566-49f4-b2f3-addbbddff12f
# ╟─e6e939c9-1e29-41b5-9f93-54771a80700d
# ╠═694a6085-6de6-473e-999c-4e0ac7cf36b3
# ╠═0cfaf31b-126a-4983-ba61-11ce6c508b27
# ╠═e033c912-7136-4f58-8492-933fbb92c68f
# ╟─9e64c70a-8862-47be-b4e0-6e52cc20a20d
# ╠═68e37ea6-387c-4618-ae23-3c071b566a65
# ╠═051a3a6d-14b2-41ce-9669-61d54b10e020
# ╠═db9845bb-f385-4be8-a18e-5e434e58fc49
# ╠═3e899a0f-1aeb-4f3c-adfe-cb25bc248e44
# ╟─af3bbee4-f567-4210-8b1c-b85471a825e7
# ╟─3da302df-033e-4f13-9c05-36b742f7d06a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
