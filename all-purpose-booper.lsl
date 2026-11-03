/*
||  ========================================================================
||  OPOSSUM LABS ALL PURPOSE BOOPER
||  ========================================================================
||  Version: 3.1 (custom nickname, 2026-11-03)
||
||  Features:
||    - Anatomy Categories: Forehead, Nose, Ears, Cheeks, Muzzle, Lips, Neck
||    - First-run setup: pronouns + consent style (re-run any time via Reset)
||    - Pronoun substitution ([toucher], [owner], [sub], [obj], [pos], [s])
||    - Custom nickname via Settings > Name, used in action text, consent
||      dialogs, and the counter (blank = your display name)
||    - Global consent system: owner approves each visitor action, 30 second
||      timeout, one request at a time, trusted list skips the check
||    - Boop counter with hover text ("<nickname> has been booped N times!"),
||      saved in linkset data
||    - Cooldown on the last visitor to stop spamming
||    - Owner Settings: Lock, Pronouns, Consent, Sounds, Particles,
||      Manual Blush, Help notecard, Reset
||    - Settings persist across re-rez and script resets (linkset data)
||    - No bundled assets: a sound named like a button plays with it
||      (capitalization does not matter), and the first texture in the
||      contents shapes the heart burst. Missing assets are skipped.
||  ========================================================================
||  License: GNU GPL v3 - https://www.gnu.org/licenses/gpl-3.0.txt
||  This program is distributed in the hope that it will be useful,
||  but WITHOUT ANY WARRANTY; without even the implied warranty of
||  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
||  GNU General Public License for details.
*/

// ########## CONSTANTS ##########
integer BLUSH_CHANNEL    = 88;     // relay channel for the blush mesh command
float   TOUCH_RANGE      = 10.0;   // max distance a non-owner touch is accepted from
integer CONSENT_TIMEOUT  = 30;     // seconds an unanswered consent request lives
integer TOUCH_COOLDOWN   = 8;      // seconds one visitor must wait between actions
integer HOVER_TIME       = 10;     // seconds the boop counter floats after each action
integer MAX_TRUSTED      = 16;     // trusted-list cap (skip-consent regulars)
string  PREF_PREFIX      = "APB."; // linkset-data key prefix for saved settings

// ########## ANATOMY CATEGORY DATA (PACKED STRINGS - MEMORY) ##########
// One packed string per category: "Name|action text|Name|action text|...".
// Names sit at even fields, texts at odd. No pipes inside the texts.
// [toucher] = Person clicking | [owner] = You | [sub] = he/she/they | [obj] = him/her/them | [pos] = his/her/their
string catForehead = "Pat|[toucher] gently pats [owner] on the head, ruffling [pos] fur.|Rest|[toucher] softly rests their forehead against [owner][s] forehead.|Kiss|[toucher] leans in and places a tender kiss right on [owner][s] forehead.|Bonk|[toucher] playfully bonks their head against [owner][s] forehead!|Noogie|[toucher] gives [owner] a playful, friendly noogie on top of [pos] head!";

string catNose = "Boop|[toucher] boops [owner][s] nose!|Beep|[toucher] touches [owner][s] li'l nose, making it beep?!|Nose Kiss|[toucher] presses a sweet kiss right on the tip of [owner][s] nose!|Lick|[toucher] licks [owner][s] nose playfully!|Smack|[toucher] smacks [owner][s] snout!|Bite|[toucher] bites [owner][s] poor nose! D:|Nuzzle|[toucher] nuzzles their nose against [owner][s] snoot affectionately.";

string catEars = "Scritch|[toucher] reaches up and scritches [owner][s] ears affectionately.|Ear Flop|[toucher] flicks [owner][s] ear, watching it flop back into place.|Ear Nibble|[toucher] leans in and nibbles gently on [owner][s] ear.|Ear Flick|[toucher] flicks [owner] hard on the ear. Hey!|Whisper|[toucher] leans in close and whispers something sweet directly into [owner][s] ear.|Flatten|[toucher] gently presses [owner][s] ears down flat against [pos] head.|Behind Ears|[toucher] scritches [owner] right behind the ears, making [pos] foot thump happily!";

string catCheeks = "Slap|[toucher] slaps [owner] upside the head for being silly!|Rub|[toucher] lovingly rubs their cheek against [owner][s] cheek.|Pinch|[toucher] playfully pinches [owner][s] fluffy cheeks!|Groom|[toucher] licks and lovingly grooms the fur on [owner][s] cheeks.|Squish|[toucher] squishes [owner][s] cheeks together, squeezing [pos] muzzle!|Chin Rub|[toucher] scritches [owner] under the chin, making [obj] lean into it.|Kiss Cheek|[toucher] presses a warm kiss against [owner][s] soft cheek.";

string catMuzzle = "Lick Muzzle|[toucher] licks [owner][s] nose and then licks down [pos] muzzle.|Hold Snoot|[toucher] gently holds [owner][s] muzzle in their hands.|Muzzle Rub|[toucher] nuzzles [owner] affectionately, muzzle to muzzle.";

string catLips = "Quick Peck|[toucher] presses a quick peck to [owner][s] lips.|Kiss|[toucher] kisses [owner] gently on the lips.|Deeply Kiss|[toucher] kisses [owner] deeply, exploring [pos] mouth with their tongue!|Playfully Bite|[toucher] playfully bites down on [owner][s] lip.|Make Out|[toucher] pulls [owner] close and passionately makes out with [obj]!";

string catNeck = "Scent|[toucher] nuzzles into [owner][s] neck, deeply taking in [pos] scent.|Collar Tug|[toucher] grabs [owner][s] collar and pulls [obj] in close.|Mark|[toucher] bites down on [owner][s] neck and shoulder, leaving a clear mating mark.|Purr Rub|[toucher] rubs against [owner][s] neck, causing [obj] to purr softly.|Nuzzle Neck|[toucher] buries their face into [owner][s] neck fluff.|Lick Neck|[toucher] runs their tongue up the side of [owner][s] neck.";

// ########## CATEGORY ROUTER & ACCESSORS ##########
list categoriesList = ["Forehead", "Nose", "Ears", "Cheeks", "Muzzle", "Lips", "Neck"];

string catData(integer cat) {
    if (cat == 0) return catForehead;
    if (cat == 1) return catNose;
    if (cat == 2) return catEars;
    if (cat == 3) return catCheeks;
    if (cat == 4) return catMuzzle;
    if (cat == 5) return catLips;
    if (cat == 6) return catNeck;
    return "";
}

// Button names for one category, for llDialog menus.
list actionNames(integer cat) {
    list f = llParseString2List(catData(cat), ["|"], []);
    list names = [];
    integer n = llGetListLength(f);
    integer i;
    for (i = 0; i < n; i += 2) names += [llList2String(f, i)];
    return names;
}

// Text for an action name in the open category; "" when the button is unknown.
string textFor(integer cat, string actionName) {
    list f = llParseString2List(catData(cat), ["|"], []);
    integer idx = llListFindList(f, [actionName]);
    if (idx == -1) return "";
    return llList2String(f, idx + 1);
}

// ########## INTERNAL STATE ##########
integer comChannel;
integer gListen = -1;
integer gBlushOn = FALSE;
integer gCurrentCat = -1;   // the open category (shared, like a single menu)
key     gPendingToucher = NULL_KEY;
string  gPendingMsg = "";
string  gPendingAction = "";
integer gPendingUntil = 0;
key     gLastVisitor = NULL_KEY;  // cooldown slot: the last non-owner to act
integer gLastUntil = 0;

// Dynamic Settings
string  pSub = "they";
string  pObj = "them";
string  pPos = "their";
integer consentRequired = TRUE;
integer gSoundsOn = TRUE;
integer gParticlesOn = TRUE;
integer gCount = 0;
integer gHoverUntil = 0;
string  gCustomName = "";    // owner's nickname ("" = use display name)
integer gNameListen = -1;   // one-shot textbox listener

// ########## NAMES & TEXT INTERPOLATION ##########
string nameOf(key id) {
    string n = llGetDisplayName(id);
    if (n == "") n = llKey2Name(id);
    if (n == "") n = "Someone";
    return n;
}

// The owner's name: chosen nickname if set, else display name.
// Toucher names always stay real display names.
string ownerName() {
    if (gCustomName != "") return gCustomName;
    return nameOf(llGetOwner());
}

string phrase(string s, key id) {
    s = llReplaceSubString(s, "[toucher]", nameOf(id), 0);
    s = llReplaceSubString(s, "[owner]", ownerName(), 0);
    s = llReplaceSubString(s, "[sub]", pSub, 0);
    s = llReplaceSubString(s, "[obj]", pObj, 0);
    s = llReplaceSubString(s, "[pos]", pPos, 0);
    integer p = llSubStringIndex(s, "[s]");
    while (p != -1) {
        string rep = "'s";
        if (p > 0) {
            string prev = llGetSubString(s, p - 1, p - 1);
            if (prev == "s" || prev == "S") rep = "'";
        }
        s = llReplaceSubString(s, "[s]", rep, 1);
        p = llSubStringIndex(s, "[s]");
    }
    return s;
}

// ########## TRUSTED LIST (skip-consent regulars, consent ON only) ##########
// The trusted list lives ONLY in linkset data (CSV of keys), so up to 16
// keys never sit in script memory.
integer isTrusted(key id) {
    string csv = llLinksetDataRead(PREF_PREFIX + "trusted");
    if (csv == "") return FALSE;
    return llSubStringIndex("," + csv + ",", "," + (string)id + ",") != -1;
}

integer trustedCount() {
    string csv = llLinksetDataRead(PREF_PREFIX + "trusted");
    if (csv == "") return 0;
    return llGetListLength(llParseString2List(csv, [","], []));
}

addTrusted(key id) {
    if (id == NULL_KEY || id == llGetOwner() || isTrusted(id)) return;
    if (trustedCount() >= MAX_TRUSTED) {
        llOwnerSay("Trusted list is full - clear it before adding more.");
        return;
    }
    string csv = llLinksetDataRead(PREF_PREFIX + "trusted");
    if (csv == "") llLinksetDataWrite(PREF_PREFIX + "trusted", (string)id);
    else llLinksetDataWrite(PREF_PREFIX + "trusted", csv + "," + (string)id);
    llOwnerSay(nameOf(id) + " added to the trusted list.");
}

// ########## SETTINGS PERSISTENCE (LINKSET DATA) ##########
savePrefs() {
    llLinksetDataWrite(PREF_PREFIX + "sub", pSub);
    llLinksetDataWrite(PREF_PREFIX + "obj", pObj);
    llLinksetDataWrite(PREF_PREFIX + "pos", pPos);
    llLinksetDataWrite(PREF_PREFIX + "consent", (string)consentRequired);
    llLinksetDataWrite(PREF_PREFIX + "sounds", (string)gSoundsOn);
    llLinksetDataWrite(PREF_PREFIX + "parts", (string)gParticlesOn);
    llLinksetDataWrite(PREF_PREFIX + "count", (string)gCount);
    llLinksetDataWrite(PREF_PREFIX + "cname", gCustomName);
}

integer loadPrefs() {
    string s = llLinksetDataRead(PREF_PREFIX + "sub");
    if (s == "") return FALSE;
    pSub = s;
    pObj = llLinksetDataRead(PREF_PREFIX + "obj");
    pPos = llLinksetDataRead(PREF_PREFIX + "pos");
    consentRequired = (llLinksetDataRead(PREF_PREFIX + "consent") != "0");
    gSoundsOn = (llLinksetDataRead(PREF_PREFIX + "sounds") != "0");
    gParticlesOn = (llLinksetDataRead(PREF_PREFIX + "parts") != "0");
    gCount = (integer)llLinksetDataRead(PREF_PREFIX + "count");
    gCustomName = llLinksetDataRead(PREF_PREFIX + "cname"); // "" reads as unset
    return TRUE;
}

clearPrefs() {
    llLinksetDataDelete(PREF_PREFIX + "sub");
    llLinksetDataDelete(PREF_PREFIX + "obj");
    llLinksetDataDelete(PREF_PREFIX + "pos");
    llLinksetDataDelete(PREF_PREFIX + "consent");
    llLinksetDataDelete(PREF_PREFIX + "sounds");
    llLinksetDataDelete(PREF_PREFIX + "parts");
    llLinksetDataDelete(PREF_PREFIX + "count");
    llLinksetDataDelete(PREF_PREFIX + "cname");
    llLinksetDataDelete(PREF_PREFIX + "trusted");
    // Hover text is a prim property that outlives a script reset, so it must
    // be cleared here or a stale counter floats after a factory Reset.
    llSetText("", <1.0, 1.0, 1.0>, 0.0);
    gHoverUntil = 0;
}

// ########## LISTENER MANAGEMENT ##########
startListen(key who) {
    llListenRemove(gListen);
    gListen = llListen(comChannel, "", who, "");
}

// ########## CUSTOM NICKNAME (OWNER ONLY) ##########
// One-shot textbox on comChannel - 1, so free-text replies can never be
// mistaken for button presses. Cancelling the box sends nothing; the
// leftover listener is removed on the next open or reply.
openNameBox() {
    llListenRemove(gNameListen);
    gNameListen = llListen(comChannel - 1, "", llGetOwner(), "");
    llTextBox(llGetOwner(), "Type a nickname (blank = your display name):", comChannel - 1);
}

handleNameReply(string message) {
    llListenRemove(gNameListen);
    gNameListen = -1;
    string n = llStringTrim(message, STRING_TRIM);
    if (n == "") {
        gCustomName = "";
        llLinksetDataWrite(PREF_PREFIX + "cname", "");
        llOwnerSay("Nickname cleared - using your display name.");
        return;
    }
    gCustomName = llGetSubString(n, 0, 29); // cap at 30: display names max at 31
    llLinksetDataWrite(PREF_PREFIX + "cname", gCustomName);
    llOwnerSay("Nickname set: " + gCustomName);
}

// ########## TIMER ##########
// Blush decay + consent timeout + counter fade.
armTimer() {
    integer wait = 0;
    integer now = llGetUnixTime();
    if (gBlushOn) wait = 10;
    if (gPendingToucher != NULL_KEY) {
        integer remain = gPendingUntil - now;
        if (remain < 1) remain = 1;
        if (wait == 0 || remain < wait) wait = remain;
    }
    if (gHoverUntil != 0) {
        integer h = gHoverUntil - now;
        if (h < 1) h = 1;
        if (wait == 0 || h < wait) wait = h;
    }
    if (wait > 0) llSetTimerEvent(wait);
    else llSetTimerEvent(0);
}

clearPending() {
    gPendingToucher = NULL_KEY;
    gPendingMsg = "";
    gPendingAction = "";
    armTimer();
}

// Boop counter: floats briefly after each visitor action.
showCounter() {
    string plural = "s";
    if (gCount == 1) plural = "";
    llSetText(ownerName() + " has been booped " + (string)gCount + " time" + plural + "!", <1.0, 1.0, 1.0>, 1.0);
    gHoverUntil = llGetUnixTime() + HOVER_TIME;
    armTimer();
}

// ########## EFFECTS ##########
showHearts() {
    if (!gParticlesOn) return;
    list ps = [
        PSYS_PART_FLAGS,           PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN,          PSYS_SRC_PATTERN_EXPLODE,
        PSYS_PART_START_ALPHA,     1.0,
        PSYS_PART_END_ALPHA,       0.0,
        PSYS_PART_START_COLOR,     <1.0, 0.0, 0.0>,
        PSYS_PART_END_COLOR,       <1.0, 0.2, 0.2>,
        PSYS_PART_START_SCALE,     <0.05, 0.05, 0.0>,
        PSYS_PART_END_SCALE,       <0.3, 0.3, 0.0>,
        PSYS_PART_MAX_AGE,         2.0,
        PSYS_SRC_BURST_RATE,       0.1,
        PSYS_SRC_BURST_PART_COUNT, 8,
        PSYS_SRC_BURST_RADIUS,     0.2,
        PSYS_SRC_BURST_SPEED_MIN,  0.2,
        PSYS_SRC_BURST_SPEED_MAX,  0.5,
        PSYS_SRC_MAX_AGE,          0.6
    ];
    // Optional: the first texture in the contents shapes the burst.
    if (llGetInventoryNumber(INVENTORY_TEXTURE) > 0) ps += [PSYS_SRC_TEXTURE, llGetInventoryName(INVENTORY_TEXTURE, 0)];
    llParticleSystem(ps);
}

// Optional: an inventory sound named like the action button plays with it.
// Inventory name lookups are case-sensitive, so both sides are compared
// lowercased - a "kiss" item matches the Kiss button.
playActionSound(string actionName) {
    if (!gSoundsOn) return;
    integer count = llGetInventoryNumber(INVENTORY_SOUND);
    string wanted = llToLower(actionName);
    integer i;
    for (i = 0; i < count; ++i) {
        string item = llGetInventoryName(INVENTORY_SOUND, i);
        if (llToLower(item) == wanted) { llPlaySound(item, 1.0); return; }
    }
}

executeAction(string text, key toucher, string actionName) {
    string oldName = llGetObjectName();
    llSetObjectName(" ");
    llSay(PUBLIC_CHANNEL, "/me " + phrase(text, toucher));
    llSetObjectName(oldName);
    playActionSound(actionName);
    showHearts();
    gBlushOn = TRUE;
    llSay(BLUSH_CHANNEL, "blush|1.0");
    if (toucher != llGetOwner()) {
        // Visitor interaction: count it, flash the counter, start cooldown
        ++gCount;
        llLinksetDataWrite(PREF_PREFIX + "count", (string)gCount);
        showCounter();
        gLastVisitor = toucher;
        gLastUntil = llGetUnixTime() + TOUCH_COOLDOWN;
    }
    armTimer();
}

// Owner Help: gives the first notecard found in the contents, so any
// notecard name works.
giveHelp() {
    if (llGetInventoryNumber(INVENTORY_NOTECARD) > 0) {
        llGiveInventory(llGetOwner(), llGetInventoryName(INVENTORY_NOTECARD, 0));
    } else {
        llOwnerSay("No help notecard in the contents.");
    }
}

// ########## CONSENT ##########
requestConsent(key toucher, string actionName, string text) {
    if (gPendingToucher != NULL_KEY) {
        llRegionSayTo(toucher, 0, "One request at a time - try again in a moment.");
        return;
    }
    gPendingToucher = toucher;
    gPendingMsg = text;
    gPendingAction = actionName;
    gPendingUntil = llGetUnixTime() + CONSENT_TIMEOUT;
    armTimer();
    llRegionSayTo(toucher, 0, "Getting permission to " + llToLower(actionName) + " " + ownerName() + "...");
    llDialog(llGetOwner(), nameOf(toucher) + " wants to " + llToLower(actionName) + " you. Allow?", ["YES_ALLOW", "TRUST_ALLOW", "NO_DENY"], comChannel);
}

// Resolve an action button: cooldown check, then consent when required.
resolveAction(key id, string actionName) {
    if (id == gLastVisitor && id != llGetOwner() && llGetUnixTime() < gLastUntil) {
        llRegionSayTo(id, 0, "Easy there! Give it a few seconds.");
        return;
    }
    string text = textFor(gCurrentCat, actionName);
    if (text == "") return; // no category open, or stale/unknown button
    if (id == llGetOwner() || !consentRequired || isTrusted(id)) {
        executeAction(text, id, actionName);
        return;
    }
    requestConsent(id, actionName, text);
}

// ########## MENUS ##########
showCategoryMenu(key id) {
    list b = categoriesList;
    if (id == llGetOwner()) b += ["SETTINGS"];
    llDialog(id, "Pick a target area:", b, comChannel);
}

showSettingsMenu() {
    string cStatus = "Consent: ON";
    if (!consentRequired) cStatus = "Consent: OFF"; // buttons show the CURRENT state; pressing toggles it
    string sStatus = "Sounds: On";
    if (!gSoundsOn) sStatus = "Sounds: Off";
    string pStatus = "Particles: On";
    if (!gParticlesOn) pStatus = "Particles: Off";
    list b = ["Lock", "Pronouns", "Name", cStatus, sStatus, pStatus, "Manual Blush", "Help", "Reset", "BACK"];
    if (consentRequired) b += ["Trusted"]; // only meaningful while consent checks run
    llDialog(llGetOwner(), "Settings:", b, comChannel);
}

showTrustedMenu() {
    llDialog(llGetOwner(), "Trusted visitors skip permission checks (" + (string)trustedCount() + "/" + (string)MAX_TRUSTED + ").", ["Clear Trusted", "BACK"], comChannel);
}

showActionMenu(key id) {
    if (gCurrentCat < 0) return;
    string title = "Target Area: " + llList2String(categoriesList, gCurrentCat);
    llDialog(id, title, ["BACK"] + actionNames(gCurrentCat), comChannel);
}

openCategory(key id, integer cat) {
    gCurrentCat = cat;
    showActionMenu(id);
}

// ########## SHARED EVENT BODIES ##########
// Blush decay + counter fade.
blushAndHoverTick() {
    if (gBlushOn) {
        gBlushOn = FALSE;
        llSay(BLUSH_CHANNEL, "blush|0.0");
        llParticleSystem([]);
    }
    if (gHoverUntil != 0 && llGetUnixTime() >= gHoverUntil) {
        llSetText("", <1.0, 1.0, 1.0>, 0.0);
        gHoverUntil = 0;
    }
}

// Ground-rez notice: on_rez fires before attach on wear/login, but
// llGetAttached() is already nonzero then - so this only triggers grounded.
groundRezNotice() {
    if (llGetAttached() == 0) {
        llOwnerSay("The booper is meant to be worn, not left on the ground.");
    }
}

// Owner change = new owner starts from a clean slate.
ownerChangeReset() {
    clearPending();
    clearPrefs();
    llResetScript();
}

// ########## INITIAL SETUP RUN STATE ##########
default {
    state_entry() {
        comChannel = -(integer)(llFrand(999999999) + 1000000); // always negative, never channel 0
        startListen(llGetOwner());
        if (loadPrefs()) {
            llOwnerSay("All Purpose Booper configured and ready.");
            state Operational;
        }
        llOwnerSay("Running setup - please answer the dialog.");
        llDialog(llGetOwner(), "Booper setup\n\nStep 1 - your pronouns:", ["He/Him", "She/Her", "They/Them"], comChannel);
    }

    touch_start(integer num) {
        integer i;
        for (i = 0; i < num; ++i) {
            key k = llDetectedKey(i);
            if (k == llGetOwner()) {
                llDialog(k, "Setup pending - step 1: your pronouns:", ["He/Him", "She/Her", "They/Them"], comChannel);
            } else {
                llRegionSayTo(k, 0, "Still setting up - please wait.");
            }
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (id != llGetOwner()) return;

        if (message == "He/Him" || message == "She/Her" || message == "They/Them") {
            if (message == "He/Him")       { pSub = "he";   pObj = "him";  pPos = "his";   }
            else if (message == "She/Her") { pSub = "she";  pObj = "her";  pPos = "her";   }
            else                           { pSub = "they"; pObj = "them"; pPos = "their"; }
            llOwnerSay("Pronouns saved. Now, consent:");
            llDialog(llGetOwner(), "Step 2 - approve interactions before they happen?\n\n(Yes = an Allow dialog for each action.)", ["Consent ON", "Consent OFF"], comChannel);
            return;
        }

        if (message == "Consent ON" || message == "Consent OFF") {
            if (message == "Consent ON") {
                consentRequired = TRUE;
                llOwnerSay("Consent on - you approve each action.");
            } else {
                consentRequired = FALSE;
                llOwnerSay("Consent off - actions play right away.");
            }
            savePrefs();
            llOwnerSay("Setup complete!");
            state Operational;
        }
    }

    on_rez(integer param) {
        groundRezNotice();
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) ownerChangeReset();
    }
}

// ########## MAIN OPERATIONAL LOGIC STATE ##########
state Operational {
    state_entry() {
        comChannel = -(integer)(llFrand(999999999) + 1000000);
        startListen(NULL_KEY); // one persistent handle; every privileged branch checks id
        gCurrentCat = -1;
        llParticleSystem([]);
    }

    touch_start(integer num) {
        key owner = llGetOwner();
        integer i;
        for (i = 0; i < num; ++i) {
            key k = llDetectedKey(i);
            if (k == owner || llVecDist(llDetectedPos(i), llGetPos()) <= TOUCH_RANGE) {
                showCategoryMenu(k);
            }
        }
    }

    listen(integer channel, string name, key id, string message) {
        key owner = llGetOwner();

        // --- Nickname textbox replies: OWNER ONLY (one-shot on comChannel - 1) ---
        if (channel == comChannel - 1) { handleNameReply(message); return; }

        // --- Consent replies: OWNER ONLY ---
        if (message == "YES_ALLOW" || message == "TRUST_ALLOW" || message == "NO_DENY") {
            if (id != owner || gPendingToucher == NULL_KEY) return;
            if (message == "NO_DENY") {
                llRegionSayTo(gPendingToucher, 0, ownerName() + " said no to that one.");
                clearPending();
                return;
            }
            key t = gPendingToucher;
            string txt = gPendingMsg;
            string act = gPendingAction;
            clearPending();
            if (message == "TRUST_ALLOW") addTrusted(t);
            executeAction(txt, t, act);
            return;
        }

        // --- Settings: OWNER ONLY ---
        if (id == owner) {
            if (message == "SETTINGS")     { showSettingsMenu(); return; }
            if (message == "Name")         { openNameBox(); return; }
            if (message == "Help")         { giveHelp(); return; }
            if (message == "Trusted")     { if (consentRequired) showTrustedMenu(); return; }
            if (message == "Clear Trusted") {
                if (consentRequired) {
                    llLinksetDataDelete(PREF_PREFIX + "trusted");
                    llOwnerSay("Trusted list cleared.");
                    showTrustedMenu();
                }
                return;
            }
            if (message == "Consent: ON")  { consentRequired = FALSE; savePrefs(); llOwnerSay("Consent off - actions play right away."); showSettingsMenu(); return; }
            if (message == "Consent: OFF") { consentRequired = TRUE;  savePrefs(); llOwnerSay("Consent on - you approve each action."); showSettingsMenu(); return; }
            if (message == "Sounds: On")   { gSoundsOn = FALSE;    savePrefs(); llOwnerSay("Sounds off.");   showSettingsMenu(); return; }
            if (message == "Sounds: Off")  { gSoundsOn = TRUE;     savePrefs(); llOwnerSay("Sounds on.");    showSettingsMenu(); return; }
            if (message == "Particles: On")   { gParticlesOn = FALSE; savePrefs(); llOwnerSay("Particles off."); showSettingsMenu(); return; }
            if (message == "Particles: Off") { gParticlesOn = TRUE;  savePrefs(); llOwnerSay("Particles on.");  showSettingsMenu(); return; }
            if (message == "He/Him")       { pSub = "he";   pObj = "him";  pPos = "his";   savePrefs(); llOwnerSay("Saved: He/Him.");    return; }
            if (message == "She/Her")      { pSub = "she";  pObj = "her";  pPos = "her";   savePrefs(); llOwnerSay("Saved: She/Her.");   return; }
            if (message == "They/Them")    { pSub = "they"; pObj = "them"; pPos = "their"; savePrefs(); llOwnerSay("Saved: They/Them."); return; }
            if (message == "Pronouns")    { llDialog(id, "Choose your pronouns:", ["He/Him", "She/Her", "They/Them"], comChannel); return; }
            if (message == "Manual Blush") {
                showHearts();
                gBlushOn = TRUE;
                llSay(BLUSH_CHANNEL, "blush|1.0");
                armTimer();
                llOwnerSay("Blush test fired.");
                return;
            }
            if (message == "Reset") { clearPending(); clearPrefs(); llResetScript(); return; } // full factory reset
            if (message == "Lock")  { clearPending(); state Locked; return; }
        }

        // --- Navigation ---
        if (message == "BACK") { showCategoryMenu(id); return; }

        // --- Category selection ---
        integer catIdx = llListFindList(categoriesList, [message]);
        if (catIdx != -1) { openCategory(id, catIdx); return; }

        // --- Action resolution ---
        resolveAction(id, message);
    }

    timer() {
        llSetTimerEvent(0);
        blushAndHoverTick();
        if (gPendingToucher != NULL_KEY && llGetUnixTime() >= gPendingUntil) {
            llRegionSayTo(gPendingToucher, 0, "No answer from " + ownerName() + " - try again later.");
            clearPending();
        }
        armTimer();
    }

    on_rez(integer param) {
        groundRezNotice();
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) ownerChangeReset();
    }
}

// ########## SECURITY LOCKED STATE ##########
state Locked {
    state_entry() {
        llParticleSystem([]);
        clearPending();
        llOwnerSay("Booper locked.");
        startListen(llGetOwner());
    }

    touch_start(integer num) {
        integer i;
        for (i = 0; i < num; ++i) {
            key k = llDetectedKey(i);
            if (k == llGetOwner()) {
                llDialog(k, "Booper is locked:", ["Unlock", "Reset"], comChannel);
            } else {
                llRegionSayTo(k, 0, "Sorry - the booper is locked right now.");
            }
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (id != llGetOwner()) return;
        if (message == "Unlock") { state Operational; return; } // settings are retained
        if (message == "Reset")  { clearPrefs(); llResetScript(); return; }
    }

    timer() {
        llSetTimerEvent(0);
        blushAndHoverTick();
        armTimer();
    }

    on_rez(integer param) {
        groundRezNotice();
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) ownerChangeReset();
    }
}
