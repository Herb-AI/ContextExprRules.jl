"""
	Checks if elements of vec1 are contained in vec2 in the same order (possibly with elements in between)
"""
function containedin(vec1::Vector, vec2::Vector)
	vec1_index = 1 # keeps track where we are in the firsst vector
	for item in vec2
		if item == vec1[vec1_index]
			vec1_index += 1  # increase the index every time we encounter the matching element
		end
	end

	vec1_index > length(vec1)
end


"""
Propagates the CanComeAfter constraint: 
	it removes the rule from the domain if the predecessors sequence is in the ancestors
"""
function propagate(c::ComesAfter, context::GrammarContext, domain::Vector{Int})
	ancestors = get_rulesequence(context.originalExpr, context.nodeLocation[begin:end-1])  # remove the current node from the node sequence
	if c.rule in domain  # if rule is in domain, check the ancestors
		if containedin(c.predecessors, ancestors)
			return domain
		else
			return filter!(e -> e != c.rule, domain)
		end
	else # if it is not in the domain, just return domain
		return domain
	end
end