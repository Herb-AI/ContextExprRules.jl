using ContextExprRules

grammar = @cgrammar begin
	Real = 1 | 2 | 3
	Real = Real + Real
	Real = Real * Real
end

# iter = ConstrExpressionIterator(grammar, 2, :Real)
# elems = collect(iter)

constraint = ComesAfter(3,5)

addconstraint!(grammar, constraint)

iter2 = ContextExpressionIterator(grammar, 2, :Real)
elems2 = collect(iter2)