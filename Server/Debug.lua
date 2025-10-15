Events.SubscribeRemote("ReloadPackages", function()
  Console.Log("Reloading Packages")
  for k, v in pairs(Server.GetPackages(true)) do
    Console.Log("Reloading Package: " .. v.name)
    Chat.BroadcastMessage("Reloading Package: " .. v.name)
    Server.ReloadPackage(v.name)
  end
  for k, v in pairs(Player.GetAll()) do
    Chat.BroadcastMessage(v:GetName() .. " is in dimension " .. v:GetDimension())
    v:SetDimension(1)
  end
end)
