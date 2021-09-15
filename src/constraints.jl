abstract type Constraint end
abstract type ValidatorConstraint <: Constraint end
abstract type PropagatorConstraint <: Constraint end

"""
	Derivation rule can only appear in the derivation tree if the predecessors are in the path to the current node (in order)
"""
struct ComesAfter <: PropagatorConstraint
	rule::Int 
	predecessors::Vector{Int}
end

ComesAfter(rule::Int, predecessor::Int) = ComesAfter(rule, [predecessor])




"""
	
"""
struct Ordered
	rules
end