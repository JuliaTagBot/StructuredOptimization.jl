immutable MoreauEnvelope{R <: Real, T <: ProximableFunction} <: ProximableFunction
	lambda::R
	g::T
	# dirty trick to use in place prox! when evaluating the function
	# not sure about that!
	buf::AbstractVector{Nullable{AbstractArray}}
	function MoreauEnvelope(lambda::R, g::T)
		if lambda <= 0 error("parameter lambda must be positive") end
		new(lambda, g, [ Nullable{AbstractArray}() ])
	end
end

MoreauEnvelope{R <: Real, T <: ProximableFunction}(lambda::R, g::T) = MoreauEnvelope{R, T}(lambda, g)

is_convex(f::MoreauEnvelope) = is_convex(f.g)
is_smooth(f::MoreauEnvelope) = is_convex(f.g)

function (f::MoreauEnvelope)(x::AbstractArray)
	if isnull(f.buf[1])
		f.buf[1] = Nullable{AbstractArray}(similar(x))
	end
	g_prox = prox!(get(f.buf[1]), f.g, x, f.lambda)
	return g_prox + 1/(2*f.lambda)*deepvecnorm(get(f.buf[1])-x)^2
end

function gradient!(grad::AbstractArray, f::MoreauEnvelope, x::AbstractArray)
	g_prox = prox!(grad, f.g, x, f.lambda)
	grad .= (x - grad)/f.lambda
	fx = g_prox + (f.lambda/2)*deepvecnorm(grad)^2
	return fx
end

fun_name(f::MoreauEnvelope,i::Int64) =
"f$(i)(prox{λ$(i),f$(i)}(A$(i)x))+ 1/2 ‖x - prox{λ$(i),f$(i)}(A$(i)x)‖²"

fun_par( f::MoreauEnvelope,i::Int64)  = "λ$i = $(round(f.lambda,3))"