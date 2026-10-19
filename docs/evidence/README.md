# V2 frontend state source (real DSH)

Extracted from the temporary debug marker `[PET:<phase>]` set by the V2 client
component while reading `ctx.sessions.binding(sessionId).eventSource`.
This proves the frontend transient stream is live and session-bound.

Sequence observed around real turns:

```text
thinking
tool
requesting
thinking
tool
idle
requesting
thinking
tool
... (repeats)
```

The final component uses the same `phaseOf()` mapping; the debug title marker
and test badge are not part of the shipped component.

Visual evidence:

- `v2-right-idle-composer.png`: front idle, no computer, feet on the
  composer's top edge at its right side.
- `v2-right-thinking-frames.png`: front idle, then the side pose with the
  gray line laptop at the right edge, then front idle again.
- `preview-light.png` / `preview-dark.png`: material transparency and contrast.
