------------------------------------------------------------------------------------------------------------------------
--                                                    User library                                                    --
------------------------------------------------------------------------------------------------------------------------

local wrequire = require("redflat.util").wrequire
local setmetatable = setmetatable

local lib = { _NAME = "user.float" }

return setmetatable(lib, { __index = wrequire })
