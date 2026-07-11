# Wave State — Snapshot, Not Doctrine

**This file is a snapshot from the session date below. It is not verified truth as of today.**

Before using anything here to draft or price a market: re-check the live market count via `/api/markets`, and independently re-search every fact attached to a queue idea. Nothing in this file should be cited as current without a fresh check — that's true even if it was true when written. This file exists so a session has a starting point for "what were we last thinking," not so it can skip verification.

If this file is more than ~7 days old relative to today's session, treat everything below as historical context only — don't act on it before re-verifying.

---

## Last Known Wave State

**Session date:** 2026-07-09
**Wave:** WC R16 in progress; WAFCON anchors start ~Jul 28.
**Markets live (as of session):** 24
**Category balance (as of session):** sports_football heavily over-represented (~95%); macroeconomy, entertainment, fx_crypto, african_internet, politics under-represented.

*(Re-derive current count/balance from `/api/markets` — don't trust the numbers above.)*

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
| Attention Wars (Google Trends multi-topic race) | Confirm each topic is still live/upcoming, not past; Google Trends 5-term comparison cap applies |
| NGX weekly best/worst performer (rotating format) | NGX official data |
| WAFCON event-page bundles (win/clean sheet/scorer) | Confirm current group stage / fixture status |

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
