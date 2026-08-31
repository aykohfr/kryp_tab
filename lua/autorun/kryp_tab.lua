KrypTab = KrypTab or {}

if SERVER then
    AddCSLuaFile("kryp_tab/sh_config.lua")
    AddCSLuaFile("kryp_tab/cl_tablist.lua")
end

include("kryp_tab/sh_config.lua")

if CLIENT then
    include("kryp_tab/cl_tablist.lua")
end
