
include("terms_extract.jl")
include("terms_properties.jl")
include("terms_splitting.jl")

abstract type Solver end

abstract type FBSolver <: Solver end

################################################################################
export PG, FPG

struct PG <: FBSolver
    kwargs::Array
    function PG(; kwargs...)
        new(kwargs)
    end
end

function FPG(; kwargs...)
    return PG(; kwargs..., fast=true)
end

function apply!(solver::PG, x; kwargs...)
    (it, xsol, solver) = ProximalAlgorithms.FBS(x; solver.kwargs..., kwargs...)
    blockcopy!(x, xsol)
    return solver
end

################################################################################
export ZeroFPR

struct ZeroFPR <: FBSolver
    kwargs::Array
    function ZeroFPR(; kwargs...)
        new(kwargs)
    end
end

function apply!(solver::ZeroFPR, x; kwargs...)
    (it, xsol, solver) = ProximalAlgorithms.ZeroFPR(x; solver.kwargs..., kwargs...)
    blockcopy!(x, xsol)
    return solver
end

################################################################################
export PANOC

struct PANOC <: FBSolver
    kwargs::Array
    function PANOC(; kwargs...)
        new(kwargs)
    end
end

function apply!(solver::PANOC, x; kwargs...)
    (it, xsol, solver) = ProximalAlgorithms.PANOC(x; solver.kwargs..., kwargs...)
    blockcopy!(x, xsol)
    return solver
end

################################################################################
export solve!

function solve!(terms::Tuple, solver::FBSolver)
	x = extract_variables(terms)
	# Separate smooth and nonsmooth
	smooth, nonsmooth = split_smooth(terms)
	# Separate quadratic and nonquadratic
	quadratic, smooth = split_quadratic(smooth)
	kwargs = Array{Any, 1}()
	if is_proximable(nonsmooth)
		g = extract_proximable(x, nonsmooth)
		append!(kwargs, [(:g, g)])
		if !isempty(quadratic)
			fq = extract_functions(quadratic)
			Aq = extract_operators(x, quadratic)
			append!(kwargs, [(:fq, fq)])
			append!(kwargs, [(:Aq, Aq)])
		end
		if !isempty(smooth)
			fs = extract_functions(smooth)
			As = extract_operators(x, smooth)
			if is_linear(smooth)
				append!(kwargs, [(:As, As)])
			else
				fs = RegLS.PrecomposeNonlinear(fs, As)
			end
			append!(kwargs, [(:fs, fs)])
		end
		return apply!(solver, ~x; kwargs...)
	end
	error("Sorry, I cannot solve this problem")
end

################################################################################

default_solver = PANOC
