--[[
aeslua: Lua AES implementation
Copyright (c) 2006,2007 Matthias Hilbig

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser Public License as published by the
Free Software Foundation; either version 2.1 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser Public License for more details.

A copy of the terms and conditions of the license can be found in
License.txt or online at

	http://www.gnu.org/copyleft/lesser.html

To obtain a copy, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Author
-------
Matthias Hilbig
http://homepages.upb.de/hilbig/aeslua/
hilbig@upb.de
]]

--require("bit");

-- finite field with base 2 and modulo irreducible polynom x^8+x^4+x^3+x+1 = 0x11d
local private = {};
local public = {};

aeslua.gf = public;

-- private data of gf
private.n = 0x100;
private.ord = 0xff;
private.irrPolynom = 0x11b;
private.exp = {};
private.log = {};

--
-- add two polynoms (its simply xor)
--
function public.add(operand1, operand2) 
	return bit.bxor(operand1,operand2);
end

-- 
-- subtract two polynoms (same as addition)
--
function public.sub(operand1, operand2) 
	return bit.bxor(operand1,operand2);
end

--
-- inverts element
-- a^(-1) = g^(order - log(a))
--
function public.invert(operand)
	-- special case for 1 
	if (operand == 1) then
		return 1;
	end;
	-- normal invert
	local exponent = private.ord - private.log[operand];
	return private.exp[exponent];
end

--
-- multiply two elements using a logarithm table
-- a*b = g^(log(a)+log(b))
--
function public.mul(operand1, operand2)
    if (operand1 == 0 or operand2 == 0) then
        return 0;
    end
	
    local exponent = private.log[operand1] + private.log[operand2];
	if (exponent >= private.ord) then
		exponent = exponent - private.ord;
	end
	return  private.exp[exponent];
end

--
-- divide two elements
-- a/b = g^(log(a)-log(b))
--
function public.div(operand1, operand2)
    if (operand1 == 0)  then
        return 0;
    end
    -- TODO: exception if operand2 == 0
	local exponent = private.log[operand1] - private.log[operand2];
	if (exponent < 0) then
		exponent = exponent + private.ord;
	end
	return private.exp[exponent];
end

--
-- print logarithmic table
--
function public.printLog()
	for i = 1, private.n do
		print("log(", i-1, ")=", private.log[i-1]);
	end
end

--
-- print exponentiation table
--
function public.printExp()
	for i = 1, private.n do
		print("exp(", i-1, ")=", private.exp[i-1]);
	end
end

--
-- calculate logarithmic and exponentiation table
--
function private.initMulTable()
	local a = 1;

	for i = 0,private.ord-1 do
    	private.exp[i] = a;
		private.log[a] = i;

		-- multiply with generator x+1 -> left shift + 1	
		a = bit.bxor(bit.lshift(a, 1), a);

		-- if a gets larger than order, reduce modulo irreducible polynom
		if a > private.ord then
			a = public.sub(a, private.irrPolynom);
		end
	end
end

private.initMulTable();

--return public;