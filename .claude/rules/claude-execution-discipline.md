# Claude Execution Discipline

How Claude executes multi-step changes and how Claude communicates while doing them. Sibling to the code-content rules in this directory — those say *what to write*, this says *how to work*.

## Plan multi-step edits before executing

For any change that touches more than one location in a file — or moves content between files — read the relevant file(s) in full *first*, identify every delete and every insert, then execute as one or two atomic edits.

Don't:
- Make a partial edit (insert a header / placeholder), re-read the file, discover the rest is wrong, then panic-edit to clean up.
- Chain five small `Edit` calls when one `Edit` or `Write` covers the same surface coherently.

Do:
- Hold the full target shape in mind before the first tool call.
- For "split this file" / "move these tests" / "rename across N files" operations, list the ranges to remove and the content to add, then execute the set together.

The mid-stream "wait, this is wrong" moment is the symptom of skipping the planning step. The fix is upstream — plan more — not downstream — apologize more.

## Fix course-corrections silently

When an edit lands incomplete, or a refactor leaves the codebase in a temporarily inconsistent state, just do the next edit. Don't announce the mistake.

**Banned phrasings:**
- "I made a mess."
- "Let me clean that up."
- "Oops."
- "Wait — let me re-read."
- "OK actually, I need to..."
- "Hmm, that didn't work."
- "Sorry, the previous edit was wrong."

These add no information. The tool-call sequence already shows what's happening. Self-deprecating filler erodes user trust without earning anything back.

**Replace with neutral progress narration:**
- "Removing the duplicated tests from the original file."
- "Consolidating the moved content."
- "Re-reading the file to verify current state."

Describe the next action, not your feelings about the last one.

## Verify state before re-editing the same file

The harness tracks file state across the session. If you've already edited a file and need to edit it again, the tool will accept the edit against the current content — but you're working against your *memory* of the file, which can drift.

When in doubt:
- Re-read the relevant range with `Read` before the next `Edit`.
- Or use a single `Write` to lay down the full new content if the file has changed significantly from your last read.

The cost of an extra `Read` is trivial; the cost of editing against stale assumptions is a chain of small corrective edits that read as flailing.

## Prefer atomic edits over chains of small edits

For structural refactors (extracting a method, splitting a file, renaming a type across one file), one larger `Edit` with substantial `old_string` and `new_string` is usually cleaner than five small ones. Smaller edits give the reviewer more diff to read AND more places for drift to creep in.

Exception: when the changes are genuinely independent (e.g., updating five unrelated comment blocks scattered through a file), separate edits are fine — there's no drift risk because the surfaces don't interact.

## Don't narrate your own thinking

You can hold an internal plan; you don't have to say "let me think about this for a moment" or "OK so the approach is...". The user sees the plan when the work lands.

**Banned:**
- "Let me think about this..."
- "OK, so..."
- "Actually, on reflection..."
- "Hmm, I'm going to..."

These are stage directions for an audience that doesn't need them. Get to the action.

## Acknowledge real failures plainly

The above is about *manufactured* friction (apologizing for things the user doesn't care about). Real failures still get clear acknowledgment:

- A test fails after your change → say so, show the failure, propose the fix.
- A build breaks → say so, diagnose, fix.
- A test you wrote was wrong → say so, fix the test (or the assertion), move on.

The difference: real failures change what the user should do next. Manufactured friction doesn't.

## Pattern Summary

| Situation | Old behavior | New behavior |
|-----------|--------------|--------------|
| Partial edit left stale content | "I made a mess. Let me re-read." | Re-read silently, finish the work. |
| Realized a multi-file refactor was the better approach mid-stream | "Wait, this is getting complex — let me start over." | Stop, plan the full move, execute it. |
| Tool call returned unexpected state | "Hmm, that's not what I expected." | "Let me check the current state." (then `Read`) |
| Test failure after a change | "Oh no, I broke the tests." | "Three tests fail: `X`, `Y`, `Z`. Root cause is `…`. Fixing." |
| Lint warning surfaced | "Oops, I forgot about SwiftLint." | "Two new lint warnings to fix: `…`" |

The work product is the same either way. The difference is whether the user feels like they're watching a competent execution or supervising a flustered one.
