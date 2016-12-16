using RegLS
using ProximalOperators
using Base.Test
using MathProgBase
using Ipopt

n = 2100 # number of features
m = 130 # number of data points

w = randn(n)

A = randn(m, n)
btrue = sign(A*w)

b = sign(btrue + sqrt(0.1)*randn(m))
mu = 1.0

# solve dual problem (it's a QP)
BA = b.*A;
Q = BA*BA';
q = ones(size(A, 1));
sol = quadprog(-q, Q, eye(m), '<', Inf, 0.0, mu, IpoptSolver(print_level=0))
x_qp = BA'*sol.sol;

println("Solving random SVM problem: default solver/options")
y, slv = solve(zeros(n+1), HingeLoss(b, mu), A)

println("Solving random SVM problem: random initial point")
y, slv = solve(zeros(n+1), HingeLoss(b, mu), A, randn(m))

println("Solving random SVM problem: proximal gradient (quiet)")
y, slv = solve(zeros(n+1), HingeLoss(b, mu), A, zeros(m), PG(verbose = 0))

println("Solving random SVM problem: fast proximal gradient (quiet)")
y, slv = solve(zeros(n+1), HingeLoss(b, mu), A, zeros(m), FPG(verbose = 0))