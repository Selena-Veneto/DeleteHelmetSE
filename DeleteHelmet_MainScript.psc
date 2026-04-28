; ============================================================
; DeleteHelmet_MainScript.psc
; DeleteHelmet SE — Single-script edition
; Requirements : SKSE64, Skyrim SE 1.5.97+
; ============================================================
Scriptname DeleteHelmet_MainScript extends Quest

; ── Properties ──────────────────────────────────────────────
Actor   property PlayerRef    auto
Keyword property ArmorHelmet  auto
Keyword property ClothingHead auto

; ── Saved State (auto hidden = persisted in save) ───────────
bool  property HelmetHidden   = false auto hidden
int   property SavedSlotMask  = 0     auto hidden

; ── Constants ───────────────────────────────────────────────
; Slots to hide: HEAD(0x1) + Hair(0x2) + LongHair(0x800) + Circlet(0x1000)
; Circlet(0x1000) and Ears(0x2000) are intentionally excluded
int HideSlotMask

; ── Hotkey ──────────────────────────────────────────────────
int HotKey

; ============================================================
; OnInit — fires once on first install
; ============================================================
Event OnInit()
    HideSlotMask = 0x00001803   ; HEAD | Hair | LongHair | Circlet 
    HotKey       = 35           ; H key (DIK_H)
    UnregisterForAllKeys()
    RegisterForKey(HotKey)
    Debug.Trace("DeleteHelmet SE - Initialized.")
EndEvent

; ============================================================
; OnPlayerLoadGame — fires on every load/reload
; ============================================================
Event OnPlayerLoadGame()
    HideSlotMask = 0x00000803
    HotKey       = 35
    UnregisterForAllKeys()
    RegisterForKey(HotKey)
    ; Re-apply hidden state if it was active before saving
    if HelmetHidden
        DeleteHelmet_ApplyHide()
    endif
    Debug.Trace("DeleteHelmet SE - Load game hook fired. Hidden=" + HelmetHidden)
EndEvent

; ============================================================
; OnKeyUp — fires once when key is released
; ============================================================
Event OnKeyUp(int KeyCode, float HoldTime)
    if KeyCode != HotKey
        return
    endif
    if Utility.IsInMenuMode()
        return
    endif
    if PlayerRef.IsOnMount()
        Debug.Notification("DeleteHelmet: Cannot toggle while mounted.")
        return
    endif
    if HelmetHidden
        DeleteHelmet_ShowHelmet()
    else
        DeleteHelmet_HideHelmet()
    endif
EndEvent

; ============================================================
; DeleteHelmet_HideHelmet — internal
; ============================================================
Function DeleteHelmet_HideHelmet()
    Armor headArmor = DeleteHelmet_GetHeadArmor()
    if headArmor == None
        Debug.Notification("DeleteHelmet: No helmet equipped.")
        return
    endif
    ; Save the original full slot mask before any modification
    SavedSlotMask = headArmor.GetSlotMask()
    ; Strip only the hair-interfering slots
    headArmor.RemoveSlotFromMask(HideSlotMask)
    Utility.WaitMenuMode(0.05)
    PlayerRef.QueueNiNodeUpdate()
    Utility.WaitMenuMode(0.05)
    ; Restore the slot mask so item stats remain intact
    headArmor.SetSlotMask(SavedSlotMask)
    HelmetHidden = true
    Debug.Notification("Helmet Hidden")
    Debug.Trace("DeleteHelmet SE - Hidden. Armor=" + headArmor.GetName() + " SavedMask=" + SavedSlotMask)
EndFunction

; ============================================================
; DeleteHelmet_ShowHelmet — internal
; ============================================================
Function DeleteHelmet_ShowHelmet()
    HelmetHidden = false
    PlayerRef.QueueNiNodeUpdate()
    Debug.Notification("Helmet Shown")
    Debug.Trace("DeleteHelmet SE - Shown.")
EndFunction

; ============================================================
; DeleteHelmet_ApplyHide — re-applies hidden state silently after load
; ============================================================
Function DeleteHelmet_ApplyHide()
    Armor headArmor = DeleteHelmet_GetHeadArmor()
    if headArmor == None
        ; Helmet may have been unequipped before save; reset state
        HelmetHidden  = false
        SavedSlotMask = 0
        return
    endif
    SavedSlotMask = headArmor.GetSlotMask()
    headArmor.RemoveSlotFromMask(HideSlotMask)
    Utility.WaitMenuMode(0.05)
    PlayerRef.QueueNiNodeUpdate()
    Utility.WaitMenuMode(0.05)
    headArmor.SetSlotMask(SavedSlotMask)
    Debug.Trace("DeleteHelmet SE - Re-applied hide on load.")
EndFunction

; ============================================================
; DeleteHelmet_GetHeadArmor — returns helmet/hood worn in HEAD slot
; Returns None if nothing worn or item lacks correct keyword
; ============================================================
Armor Function DeleteHelmet_GetHeadArmor()
    Armor headArmor = PlayerRef.GetWornForm(0x00000002) as Armor
    if headArmor == None
        return None
    endif
    if headArmor.HasKeyword(ArmorHelmet) || headArmor.HasKeyword(ClothingHead)
        return headArmor
    endif
    return None
EndFunction