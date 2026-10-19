window.__ModuleLoader__.load({
  id: "dsh-claude-pet",
  factory: (require) => {
    var module = { exports: {} };
    var exports = module.exports;
    Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
    const React = require("react");
    const inject = ["slots", "sessions"];
    const h = React.createElement;

    const IMAGES = {
      idle: "__IDLE__",
      rest: "__REST__",
      left: "__LEFT__",
      right: "__RIGHT__"
    };
    const CYCLE = [IMAGES.rest, IMAGES.left, IMAGES.rest, IMAGES.right];

    function hasText(value) {
      return typeof value === "string" && /\S/.test(value);
    }

    /**
     * Read only the current Session's transient assistant stream. The event
     * source is the same per-session feed the conversation UI consumes, so
     * stale events from other sessions cannot cross into this component.
     */
    function phaseOf(entries) {
      for (let i = entries.length - 1, checked = 0; i >= 0 && checked < 240; i--, checked++) {
        const entry = entries[i];
        const event = entry && entry.event;
        if (!event) continue;
        if (event.type === "assistant/live-chunk") {
          const chunk = event.data && event.data.chunk;
          if (!chunk) continue;
          switch (chunk.type) {
            case "reasoning-delta":
              if (hasText(chunk.text)) return "thinking";
              continue;
            case "block-start":
              if (chunk.blockType === "reasoning") return "thinking";
              continue;
            case "text-delta":
              if (hasText(chunk.text)) return "responding";
              continue;
            case "tool-call-delta":
              return "tool";
            case "finish":
              return "finishing";
            default:
              continue;
          }
        }
        switch (event.type) {
          case "turn/start":
          case "step/start":
          case "request/header":
            return "requesting";
          case "turn/end":
          case "step/end":
          case "assistant/message":
          case "assistant/attempt":
            return "idle";
          case "approval/asked":
            return "waiting";
          case "approval/decided":
          case "tool/call":
          case "tool/result":
            return "tool";
          default:
            break;
        }
      }
      return "idle";
    }

    function Pet(props) {
      const sessionId = props.sessionId;
      const sessions = props.sessions;
      const [state, setState] = React.useState({ phase: "idle", at: 0 });
      const [frame, setFrame] = React.useState(0);
      const [reduced] = React.useState(() => {
        try {
          return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
        } catch (error) {
          return false;
        }
      });

      React.useEffect(() => {
        let disposed = false;
        let off = null;
        let retry = null;
        const attach = () => {
          if (disposed) return;
          let binding;
          try {
            binding = sessionId ? sessions.binding(sessionId) : undefined;
          } catch (error) {
            binding = undefined;
          }
          if (!binding || !binding.eventSource) {
            setState({ phase: "idle", at: Date.now() });
            retry = window.setTimeout(attach, 500);
            return;
          }
          const source = binding.eventSource;
          const update = () => {
            if (disposed) return;
            const snapshot = source.getSnapshot();
            const entries = snapshot && Array.isArray(snapshot.entries) ? snapshot.entries : [];
            setState({ phase: phaseOf(entries), at: Date.now() });
          };
          update();
          off = source.subscribe(update);
        };
        attach();
        return () => {
          disposed = true;
          if (retry !== null) window.clearTimeout(retry);
          if (off) off();
        };
      }, [sessionId, sessions]);

      // A lost bridge/stream must never leave the pet typing forever.
      React.useEffect(() => {
        if (state.phase !== "thinking" && state.phase !== "responding" && state.phase !== "tool" && state.phase !== "waiting" && state.phase !== "requesting") return undefined;
        const timer = window.setTimeout(() => setState({ phase: "idle", at: Date.now() }), 6000);
        return () => window.clearTimeout(timer);
      }, [state.phase, state.at]);

      React.useEffect(() => {
        if (state.phase !== "thinking" || reduced) {
          setFrame(0);
          return undefined;
        }
        const timer = window.setInterval(() => setFrame((value) => (value + 1) % CYCLE.length), 140);
        return () => window.clearInterval(timer);
      }, [state.phase, reduced]);

      const thinking = state.phase === "thinking";
      const src = thinking ? (reduced ? IMAGES.rest : CYCLE[frame % CYCLE.length]) : IMAGES.idle;
      return h("div", {
        "data-dsh-claude-pet": "",
        "data-phase": state.phase,
        "aria-hidden": "true",
        style: {
          position: "absolute",
          right: "4px",
          top: "0px",
          width: "56px",
          height: "40px",
          transform: "translateY(-100%)",
          pointerEvents: "none",
          userSelect: "none",
          zIndex: 30,
          lineHeight: 0
        }
      }, h("img", {
        src,
        alt: "",
        draggable: false,
        "aria-hidden": "true",
        style: {
          display: "block",
          width: "56px",
          height: "40px",
          imageRendering: "pixelated",
          pointerEvents: "none"
        }
      }));
    }

    function apply(ctx) {
      try {
        // One-time migration cleanup for the development/test overlays that
        // may still be mounted by an already-running renderer. Production
        // pages have neither selector, so this is a no-op there.
        if (!window.__dshClaudePetLegacyClean) {
          window.__dshClaudePetLegacyClean = true;
          const style = document.createElement("style");
          style.textContent = "[data-claude-pet-debug],[data-claude-pet-test]{display:none!important}";
          document.head.appendChild(style);
          const strip = () => {
            const next = document.title.replace(/ \[PET:[^\]]*\]/g, "").replace(/ \[FINALAPPLY\]/g, "");
            if (next !== document.title) document.title = next;
          };
          strip();
          const title = document.querySelector("title");
          if (title) new MutationObserver(strip).observe(title, { childList: true, subtree: true, characterData: true });
        }
        ctx.slots.inject("conversation.input.overlay", () => ctx.slots.register({
          name: "conversation.input.overlay",
          id: "dsh-claude-pet",
          order: 10
        }, (props) => h(Pet, { ...props, sessions: ctx.sessions })));
      } catch (error) {
        console.error("[dsh-claude-pet] registration failed", error);
      }
    }

    exports.apply = apply;
    exports.inject = inject;
    exports.name = "dsh-claude-pet";
    return module.exports;
  }
});
