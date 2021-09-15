"""
Structure used to track the context - the expression being modified and the path to the current node 
"""
mutable struct GrammarContext
	originalExpr::RuleNode    	# original expression being modified
	nodeLocation::Vector{Int}   	# path to he current node in the expression, a sequence of child indices for each parent
end

GrammarContext(originalExpr::RuleNode) = GrammarContext(originalExpr, [])


"""
add parent to the context
"""
function addparent!(context::GrammarContext, parent::Int)
	push!(context.nodeLocation, parent)
end