FreeTablist = FreeTablist or {}

if SERVER then
    AddCSLuaFile("free_tablist/sh_config.lua")
    AddCSLuaFile("free_tablist/cl_tablist.lua")
end

include("free_tablist/sh_config.lua")

if CLIENT then
    include("free_tablist/cl_tablist.lua")
end
