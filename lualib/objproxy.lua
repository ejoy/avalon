
local proxy = {}

local function new_proxy(v, flag)
    if type(v) ~= "table"  or getmetatable(v) == proxy then
        return v
    end
    local p = setmetatable({_proxyobj = {}, _proxyflag = flag or {}}, proxy)
    for k,v in pairs(v) do p[k] = v end

    return p
end

function proxy.__index(t, k)
    return t._proxyobj[k]
end

function proxy.__newindex(t, k, v)
    if t._proxyobj[k] == v then
        return
    end

    v = new_proxy(v, t._proxyflag)
    t._proxyobj[k] = v

    t._proxyflag[1] = true
end

function proxy.__ipairs(t)
    return ipairs(t._proxyobj)
end

function proxy.__pairs(t)
    return pairs(t._proxyobj)
end

local M = {}

function M.new (t)
    return new_proxy(t)
end

function M.is_dirty(t)
    return t._proxyflag[1] == true
end

function M.clean(t)
    t._proxyflag[1] = nil
end

return M
