# KASIRO BRAIN
**Version:** 1.0 | **Last updated:** 2026-07-03 | **Updated by:** operator

---

## What Kasiro Is

Kasiro (kasiro.app) is Africa's prediction trading marketplace. Users deposit USDT on Tron, trade YES/NO contracts or multi-outcome pools on real-world events — sports, politics, entertainment, macroeconomics, African internet culture — and withdraw winnings. The platform earns 2% on every trade via AMM fee or parimutuel rake.

**Positioning:** Not a betting app. Not DeFi. Not US-first. A prediction trading platform built natively for African markets — the only one running a hybrid AMM + parimutuel engine at this scale on the continent.

**Structural differentiator:** Parimutuel multi-outcome markets. No African competitor offers this properly. AMM binary markets for single-event questions; parimutuel for elections, tournaments, award categories.

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

## Operating Principles (non-negotiable)

1. **Convention-by-Enforcement** — repeated bugs must be enforced by code, not comments
2. **Done Means Done** — shipped = deployed + hardened + scenario-tested
3. **One Pillar One Week** — finite weekly hour budget; one focus area; nothing added mid-week
4. **Research Before Suggesting** — always web-search the underlying event before recommending a market; verify it hasn't happened and prior is 20–80%
5. **AMM helpers always** — never inline pool math; always call `poolsAfterBuy`/`poolsAfterSell` from `amm.ts`
6. **Operator control** — agents only suggest; operator decides what to publish, edit, resolve, or price

---

## Domain Files (read these for full context)

| File | Owned by | What it holds |
|---|---|---|
| `domains/markets.md` | Market Brain agent | Active board state, pipeline design, current wave, rejected ideas |
| `domains/content.md` | Marketing agent | Brand voice, channel rules, content calendar, engagement workflow |
| `domains/competitors.md` | Market Brain + Marketing agents | Live competitor snapshots, pricing benchmarks, category gaps |
| `domains/product.md` | Product agent | Open items, decisions, conversion strategy, roadmap priorities |
| `domains/eng.md` | Engineering agent | Tech stack, AMM rules, guardrails, open engineering issues |

---

## Agent Directory

| Agent | Skill name | What it does |
|---|---|---|
| Market Brain | `kasiro-market-brain` | Scans, audits, prices, and drafts admin-ready market fields |
| Marketing | `kasiro-marketing` | Drafts content, plans calendars, writes campaign and engagement copy |
| Product | `kasiro-product` | Weekly reviews, roadmap prioritisation, decision memos, feature specs |
| Engineering | `kasiro-engineering` | Replit prompts, bug diagnosis, phase specs, architecture decisions |

---

## Current State Snapshot
*(Update this section after every significant session)*

**Last updated:** 2026-07-03
**Active focus:** Building second brain + agent system
**Current market wave:** Check `domains/markets.md`
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
