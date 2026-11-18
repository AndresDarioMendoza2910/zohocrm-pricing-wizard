# Pricing Wizard — Zoho CRM widget

A Zoho CRM embedded widget (Sigma extension) that computes client-facing deal
pricing **while a deal is being created**. It runs inside the Deal-creation
**Wizard**, where no saved record exists yet, and writes its results straight into
the wizard form.

This is one of two UI variants of the same pricing engine. The
[Button widget](../zohocrm-pricing-button) is the other; they share all pricing
and cheat-sheet logic and differ only in how they read from and write to the CRM.

## What it does

As a rep fills out a new deal, the widget:

1. **Reads** the job title and seniority from the wizard's launch payload
   (`PageLoad`) — there's no saved record to query yet.
2. **Prices** the role live as the rep drags three sliders (salary low, salary
   high, target margin) and picks a seniority tier.
3. **Writes** the results back into the in-progress wizard form via the CRM Wizard
   API (`ZOHO.CRM.WIZARD.post`): salary band and seat-cost min/max.
4. **Suggests** typical salary ranges by querying the shared backend "cheat sheet."

## Pricing

```
cost  = salary × MULT                   // grosses salary up to true employer cost
price = roundUpTo125( cost + margin )    // margin floored per seniority tier
```

- `MULT` grosses a salary up to its real cost (salary + employer taxes/fees).
- `margin` is the rep's target but is clamped to a per-seniority minimum, so a role
  can't be accidentally underpriced.
- Prices round **up** to the nearest 125, and the effective margin % is shown back
  to the rep as a sanity check.

## A detail worth calling out: optimistic save

The CRM Wizard's "apply values" call updates the form immediately, but the promise
it returns frequently **never resolves**. Naively awaiting it would leave the save
button stuck on "Saving…" *and* skip the cheat-sheet write that runs in the
completion handler. The save instead settles through a guarded timeout fallback
(a `settled` flag prevents double-firing), so the UI always completes and the data
write always fires exactly once. This is the only logic that differs from the
Button variant, which talks to a normal record API whose promise resolves cleanly.

## Backend dependency

Calls the companion [Catalyst backend](../zohocrm-pricing-backend) for role lookups
and usage counts. Because the widget is served cross-origin from Zoho's widget
host, `CS_API` in `widget.html` is an **absolute** URL to the function, and writes
carry a shared key **in the request body** (not a header) to stay within the
browser's CORS "simple request" rules — see the backend README for the full
reasoning. Set `CS_API` and `CS_KEY` in `widget.html` before packaging.

## Build & deploy

Standard Zoho ZET widget. From this folder:

```
zet pack
powershell -ExecutionPolicy Bypass -File ./fix-zip.ps1
```

`zet pack` produces `dist/extension.zip` but omits `plugin-manifest.json`;
`fix-zip.ps1` injects it back in. Upload `dist/extension.zip` at
<https://sigma.zoho.com>.

> The widget's Index Page must be `/widget.html` (not `/app/widget.html`) — Zoho
> serves from inside `app/`, so the `/app` prefix would 404.

## Layout

```
app/widget.html          widget UI + logic (wizard variant)
app/favicon.png
app/translations/en.json
plugin-manifest.json      { "service": "CRM" }
package.json, server/     local ZET dev server (not shipped to Sigma)
fix-zip.ps1               post-pack manifest injection
```
