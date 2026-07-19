# Wave State — Snapshot, Not Doctrine

**This file is a snapshot from the session date below. It is not verified truth as of today.**

Before using anything here to draft or price a market: re-check the live market count via `/api/markets`, and independently re-search every fact attached to a queue idea. Nothing in this file should be cited as current without a fresh check — that's true even if it was true when written. This file exists so a session has a starting point for "what were we last thinking," not so it can skip verification.

If this file is more than ~7 days old relative to today's session, treat everything below as historical context only — don't act on it before re-verifying.

---

## Last Known Wave State

**Session date:** 2026-07-11
**Wave:** WAFCON 2026 confirmed by CAF for 25 Jul–16 Aug (Morocco, 16 teams, Rabat/Casablanca/Fez). Mixed-pillar wave staged this session, see below.
**Markets live (as of prior session, 2026-07-09):** 24 — **not re-pulled this session, re-derive from `/api/markets` before trusting.**
**Category balance (as of prior session):** sports_football heavily over-represented (~95%); macroeconomy, entertainment, fx_crypto, african_internet, politics under-represented.

---

## Approved, pending creation (2026-07-11 session)

Three markets fully drafted, priced, and operator-approved this session. Full detail (questions, resolution criteria, frozen Google Trends Topic IDs, extraction protocol) lives in `C:\Dev\Kasiro\kasiro-next-wave-mixed-pillar.md` (Rev 3) — treat that as the source of truth, this is a pointer, not a duplicate.

| Market | Mechanics | Opening price / seed weights | Status |
|---|---|---|---|
| Parklive Jozi artist attention battle (Nasty C / Matthew Mole / Rowlene) | Parimutuel | 55 / 23 / 22 | **Draft** in admin — blocked on `source_check` gate (see Key Learnings in markets.md), not yet published |
| Comic Con Africa attendance ≥70,000 (final post-event only) | AMM | 0.50 YES | **Live** — id `6398fd8f-d2e8-4b32-a5e1-f2fecd7851d5`, published 2026-07-11 |
| Attention Wars (Big Brother Naija / Tyla / WAFCON) | Parimutuel | 45 / 30 / 25 | **Draft** in admin — same `source_check` blocker as Parklive |

All three seed weights/opening prices are oracle-matched historical Google Trends priors (same geo/category/search-type/Topic IDs as the settlement query), compressed toward equal weighting for event-window volatility — not claimed true probabilities. Comic Con is live; Parklive and Attention Wars remain drafts pending a fix or workaround for the Trends source-URL gate failure — re-check `/api/admin/markets` (status field) before trusting this table's status column.

---

## Candidate Queue (topic + source to re-check only — no baked-in facts or figures)

Each entry is a topic worth investigating, plus where to re-verify it. The specific numbers/dates a past session found are deliberately not repeated here — they're exactly the kind of detail that goes stale and gets trusted by mistake.

| Topic | Where to re-verify |
|---|---|
| 2027 Presidential Election Winner parimutuel | Current news search — candidate field, declared primaries |
| Osimhen transfer destination parimutuel | Transfer news search — window may have closed |
| Africa startup capital race (quarterly) | Africa: The Big Deal / TechCabal quarterly funding reports |
| Which Big Tech responds first to FCCPC news-content probe | FCCPC official statements, Nigerian tech press |
| Nigeria digital infrastructure race (NIN / mobile penetration / broadband / Kuiper) | NIMC, NCC published figures |
| Flutterwave IPO filing | Flutterwave official statements, Nigerian business press |
| Davido album chart debut | TurnTable Charts Nigeria |
| NGX weekly best/worst performer (rotating format) | NGX official data |
| WAFCON event-page bundles (win/clean sheet/scorer) | Confirm current group stage / fixture status against the 25 Jul–16 Aug CAF-confirmed dates |
| Remaining WAFCON semifinal/final AMMs, Expectations Index | Held back this wave to avoid adding more sports volume — re-check fixture dates once group stage concludes |
| Comic Con cosplay champion, Woordfees auction market | Watch until finalists/catalogue published |

**Watchlist (needs a reveal before outcomes can be fixed):**
- BBNaija S11 housemate social-growth market — needs official cast reveal
- Headies award-category parimutuel — needs nominee list published

---

## Rejected Ideas — Carry Forward

```json
[
  {
    "idea": "WC 2026 outright winner parimutuel",
    "reason_rejected": "Field incomplete pending knockout results",
    "revisit_when": "After the relevant round concludes — re-check current tournament stage"
  },
  {
    "idea": "Headies award category parimutuel bundle",
    "reason_rejected": "Nominee lists not yet published",
    "revisit_when": "When nominees are published — check theheadies.com"
  },
  {
    "idea": "CBN MPC decision market (MPR rate band)",
    "reason_rejected": "Current MPR level and analyst consensus not verified",
    "revisit_when": "Before next confirmed MPC meeting date — re-verify date and consensus"
  },
  {
    "idea": "USD/NGN NAFEM rate band market",
    "reason_rejected": "Needs reference-rate band methodology, not yet built",
    "revisit_when": "Once a band-construction method is defined"
  }
]
```

---

## How to update this file

After a Market Brain session: overwrite the Last Known Wave State block with fresh numbers, replace the Candidate Queue with topics only (resist the urge to bake in the facts you just found — link to where to re-check instead), and update Rejected Ideas. Don't append to history here — this file should always reflect only the most recent session, so there's one obvious place to look and no ambiguity about which entry is current.
