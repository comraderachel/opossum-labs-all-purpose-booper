# Opossum Labs All Purpose Booper

An open source head interaction script for Second Life furry avatars, licensed
under the GNU GPL v3. Wear it on your head, and anyone who clicks gets a menu
full of boops, pets, smooches, and more.

This repo has everything you need to drop the script into your own object and
make your own booper. No assets or notecards required, just the script.

## What it does

- 42 actions across seven target areas: Forehead, Nose, Ears, Cheeks,
  Muzzle, Lips, and Neck
- Pronoun support for the wearer (He/Him, She/Her, They/Them); toucher text
  stays gender-neutral
- Text tags you can build phrases from: [toucher], [owner], [sub], [obj],
  [pos], [s]
- Consent system: the owner approves each visitor action, with a 30 second
  timeout, one request at a time, and a trusted list that skips the check
- Boop counter with hover text, saved across re-rezzes
- A short cooldown so one visitor cannot spam actions
- Optional sounds: put a sound in the object's contents named the same as a
  button (capitalization does not matter) and it plays with that action
- Optional particles: the first texture in the contents shapes the heart burst
- Blush relay on channel 88 (it says `blush|1.0` / `blush|0.0`) for mesh heads
  that can react
- All settings persist in linkset data, so re-rezzing keeps them

## Make your own booper

1. Open your object's contents and make a New Script.
2. Delete the default text, paste in `all-purpose-booper.lsl`, and Save.
   A brand new script compiles as Mono, which this needs. If you paste into a
   very old script slot and get a Stack-Heap Collision, make a fresh New
   Script instead of reusing the old one.
3. Wear the object on your head (an attachment, a hat, a hairpin, whatever
   works).
4. First run walks the owner through pronouns and whether to approve each
   interaction before it happens.
5. Touch the booper. Visitors pick a target area, then an action. Owners get
   a SETTINGS button on the same menu.

The owner settings menu: Lock, Pronouns, Consent, Sounds, Particles, Manual
Blush, Help, Reset, and Trusted (shown while consent checks are on). The Help
button hands over the first notecard it finds in the contents, so any
notecard name works.

## Limits worth knowing

- One Mono script, 64 KB budget. The current feature set fits with a few KB of
  headroom, so test in-world before piling on new features.
- One action category is open at a time, shared between visitors. Two people
  clicking at the same moment can end up in the same category menu.
- The script ships with no sounds or textures. Bring your own.

## License

GPL-3.0. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the LICENSE file for details. Keep the
code open if you share or modify it.

A pre-assembled booper, with a full help notecard, is sold at the Opossum Labs
store in Second Life. Support: rachel.possum (in-world).
