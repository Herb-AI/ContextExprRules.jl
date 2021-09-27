"""
	Checks if elements of vec1 are contained in vec2 in the same order (possibly with elements in between)
"""
function containedin(vec1::Vector, vec2::Vector)
	max_elements = length(vec1)
	vec1_index = 1 # keeps track where we are in the firsst vector
	for item in vec2
		if vec1_index > max_elements
			return true
		end
		
		if item == vec1[vec1_index]
			vec1_index += 1  # increase the index every time we encounter the matching element
		end
	end

	return vec1_index > max_elements
end