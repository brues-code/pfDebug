-- /fstack: add the owner, script CPU time and allocations of the highlighted
-- frame to ClassicAPI_DebugTools' frame stack tooltip.
local _, ns = ...

local function Line(tooltip, left, right)
  tooltip:AddDoubleLine(left, right, .2, 1, .8, 1, 1, 1)
end

local function Annotate(tooltip, region)
  if not region then return end
  -- a texture or font string runs no scripts: report its frame's
  local frame = region.GetScript and region or region:GetParent()

  tooltip:AddLine(" ")
  tooltip:AddLine(ns.ACCENT .. "pf|rDebug")
  Line(tooltip, "Owner", ns.OwnerLabel(ns.Owner(region)))
  if not frame then return end

  for _, script in ipairs({ "OnUpdate", "OnEvent" }) do
    local fn = frame:GetScript(script)
    if fn then
      local text = ns.OwnerLabel(ns.Owner(fn))
      if ns.profiling then
        local ms, calls = GetFunctionCPUUsage(fn)
        text = text .. ns.GREY .. "  " .. ns.MS(ms) .. " in " .. ns.Count(calls) .. " calls"
      end
      Line(tooltip, script, text)
    end
  end

  if ns.profiling then
    local ms, calls = GetFrameCPUUsage(frame, false)
    Line(tooltip, "All scripts", ns.MS(ms) .. ns.GREY .. " in " .. ns.Count(calls) .. " calls")
  end

  local rec = ns.track.frames[frame]
  if rec and (rec.hookedUpdate or rec.hookedEvent) then
    Line(tooltip, "Allocated", ns.KB(rec.alloc) .. ns.GREY .. " (" .. ns.KBRate(rec.allocRate) .. ")")
  end
end

local function Install()
  FrameStackTooltip:HookScript("OnTooltipSetFrameStack", Annotate)
end

if IsAddOnLoaded("ClassicAPI_DebugTools") then
  Install()
else
  local loader = CreateFrame("Frame")
  loader:RegisterEvent("ADDON_LOADED")
  loader:SetScript("OnEvent", function(self, event, name)
    if name ~= "ClassicAPI_DebugTools" then return end
    self:UnregisterEvent("ADDON_LOADED")
    Install()
  end)
end
