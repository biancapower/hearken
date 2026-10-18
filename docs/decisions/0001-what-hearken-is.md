# 0001. What Hearken is

**Context.** Bianca listens to podcasts daily in AntennaPod, including explainer feeds they produce for their own learning, and has standing complaints with it. A planning decision on 2026-10-18 chose a Rails-backed PWA player as their second project over forking AntennaPod, which is a large Java and Kotlin codebase off both of their stacks. A feasibility spike the same day built a throwaway player and found every in-browser part workable, including offline seeking; Bianca used it installed on their Android phone and asked to build the real thing.

**Decision.** Hearken is a podcast player for your own audio and feeds.

- **Own feeds first.** It plays feeds and audio the user controls. Other sources, such as public podcast directories or general feed import, may come later; Hearken is not positioned as a general podcast client. Bianca, 2026-10-18: "as a public project, I think it'd be fine to position it just as something that is used for your own audio files. At least at first, I can always consider adding ability to import other audio sources later if I wanted to."
- **One user first.** A single account with a real login. More users later, which is when feed URLs entered by users need the private-address checks in `CLAUDE.md`.
- **Self-hosted.** The server runs on hardware the user controls; listening state lives on that server, not only on the phone. Nothing is public-facing in 0.1.0: it runs on Bianca's own machine, reachable over their tailnet.
- **Release 0.1.0** is done when Hearken replaces AntennaPod for Bianca's own feeds on the tailnet.

**Non-goals, for now.** A directory or search of public podcasts. A hosted service for others. A native Android or iOS app (a trusted web activity wrapper is the fallback only if background playback on Android proves unreliable). Multiple users. Recommendations or anything social.

**Roadmap.** What Bianca wants from it, in the order they raised it.

The three original wants, each something AntennaPod does badly or not at all:

1. **Notes while listening.** Mark a moment and write a note against it, kept with its timestamp and the transcript lines around it, in a form Claude can read later to pull out what is actionable (things to write about, read, or correct).
2. **A synced transcript beside the controls.** The current line highlighted as it is spoken, on the same screen as pause and skip.
3. **Sleep-timer control.** Stop after a chosen episode in the queue, after a number of episodes, or after a number of minutes.

The four later features:

4. **A gap or sting between episodes.** Seconds of silence, an audio clip, or both, set in the player, so the change of episode is audible without editing the episodes.
5. **Listening state that survives feed changes.** Played state, resume position and queue place are kept server-side against a stable episode identity, so a replaced or retitled episode keeps them.
6. **Every play is a record.** Episode, start, end and device for each play, so re-listens count, devices stay in sync, and listening history can be exported for a journal or shown as stats.
7. **Tags on episodes.** Imported from feed categories, inherited from the podcast, or assigned by the user, as the basis for tracking topics.

Also recorded: a follow-up list of sources cited in episodes, with listened state.

**Alternatives.** Forking AntennaPod; a general podcast client from the first release; staying on AntennaPod. All set aside in the planning decision for the reasons above.

**Reasons.** Bianca uses a podcast player daily, so the project is used as it is built. Rails is their first-preference stack. The three wants are ordinary server-and-page features in a Rails app, while in AntennaPod they land where upstream churns. Scoping to one's own feeds keeps the first release small.

**Consequences.** The biggest open risk is Android itself: background playback past thirty minutes with the screen off, which lock-screen and headset actions arrive, storage eviction, and battery use against AntennaPod. The spike could not measure these; an endurance pass on Bianca's phone is early work.

**Status.** Drafted by Claude on 2026-10-18 from the planning decision (approved by @biancapower, 2026-10-18) and Bianca's recorded feature list; awaiting @biancapower's read.
