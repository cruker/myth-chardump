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

local public = {};
local private = {};

aeslua.util = public;

--
-- calculate the parity of one byte
--
function public.byteParity(byte)
    byte = bit.bxor(byte, bit.rshift(byte, 4));
    byte = bit.bxor(byte, bit.rshift(byte, 2));
    byte = bit.bxor(byte, bit.rshift(byte, 1));
    return bit.band(byte, 1);
end

-- 
-- get byte at position index
--
function public.getByte(number, index)
    if (index == 0) then
        return bit.band(number,0xff);
    else
        return bit.band(bit.rshift(number, index*8),0xff);
    end
end


--
-- put number into int at position index
--
function public.putByte(number, index)
    if (index == 0) then
        return bit.band(number,0xff);
    else
        return bit.lshift(bit.band(number,0xff),index*8);
    end
end

--
-- convert byte array to int array
--
function public.bytesToInts(bytes, start, n)
    local ints = {};
    for i = 0, n - 1 do
        ints[i] = public.putByte(bytes[start + (i*4)    ], 3)
                + public.putByte(bytes[start + (i*4) + 1], 2) 
                + public.putByte(bytes[start + (i*4) + 2], 1)    
                + public.putByte(bytes[start + (i*4) + 3], 0);
    end
    return ints;
end

--
-- convert int array to byte array
--
function public.intsToBytes(ints, output, outputOffset, n)
    n = n or #ints;
    for i = 0, n do
        for j = 0,3 do
            output[outputOffset + i*4 + (3 - j)] = public.getByte(ints[i], j);
        end
    end
    return output;
end

--
-- convert bytes to hexString
--
function private.bytesToHex(bytes)
    local hexBytes = "";
    
    for i,byte in ipairs(bytes) do 
        hexBytes = hexBytes .. string.format("%02x ", byte);
    end

    return hexBytes;
end

--
-- convert data to hex string
--
function public.toHexString(data)
    local type = type(data);
    if (type == "number") then
        return string.format("%08x",data);
    elseif (type == "table") then
        return private.bytesToHex(data);
    elseif (type == "string") then
        local bytes = {string.byte(data, 1, #data)}; 

        return private.bytesToHex(bytes);
    else
        return data;
    end
end

function public.padByteString(data)
    local dataLength = #data;
    
    local random1 = math.random(0,255);
    local random2 = math.random(0,255);

    local prefix = string.char(random1,
                               random2,
                               random1,
                               random2,
                               public.getByte(dataLength, 3),
                               public.getByte(dataLength, 2),
                               public.getByte(dataLength, 1),
                               public.getByte(dataLength, 0));

    data = prefix .. data;

    local paddingLength = math.ceil(#data/16)*16 - #data;
    local padding = "";
    for i=1,paddingLength do
        padding = padding .. string.char(math.random(0,255));
    end 

    return data .. padding;
end

function private.properlyDecrypted(data)
    local random = {string.byte(data,1,4)};

    if (random[1] == random[3] and random[2] == random[4]) then
        return true;
    end
    
    return false;
end

function public.unpadByteString(data)
    if (not private.properlyDecrypted(data)) then
        return nil;
    end

    local dataLength = public.putByte(string.byte(data,5), 3)
                     + public.putByte(string.byte(data,6), 2) 
                     + public.putByte(string.byte(data,7), 1)    
                     + public.putByte(string.byte(data,8), 0);
    
    return string.sub(data,9,8+dataLength);
end

function public.xorIV(data, iv)
    for i = 1,16 do
        data[i] = bit.bxor(data[i], iv[i]);
    end 
end

--return public;