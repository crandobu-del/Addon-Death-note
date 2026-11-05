local ns = ...
local M, UI = ns.UI.Model, ns.UI
local passed=0
local function check(condition, message) assert(condition,message);passed=passed+1 end
check(M.Text("|Hbad|h") == "||Hbad||h", "escape player markup")
check(#M.Filter({{name="a.b"},{name="axb"}},".",function(r)return r.name end)==1,"literal pattern search")
check(#M.Filter({{name="A"}},"",function(r)return r.name end)==1,"empty search")
check(M.Selected({{id="a"},{id="b"}},"b",function(r)return r.id end).id=="b","retain selected identity")
check(M.Selected({},"missing",function(r)return r.id end)==nil,"empty selection")
for _,frame in ipairs(SR_TEST_FRAMES) do if frame.event=="ADDON_LOADED" then frame.scripts.OnEvent(frame,"ADDON_LOADED","SyndicatRouge") end end
UI.Toggle()
check(UI.window:IsShown() and #UI.window.view.wanted==0,"production starts empty")
check(UI.window.search.font.flags=="", "Forever edit box receives explicit font flags")
check(not UI.provider.demo,"production never loads fixtures")
for _,frame in ipairs(SR_TEST_FRAMES) do if frame.event=="PLAYER_LOGIN" then frame.scripts.OnEvent(frame,"PLAYER_LOGIN") end end
check(UI.provider.demo and #UI.window.view.wanted==4,"separate companion installs demo")
for tab=1,4 do UI.window.tabs[tab].scripts.OnClick() end
local count=#SR_TEST_FRAMES
for pass=1,4 do for tab=1,4 do UI.window.tabs[tab].scripts.OnClick() end end
check(#SR_TEST_FRAMES==count,"refresh reuses frames and text regions")
UI.window.tabs[1].scripts.OnClick()
UI.window.search:SetText("Morne")
check(UI.window.panels[1].current.enemy.name=="Mornecroc","native search selects matching record")
UI.window.search:SetText("nobody")
check(UI.window.panels[1].current==nil,"no results clears dossier")
UI.window.tabs[4].scripts.OnClick()
local p=UI.window.panels[4]
check(p.rows[1].key == p.current.id, "notification selection uses notification identity, not enemy identity")
p.thank.scripts.OnClick()
check(UI.window.panels[4].current.thanked,"thanks updates the personal notification")
check(p.thank.disabled,"thanks cannot be clicked twice")
UI.window.tabs[2].scripts.OnClick()
UI.window.search:SetText("Thörin")
check(UI.window.panels[2].rows[1].title.text:find("3.",1,true)==1,"filter preserves real ranking position")
UI.window.tabs[1].scripts.OnClick()
local wantedPanel=UI.window.panels[1]
wantedPanel.detailScroll:SetVerticalScroll(100)
wantedPanel.rows[4].scripts.OnClick()
check(wantedPanel.detailScroll:GetVerticalScroll()==0,"selecting a new dossier resets detail scroll")
SyndicatRouge.ResetView()
check(not UI.provider.demo and #UI.window.view.wanted==0,"reset removes all fictitious records")
UI.window.tabs[1].scripts.OnClick()
UI.Toggle();check(not UI.window:IsShown(),"toggle closes window")
return {passed=passed}
