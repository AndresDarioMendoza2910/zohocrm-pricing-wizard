# Nessteams Pricing Wizard

Zoho CRM widget (Sigma extension) — the **Nessteams Pricing Simulator** adapted
for the **Job Request creation Wizard** on the Deals module.

This is one of two sibling projects under `Nessteams Pricing Calculator/`:

| Project | Launch context | Reads inputs via | Writes outputs via | Status text |
|---------|----------------|------------------|--------------------|-------------|
| **nessteams-pricing-wizard** (this one) | Wizard during record **creation** (no record yet) | `PageLoad` payload (`readWizardField`) | `ZOHO.CRM.WIZARD.post` | "Connected to Wizard" |
| nessteams-pricing-button | Custom Button on an **existing** Deal | `ZOHO.CRM.API.getRecord` | `ZOHO.CRM.API.updateRecord` | "Connected to Zoho CRM" |

> The two `widget.html` files are **identical except** the CRM read/write layer
> (`isWizard` flag, `readWizardField()`, the `PageLoad` branch, and the
> `saveToCRM` branch). UI, pricing, and cheat-sheet logic are the same in both.

## What it does
The user picks a seniority tier and salary range with sliders; the widget
computes client prices and writes salary + price values into the wizard form.
A "salary cheat sheet" (Catalyst backend) suggests typical ranges per role.

- **Inputs** (from screen 1 of the wizard, read on `PageLoad`):
  `Deal_Name` (job title, also the cheat-sheet lookup key) and `Seniority`.
- **Outputs** (posted to the wizard form on Save): `Salary_Low`, `Salary_High`,
  `Seat_Cost_Min`, `Seat_Cost_Max`.

## Pricing formula (do not change without intent)
- `MULT = 1.25` — cost multiplier (salary + Panama employer taxes/fees).
- `price = r125(salary * 1.25 + max(marginDollars, TIER_FLOORS[tier]))`
- `r125(v) = Math.ceil(v / 125) * 125` — rounds **up** to nearest 125.
- `TIER_FLOORS` is currently a **flat 1000** for all tiers (business decision
  2026-06-16); per-tier values are kept in the code for easy reinstatement.

## Backend dependency
Calls the Catalyst `cheatsheet-api` Advanced I/O function (Node 20) for role
lookups and usage counts. `CS_API` in `widget.html` points at the **absolute**
Catalyst URL (required because the widget is served from `*.zappsusercontent.com`):

```
https://pricing-calculator-916648406.development.catalystserverless.com/server/cheatsheet-api
```

Currently the **development** environment only. See the main project's
`HANDOFF.md` for promoting to production.

## Build & deploy
This is a standard Zoho ZET scaffold. From this folder:

```
zet pack
powershell -ExecutionPolicy Bypass -File .\fix-zip.ps1
```

`zet pack` produces `dist/extension.zip` but deliberately omits
`plugin-manifest.json`; `fix-zip.ps1` injects it back in. Then upload
`dist/extension.zip` at <https://sigma.zoho.com>.

> **Index Page must be `/widget.html`** (NOT `/app/widget.html`) — Zoho roots
> the server inside `app/`, so the `/app` prefix would 404.

After deploy, hard-refresh the CRM page (Zoho caches widget assets aggressively)
and verify the status bar shows **"Connected to Wizard · <job title>"** rather
than "Manual Mode".

## Files
```
plugin-manifest.json        { "service": "CRM" }
app/widget.html             the widget (wizard-adapted)
app/favicon.png
app/translations/en.json
package.json, server/       local ZET dev server (not shipped to Sigma)
fix-zip.ps1                 post-pack manifest injection
cert.pem, key.pem           local dev HTTPS certs
```
