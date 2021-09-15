
"""
Returns all rules of a specific type used in a RuleNode 
"""
function rulesoftype(node::RuleNode, ruleset::Set{Int})
	retval = Set()

	if node.ind in ruleset
		union!(retval, [node.ind])
	end

	if isempty(node.children)
		return retval
	else
		for child in node.children
			union!(retval, rulesoftype(child, ruleset))
		end

		return retval
	end
end

rulesoftype(node::RuleNode, grammar::GrammarType, ruletype::Symbol) = rulesoftype(node, Set(grammar[ruletype]))



"""
Returns all rules of a specific type used in a RuleNode but not in the ignoreNode
"""
function rulesoftype(node::RuleNode, ruleset::Set{Int}, ignoreNode::RuleNode)
	retval = Set()

	if node == ignoreNode
		return retval
	end

	if node.ind in ruleset
		union!(retval, [node.ind])
	end

	if isempty(node.children)
		return retval
	else
		for child in node.children
			union!(retval, rulesoftype(child, ruleset))
		end

		return retval
	end
end

rulesoftype(node::RuleNode, grammar::GrammarType, ruletype::Symbol, ignoreNode::RuleNode) = rulesoftype(node, Set(grammar[ruletype]), ignoreNode)



"""
Replace a node in expr, specified by path, with new_expr.
Path is a sequence of child indices, starting from the node 
"""
function swap_node(expr::RuleNode, new_expr::RuleNode, path::Vector{Int})
	if length(path) == 1
		expr.children[path[begin]] = new_expr
	else
		swap_node(expr.children[path[begin]], new_expr, path[2:end])
	end
end


"""
	Replace child i of a node,  a part of larger expr, with new_expr
"""
function swap_node(expr::RuleNode, node::RuleNode, child_index::Int, new_expr::RuleNode)
	if expr == node 
		node.children[child_index] = new_expr
	else
		for child in expr.children
			swap_node(child, node, child_index, new_expr)
		end
	end
end


"""
	Extract derivation sequence from path  (sequence of child indices)

	if the path is deeper than the deepest node, it returns what it has 
"""
function get_rulesequence(node::RuleNode, path::Vector{Int})
	if isempty(node.children)
		return []
	elseif isempty(path)
		if node.ind == 0   # sign for empty node
			return []
		else
			return [node.ind]
		end
	else
		return append!([node.ind], get_rulesequence(node.children[path[begin]], path[2:end]))
	end
end