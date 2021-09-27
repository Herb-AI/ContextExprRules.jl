
"""
	Structure representing context-sensitive grammar
	Extends ExprRules.Grammar with constraints
"""
struct ContextGrammar <: GrammarType
	rules::Vector{Any}
	types::Vector{Symbol}
	isterminal::BitVector
	iseval::BitVector
	bytype::Dict{Symbol, Vector{Int}}
	childtypes::Vector{Vector{Symbol}}
	constraints::Vector{Constraint}
end


"""
    get_childtypes(rule::Any, types::AbstractVector{Symbol})
Returns the child types of a production rule.
"""
function get_childtypes(rule::Any, types::AbstractVector{Symbol})
    retval = Symbol[]
    if isa(rule, Expr)
        for arg in rule.args
            append!(retval, get_childtypes(arg, types))
        end
    elseif rule ∈ types
        push!(retval, rule)
    end
    return retval
end


"""
	Reduces the set of possible children of a node using the grammar's constraints
"""
function propagate_contraints(grammar::ContextGrammar, context::GrammarContext, child_rules::Vector{Int})
	domain = child_rules

	for propagator in grammar.constraints
		domain = propagate(propagator, context, domain)
	end

	return domain
end



"""
	reimplementation of the ExprRules._next_state!
	Change: child expressions are filtered so that the constraints are not violated

"""
function _next_state!(node::RuleNode, grammar::ContextGrammar, max_depth::Int, context::GrammarContext)

	if max_depth < 1
	    return (node, false) # did not work
	elseif isterminal(grammar, node)
	    # do nothing
	    if iseval(grammar, node.ind) && (node._val === nothing)  # evaluate the rule
		node._val = eval(grammar.rules[node.ind].args[2])
	    end
	    return (node, false) # cannot change leaves
	else # !isterminal
	    # if node is not terminal and doesn't have children, expand every child
	    if isempty(node.children)  
		if max_depth ≤ 1
		    return (node,false) # cannot expand
		end

		child_index = 1  # keepa track of which child we are processing now (needed for context)
    
		# build out the node
		for c in child_types(grammar, node)
		    worked = false
		    i = 0
		    child = RuleNode(0)

		    new_context = GrammarContext(context.originalExpr, deepcopy(context.nodeLocation))
		    push!(new_context.nodeLocation, child_index)

		    child_rules = [x for x in grammar[c]]  # select all applicable rules
		    child_rules = propagate_contraints(grammar, new_context, child_rules)  # filter out those that violate constraints

		    while !worked && i < length(child_rules)
			i += 1
			child = RuleNode(child_rules[i])
    
			if iseval(grammar, child.ind) # if rule needs to be evaluated (_())
			    child._val = eval(grammar.rules[child.ind].args[2])
			end

			worked = true
			if !isterminal(grammar, child)
			    child, worked = _next_state!(child, grammar, max_depth-1, new_context)
			end
		    end
		    if !worked
			return (node, false) # did not work
		    end
		    push!(node.children, child)

		    child_index += 1
		end
    
		return (node, true)
	    else # not empty
		# make one change, starting with rightmost child
		worked = false
		child_index = length(node.children) + 1
		while !worked && child_index > 1
		    child_index -= 1
		    child = node.children[child_index]
    
		    new_context = GrammarContext(context.originalExpr, deepcopy(context.nodeLocation))
		    push!(new_context.nodeLocation, child_index)

		    child, child_worked = _next_state!(child, grammar, max_depth-1, new_context)
		    while !child_worked
			child_type = return_type(grammar, child)

			child_rules = [x for x in grammar[child_type]]  # get all applicable rules
			child_rules = propagate_contraints(grammar, new_context, child_rules)  # filter ones that violate constraints


			i = something(findfirst(isequal(child.ind), child_rules), 0)
			if i < length(child_rules)
			    child_worked = true
			    child = RuleNode(child_rules[i+1])
    
			    # node needs to be evaluated
			    if iseval(grammar, child.ind)
				child._val = eval(grammar.rules[child.ind].args[2])
			    end
    
			    if !isterminal(grammar, child)
				child, child_worked = _next_state!(child, grammar, max_depth-1, new_context)
			    end
			    node.children[child_index] = child
			else
			    break
			end
		    end
    
		    if child_worked
			worked = true
    
			# reset remaining children
			for child_index2 in child_index+1 : length(node.children)
			    c = child_types(grammar, node)[child_index2]
			    worked = false
			    i = 0
			    child = RuleNode(0)

			    new_context = GrammarContext(context.originalExpr, deepcopy(context.nodeLocation))
			    push!(new_context.nodeLocation, child_index2)

			    child_rules = [x for x in grammar[c]]  # take all applicable rules
			    child_rules = propagate_contraints(grammar, new_context, child_rules)  # reomove ones that violate constraints


			    while !worked && i < length(child_rules)
				i += 1
				child = RuleNode(child_rules[i])
    
				if iseval(grammar, child.ind)
				    child._val = eval(grammar.rules[child.ind].args[2])
				end
    
				worked = true
				if !isterminal(grammar, child)
				    child, worked = _next_state!(child, grammar, max_depth-1, new_context)
				end
			    end
			    if !worked
				break
			    end
			    node.children[child_index2] = child
			end
		    end
		end
    
		return (node, worked)
	    end
	end
    end



mutable struct ContextExpressionIterator <: ExprIter
	grammar::ContextGrammar
	max_depth::Int
	sym::Symbol
end


function Base.iterate(iter::ContextExpressionIterator)
	init_node = RuleNode(0)  # needed for propagating constraints on the root node 
	init_context = GrammarContext(init_node)
    
	grammar, sym, max_depth = iter.grammar, iter.sym, iter.max_depth
    
	# propagate constraints on the root node 
	sym_rules = [x for x in grammar[sym]]
	sym_rules = propagate_contraints(grammar, init_context, sym_rules)
	#node = RuleNode(grammar[sym][1])
	node = RuleNode(sym_rules[1])
     
	if isterminal(grammar, node)
	    return (deepcopy(node), node)
	else
	    context = GrammarContext(node)
	    node, worked =  _next_state!(node, grammar, max_depth, context)
	    while !worked
		# increment root's rule
		rules = [x for x in grammar[sym]]
		rules = propagate_contraints(grammar, init_context, rules) # propagate constraints on the root node
    
		i = something(findfirst(isequal(node.ind), rules), 0)
		if i < length(rules)
		    node, worked = RuleNode(rules[i+1]), true
		    if !isterminal(grammar, node)
			node, worked = _next_state!(node, grammar, max_depth, context)
		    end
		else
		    break
		end
	    end
	    return worked ? (deepcopy(node), node) : nothing
	end
end



function Base.iterate(iter::ContextExpressionIterator, state::RuleNode)
	grammar, max_depth = iter.grammar, iter.max_depth
	context = GrammarContext(state)
	node, worked = _next_state!(state, grammar, max_depth, context)
    
	while !worked
	    # increment root's rule
	    init_node = RuleNode(0)  # needed for propagating constraints on the root node 
    	    init_context = GrammarContext(init_node)

	    rules = [x for x in grammar[iter.sym]]
	    rules = propagate_contraints(grammar, init_context, rules)

	    i = something(findfirst(isequal(node.ind), rules), 0)
	    if i < length(rules)
		node, worked = RuleNode(rules[i+1]), true
		if !isterminal(grammar, node)
		    context = GrammarContext(node)
		    node, worked = _next_state!(node, grammar, max_depth, context)
		end
	    else
		break
	    end
	end
	return worked ? (deepcopy(node), node) : nothing
end


macro cgrammar(ex)
	rules = Any[]
	types = Symbol[]
	bytype = Dict{Symbol,Vector{Int}}()
	for e in ex.args
	    if isa(e, Expr)
		if e.head == :(=)
		    s = e.args[1] # name of return type
		    rule = e.args[2] # expression?
		    rvec = Any[]
		    _parse_rule!(rvec, rule)
		    for r in rvec
			push!(rules, r)
			push!(types, s)
			bytype[s] = push!(get(bytype, s, Int[]), length(rules))
		    end
		end
	    end
	end
	alltypes = collect(keys(bytype))
	is_terminal = [isterminal(rule, alltypes) for rule in rules]
	is_eval = [iseval(rule) for rule in rules]
	childtypes = [get_childtypes(rule, alltypes) for rule in rules]
	return ContextGrammar(rules, types, is_terminal, is_eval, bytype, childtypes, [])
end

_parse_rule!(v::Vector{Any}, r) = push!(v, r)

function _parse_rule!(v::Vector{Any}, ex::Expr)
	if ex.head == :call && ex.args[1] == :|
	     terms = length(ex.args) == 2 ?
		collect(interpret(ex.args[2])) :    #|(a:c) case
		ex.args[2:end]                      #a|b|c case
	    for t in terms
		_parse_rule!(v, t)
	    end
	else
	    push!(v, ex)
	end
end


"""
    Add constraint to the grammar
"""
addconstraint!(grammar::ContextGrammar, cons::Constraint) = push!(grammar.constraints, cons)

