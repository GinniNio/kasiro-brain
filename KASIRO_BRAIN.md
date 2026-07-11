# KASIRO BRAIN
**Version:** 1.2 | **Last updated:** 2026-07-09

---

## What Kasiro Is

Kasiro (kasiro.app) is Africa's prediction trading marketplace. Users deposit USDT on Tron, trade YES/NO contracts or multi-outcome pools on real-world events — sports, politics, entertainment, macroeconomics, African internet culture — and withdraw winnings. The platform earns 2% on every trade via AMM fee or parimutuel rake.

**Positioning:** Not a betting app. Not DeFi. Not US-first. A prediction trading platform built natively for African markets — the only one running a hybrid AMM + parimutuel engine at this scale on the continent.

**Structural differentiator:** Parimutuel multi-outcome markets. No African competitor offers this properly. AMM binary markets for single-event questions; parimutuel for elections, tournaments, award categories, races and baskets where outcomes are mutually exclusive.

**Editorial differentiator:** Kasiro converts African attention, money, technology, public life and culture into verifiable markets. It should be known for distinctive race, basket, attention, reaction and index formats, not as a smaller sportsbook or a copy of a global exchange.

**What Kasiro is not:** A sportsbook, a wallet, a crypto exchange, a social media tool, or a micro-insurance product. Never position it as any of these.

---

## Core Identity

| Attribute | Value |
|---|---|
| Live URL | kasiro.app |
| X handle | @kasiro_markets |
| Instagram | @kasiromarkets |
| Telegram bot | @predicto_build_bot |
| Telegram community | Kasiro Markets (-1003896103462) |
| Deposit rail | TRC-20 USDT on Tron |
| Revenue model | 2% fee on AMM trades; 8% rake on parimutuel pools |
| Target user | Tech-savvy Africans 18–35, Nigeria-first, crypto-holding, sports-following |
| Operator identity | Anonymous — no public founder voice, no press, no podcast appearances |

---

## Shared Doctrine

**Read `KASIRO_DOCTRINE.md` before any agent spec or domain file.** The 15 doctrine rules override everything else.

---

## Connected Agent Loop

```
Market opportunity
→ Market Brain validates/drafts
→ Marketing Brain distributes
→ Product Brain prioritises fixes/features
→ Engineering Brain creates Replit prompts
→ Operator Brain decides what ships/promotes/fixes today
→ brain_update writes back to shared state
```

---

## Agent Directory

| Agent | Skill name | Purpose |
|---|---|---|
| Operator Brain | `kasiro-operator` | Daily operating board — decides what happens today |
| Market Brain | `kasiro-market-brain` | Validates, prices, and drafts safe publishable markets |
| Marketing Brain | `kasiro-marketing` | Distribution — X, Instagram, Threads. Autopost. Reply hunting. |
| Product Brain | `kasiro-product` | Chooses what to build, fix, defer, or kill |
| Engineering Brain | `kasiro-engineering` | Safe Replit prompts with acceptance tests |

---

## Domain Files

| File | Owned by | What it holds |
|---|---|---|
| `domains/markets.md` | Market Brain | Pipeline doctrine, board state, close-time rules, rejected ideas |
| `domains/market-strategy.md` | Market Brain | Differentiated editorial lenses, signature formats, scoring, validation and portfolio strategy |
| `domains/content.md` | Marketing Brain | Brand voice, channel rules, autopost rules, reply hunting state |
| `domains/competitors.md` | Market Brain + Marketing Brain | Competitor snapshots, pricing benchmarks, category gaps |
| `domains/product.md` | Product Brain | Open items, decisions, roadmap priorities, decision memos |
| `domains/eng.md` | Engineering Brain | Tech stack, AMM guardrails, DB rules, open engineering issues |

---

## Shared State Tables (pending implementation in Kasiro codebase)

| Table | Purpose |
|---|---|
| `brain_updates` | Append-only memory and coordination ledger |
| `market_requests` | Hot topics flagged with no live market |
| `signals` | Event and market intelligence for all agents |
| `ops_issues` | Bugs, settlement problems, trust issues (SEV0–SEV4) |
| `decision_memos` | Product decision traceability |
| `social_campaigns` | Autopost campaign tracking |
| `social_posts` | Individual platform posts with status/approval state |
| `social_creatives` | Generated/approved image assets per platform |

Run `/eng phase-spec --spec "shared state tables"` to generate the Replit implementation prompt.

---

## Current State Snapshot
*(Update this section after every significant session)*

**Last updated:** 2026-07-09
**Active focus:** Differentiate Kasiro through African attention, race, basket, reaction, index and Future Africa market franchises
**Current market wave:** Check `domains/markets.md`
**Market strategy:** Check `domains/market-strategy.md`
**Open product items:** Check `domains/product.md`
**Last content run:** Check `domains/content.md`

---

## What Is Dead / Archived

- Predicto 1 (Supabase/Vercel) — shut down 2026-04-03 per ADR-001
- OneDrive Predicto folder — dead workspace; read-only archive
- Prolego2 OneDrive folder — dead; Predicto 1 era artifacts only
- Niche daily scan — retired 2026-05-07; scrape scripts never returned to repo
- M2 Obi market (id: d5747991) — resolved NO; Obi resigned from ADC 2026-05-03
- Scheduled tasks (all) — replaced by this agent system

---

## Key Source Files (in Kasiro repo)

| File | What it is |
|---|---|
| `C:\Dev\Kasiro\replit.md` | Master AI session context — read this first for any engineering work |
| `C:\Dev\Kasiro\ACTION_PLAN.md` | Running list of open items; reviewed weekly |
| `C:\Dev\Kasiro\MARKET_PIPELINE_DESIGN.md` | Market curation doctrine and lifecycle rules |
| `C:\Dev\Kasiro\kasiro-conversion-plan.md` | Conversion strategy, problem hierarchy, differentiator framing |
| `C:\Dev\Kasiro\docs/design-system/brand-voice-guidelines.md` | Full brand voice doc |
| `C:\Dev\Kasiro\docs/design-system/design-system.md` | Visual design system |
| `C:\Dev\Kasiro\docs/ADR-001` through `ADR-009` | Why the architecture is what it is |
| `C:\Dev\Kasiro\OPERATIONS_MANUAL.md` | Day-to-day operations reference |
| `C:\Dev\Kasiro\MANUAL_DATABASE.md` | All 30+ tables with schema and descriptions |
