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

--local aes = require("aeslua.aes");
--local util = require("aeslua.util");
--local buffer = require("aeslua.buffer");

local aes = aeslua.aes;
local util = aeslua.util;
local buffer = aeslua.buffer;

local public = {};

aeslua.ciphermode = public;

--
-- Encrypt strings
-- key - byte array with key
-- string - string to encrypt
-- modefunction - function for cipher mode to use
--
function public.encryptString(key, data, modeFunction)
    local iv = iv or {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    local keySched = aes.expandEncryptionKey(key);
    local encryptedData = buffer.new();
    
    for i = 1, #data/16 do
        local offset = (i-1)*16 + 1;
        local byteData = {string.byte(data,offset,offset +15)};
		
        modeFunction(keySched, byteData, iv);

        buffer.addString(encryptedData, string.char(unpack(byteData)));    
    end
    
    return buffer.toString(encryptedData);
end

--
-- the following 4 functions can be used as 
-- modefunction for encryptString
--

-- Electronic code book mode encrypt function
function public.encryptECB(keySched, byteData, iv) 
	aes.encrypt(keySched, byteData, 1, byteData, 1);
end

-- Cipher block chaining mode encrypt function
function public.encryptCBC(keySched, byteData, iv) 
    util.xorIV(byteData, iv);

    aes.encrypt(keySched, byteData, 1, byteData, 1);    
        
    for j = 1,16 do
        iv[j] = byteData[j];
    end
end

-- Output feedback mode encrypt function
function public.encryptOFB(keySched, byteData, iv) 
    aes.encrypt(keySched, iv, 1, iv, 1);
    util.xorIV(byteData, iv);
end

-- Cipher feedback mode encrypt function
function public.encryptCFB(keySched, byteData, iv) 
    aes.encrypt(keySched, iv, 1, iv, 1);    
    util.xorIV(byteData, iv);
       
    for j = 1,16 do
        iv[j] = byteData[j];
    end        
end

--
-- Decrypt strings
-- key - byte array with key
-- string - string to decrypt
-- modefunction - function for cipher mode to use
--
function public.decryptString(key, data, modeFunction)
    local iv = iv or {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    
    local keySched;
    if (modeFunction == public.decryptOFB or modeFunction == public.decryptCFB) then
    	keySched = aes.expandEncryptionKey(key);
   	else
   		keySched = aes.expandDecryptionKey(key);
    end
    
    local decryptedData = buffer.new();

    for i = 1, #data/16 do
        local offset = (i-1)*16 + 1;
        local byteData = {string.byte(data,offset,offset +15)};

		iv = modeFunction(keySched, byteData, iv);

        buffer.addString(decryptedData, string.char(unpack(byteData)));
    end

    return buffer.toString(decryptedData);    
end

--
-- the following 4 functions can be used as 
-- modefunction for decryptString
--

-- Electronic code book mode decrypt function
function public.decryptECB(keySched, byteData, iv) 

    aes.decrypt(keySched, byteData, 1, byteData, 1);
    
    return iv;
end

-- Cipher block chaining mode decrypt function
function public.decryptCBC(keySched, byteData, iv) 
	local nextIV = {};
    for j = 1,16 do
        nextIV[j] = byteData[j];
    end
        
    aes.decrypt(keySched, byteData, 1, byteData, 1);    
    util.xorIV(byteData, iv);

	return nextIV;
end

-- Output feedback mode decrypt function
function public.decryptOFB(keySched, byteData, iv) 
    aes.encrypt(keySched, iv, 1, iv, 1);
    util.xorIV(byteData, iv);
    
    return iv;
end

-- Cipher feedback mode decrypt function
function public.decryptCFB(keySched, byteData, iv) 
    local nextIV = {};
    for j = 1,16 do
        nextIV[j] = byteData[j];
    end

    aes.encrypt(keySched, iv, 1, iv, 1);
        
    util.xorIV(byteData, iv);
    
    return nextIV;
end

--return public;