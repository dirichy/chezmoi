local function fixed4(segmentation, env)
	local input = segmentation.input
	if string.match(input, "^%a+$") then
		local i = 0
		local j = 4
		while j < #input do
			local seg = Segment(i, j)
			seg.tags = Set({ "abc" })
			segmentation:add_segment(seg)
			i = i + 4
			j = j + 4
		end
		local seg = Segment(i, #input)
		seg.tags = Set({ "abc" })
		segmentation:add_segment(seg)
		return false
	end
	return true
end
return fixed4
