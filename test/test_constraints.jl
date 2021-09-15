@testset "ComesAfter" begin
	
	grammar = @cgrammar begin
		Real = 1 | 2 | 3
		Real = Real + Real
		Real = Real * Real
	end

	iter = ContextExpressionIterator(grammar, 2, :Real)
	elems = collect(iter)

	constraint = ComesAfter(3,5)
	addconstraint!(grammar, constraint)

	iter2 = ContextExpressionIterator(grammar, 2, :Real)
	elems2 = collect(iter2)

	@test length(elems) > length(elems2)
	@test length(elems) == 21
	@test length(elems2) == 15
end