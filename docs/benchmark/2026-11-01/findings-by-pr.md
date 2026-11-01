# Findings by PR: severity, cost of a miss, and who caught each one

Every distinct finding any of the three reviewers posted on the five replayed PRs, live
(2026-10-31, kaipu-record) or in replay (2026-11-01). One table per PR, ordered by severity.

**Runs counted.** Wachiman: live v1.2.0 + three v1.3.0 replays = 4 runs. Pullfrog: live + one
fresh replay = 2 runs. CodeRabbit: one replay = 1 run. A cell reads "k/n": found in k of n runs.

**Severity** is this benchmark's judgment of what the bug does to a user, not the reviewer's own
label:

| Severity | Meaning |
| --- | --- |
| High | The user loses data, or the app shows a wrong result with no warning. |
| Medium | Visible wrong behaviour the user can notice and work around. |
| Low | Accessibility, cosmetics, or a weak test that would let a later bug through. |
| Info | Comments, docs, leftovers. No runtime effect. |

**Verified** means checked against the code at the head (all live findings, on 2026-10-31) or
fixed by the author afterwards. Replay-only findings are **not verified**: their severity and
"if missed" text are inferred from the finding itself, and some may turn out invalid.

**The cost of a catch.** Missing a High or Medium bug ships it. Catching only Low and Info items
costs too: a review with fifteen of them buries the one that matters, and the reader learns to
skim. A reviewer is worth what it catches at the top of these tables, every run.

## #463: camera off and on mid-take keeps the face in its own track

| Finding | Kind | Severity | If missed | Wachiman | Pullfrog | CodeRabbit | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Camera cannot reopen → the face is recorded nowhere | bug | **High** | The take finishes with no face track and no error; the face from that point on is lost | 2/4 | 0/2 | 0/1 | yes, fixed in `b0f028c` |
| A superseded re-open closes the camera gap too early | bug | **Medium** (inferred) | The gap marker ends before the camera is really back, so the timeline is wrong around the toggle | 0/4 | 1/2 | 0/1 | fixed by the author in `8609fab` |
| Random gap ids break the Share fingerprint | bug | **Medium** | Sharing the same take again does not reuse the earlier upload | 0/4 | 2/2 | 0/1 | yes, fixed in `29395c3` |
| Late-frame "dropped and closed" path never tested | tests | Low | A later change to that path breaks it silently | 4/4 | 0/2 | 0/1 | yes |
| Hub-reset test name only exercises abort | tests | Low | Same, for the reset path | 2/4 | 0/2 | 0/1 | yes |
| "off" comment says it waits on the queue; it does not | docs | Info | Misleads the next reader | 3/4 | 0/2 | 0/1 | yes |
| `releaseAll` JSDoc now sits on `releaseWebcam` | docs | Info | Same | 3/4 | 0/2 | 0/1 | no |

## #464: ready copy shows up in the Library; minimizable export widget

| Finding | Kind | Severity | If missed | Wachiman | Pullfrog | CodeRabbit | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Card's Show in Finder and drag skip `markCopySeen` | bug | **Medium** | The "ready" card keeps showing after the user already used the file | 0/4 | 1/2 | **1/1** | yes |
| Ready cards retired before anyone saw them (list view, filter) | bug | **Medium** | The user never gets told the copy is ready | 1/4 | 0/2 | 0/1 | yes |
| Copy loses Edit / Prepare / Tags / Delete while its ready card shows | bug | Medium (inferred) | The user cannot act on the copy until the card goes away | 1/4 | 0/2 | 0/1 | no |
| Pill `aria-label` hides the progressbar | a11y | Low | Screen-reader users cannot follow export progress | 2/4 | 2/2 | 0/1 | yes |
| Card accessible names hide the destination | a11y | Low | Screen-reader users hear the same name on every card | 0/4 | 0/2 | 1/1 | no |
| "…and forgets it" test never checks the forget | tests | Low | A regression in forgetting passes CI | 1/4 | 0/2 | 0/1 | no |

## #465: recording detail, destinations strip, copies from this original

| Finding | Kind | Severity | If missed | Wachiman | Pullfrog | CodeRabbit | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- |
| New drag handle skips `markCopySeen` | bug | **Medium** | Same as #464: the ready notice stays after the user dragged the file out | 0/4 | 1/2 | 0/1 | yes |
| An unreadable file leaves every card's size at "…" | bug | Low (inferred) | Sizes never load for the whole strip, not just the broken file | 1/4 | 0/2 | 0/1 | no |
| Library-detail bottom panel flickers before the re-list | bug | Low (inferred) | A visible flash when the first copy finishes | 0/4 | 1/2 | 0/1 | no |
| Drag test replaces the shared `electronAPI` stub and never restores it | tests | Low | Later tests run against the wrong stub and can pass or fail for the wrong reason | 4/4 | 0/2 | 0/1 | yes |
| "Open in Export" test never checks the absent case | tests | Low | A regression in the absent case passes CI | 4/4 | 0/2 | 0/1 | yes |
| Archive card's accessible name reads "Export a copy for Archive copy" | a11y | Low | A confusing label for screen-reader users | 1/4 | 0/2 | 0/1 | no |
| QA doc says to drag the row; only the Drag button drags | docs | Info | A tester reports a false bug | 1/4 | 0/2 | 0/1 | no |

## #466: float "Your video is ready" outside the app window

| Finding | Kind | Severity | If missed | Wachiman | Pullfrog | CodeRabbit | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Back re-shows the always-on-top card | bug | **Medium** | A dismissed card floats again over every other app | 0/4 | 1/2 | 0/1 | yes |
| The card can fail to load and is then lost for the session (`show()` returns `true` before it can paint; a rejected `loadURL` is unhandled) | bug | **Medium** | The user never sees "ready" again until they restart the app | 1/4 | 0/2 | 1/1 | yes (Wachiman's live wording) |
| Reused hidden window can flash the previous recording's card | bug | Low (inferred) | The wrong video's card shows for a moment | 2/4 | 0/2 | 0/1 | no |
| `recording-ready:show` accepts any renderer | security | Low | Any renderer, including a compromised one, can open an always-on-top window | 2/4 | 0/2 | 0/1 | yes |
| Card shadow clipped by the 16 DIP window padding | cosmetic | Low | The card looks cut at its edges | 0/4 | 2/2 | 0/1 | yes |
| Test name says Edit-first is ignored; the test asserts it closes | tests | Low | The next reader trusts the wrong behaviour | 1/4 | 0/2 | 0/1 | no |
| Docstring says the card closes on leaving the page; the floating window does not | docs | Info | Misleads the next reader | 3/4 | 0/2 | 0/1 | no |

## #467: Export screen with its own rail entry (replaces Prepare)

| Finding | Kind | Severity | If missed | Wachiman | Pullfrog | CodeRabbit | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A file dropped on the Library navigates the Electron window to `file://` (no `will-navigate` guard) | bug | **High** (inferred) | The app's own window is replaced by the dropped file; the user loses the screen they were on | 0/4 | 1/2 | 0/1 | no |
| Export never re-lists the Library when an export finishes | bug | **Medium** | The new copy does not appear in the Library until something else refreshes it | 0/4 | 1/2 | 0/1 | yes |
| "Pick from Library" enabled while importing | bug | **Medium** | A second pick races the import in progress | 3/4 | 0/2 | 0/1 | yes |
| A finished Email export is listed as "Chat" in Recent exports | bug | Medium (inferred) | The user sees the wrong destination for a finished export | 2/4 | 0/2 | 0/1 | no; noticed by hand on 10-31 |
| GitHub size bar label omits fits / over | a11y | Low | Screen-reader users cannot tell whether the file fits | 2/4 | 0/2 | 0/1 | yes |
| Picker `role="dialog"` without focus management | a11y | Low | Keyboard focus is left behind the dialog | 2/4 | 0/2 | 0/1 | yes |
| Library drop test passes either way | tests | Low | The drop can break with CI green | 4/4 | 0/2 | 0/1 | yes |
| Sidebar "with and without a video" tests one case | tests | Low | Half the behaviour is untested | 4/4 | 0/2 | 0/1 | yes |
| Badge "in progress" count untested | tests | Low | A wrong count passes CI | 1/4 | 0/2 | 0/1 | yes |
| Running row shows the title where finished rows show the destination | cleanup | Low | An inconsistent list | 1/4 | 0/2 | 0/1 | yes |
| `EXPORT_ORDER` can silently miss a destination | cleanup | Low | A future destination is left out of the list | 1/4 | 0/2 | 0/1 | no |
| Orphaned CSS comment for the removed drop strip | cleanup | Info | Dead text | 4/4 | 1/2 | 0/1 | yes |
| CSS comment calls 900×670 the default; it is the minimum | docs | Info | Misleads the next reader | 1/4 | 0/2 | 0/1 | no |

## What the tables say

| Severity | Distinct findings | Wachiman caught at least once | Pullfrog | CodeRabbit | Caught in every run by anyone |
| --- | --- | --- | --- | --- | --- |
| High | 2 | 1 | 1 | 0 | none |
| Medium | 11 | 5 | 6 | 2 | Pullfrog's Share ids (2/2) |
| Low | 21 | 18 | 3 | 1 | Wachiman's tests (4/4), Pullfrog's pill and shadow (2/2) |
| Info | 6 | 6 | 1 | 0 | Wachiman's CSS comment (4/4) |

1. **No bug of severity Medium or higher was caught in every run, except one** (Pullfrog's random
   ids, 2 of 2). Everything a user would feel is found *sometimes*. This is the number the next
   version has to move.
2. **Wachiman's reliable output is Low and Info.** Its stable core (4 of 4) is tests and
   leftovers. Useful, but it is the part of a review a user can afford to lose.
3. **The two High findings were each found once**, by different reviewers, and the newer one
   (`file://` navigation) is still unverified.
4. **CodeRabbit is quiet but not empty.** Two of its three findings are Medium bugs another
   reviewer also found: `markCopySeen` on #464 (Pullfrog's live catch) and the card lost for the
   session on #466 (Wachiman's live catch).
5. **Next step:** verify the 15 unverified rows against the code at the head, then add a run to
   every column: Pullfrog and CodeRabbit in their
   [v2](https://github.com/niway-dev/kaipu-bench-pullfrog-v2) [repositories](https://github.com/niway-dev/kaipu-bench-coderabbit-v2),
   Wachiman on a new `head-r4` branch.
