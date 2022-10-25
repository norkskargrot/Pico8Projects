btns={false,false,false,false,false,false}

function updbtns()
	for i=0,5 do
		btns[i+1]=btn(i)
	end
end

function btnd(n)
	return (btn(n)==true and btns[n+1]==false)
end