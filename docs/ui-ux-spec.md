# RELIEFROUTE UI/UX SPECIFICATION

## Product idea

ReliefRoute helps people find everyday medicines, manage prescriptions, and
follow delivery orders from one simple mobile app.

## New design direction

The interface uses a calm, accessible healthcare style instead of a busy retail
layout. Each screen answers one question clearly:

- Home: What needs my attention today?
- Medicines: What can I find and buy?
- Orders: Where is my delivery?
- Care: What prescription or reminder action is due?

## Visual system

| Token | Value | Use |
|---|---|---|
| Primary | `#4C1D95` | Main actions and navigation |
| Accent | `#8B5CF6` | Highlights and active states |
| Surface | `#FCFAFF` | Page background |
| Card | `#FFFFFF` | Content containers |
| Text | `#171321` | Main text |
| Muted | `#6B6475` | Supporting text |
| Success | `#16855B` | Delivered and completed states |
| Warning | `#B45309` | Pending actions |

Typography uses large, readable headings, short descriptions, and sentence-case
labels. Buttons use verbs: `Browse medicines`, `Track order`, `Add reminder`.

## Main user flow

```text
Welcome → Sign in → Home → Browse medicines → Medicine details
                                 ↓
                         Add to order → Delivery address
                                 ↓
                           Order confirmation
```

## Screen requirements

### Welcome and sign in

- Clear RELIEFROUTE logo and purpose statement.
- Username/email and password fields with validation.
- Primary `Log in` action and secondary account action.
- Demo mode is labelled honestly.

### Home

- Greeting and profile avatar.
- One delivery status card.
- Search field above quick actions.
- Quick actions: Medicines, Orders, Reminders, Support.
- Recent activity and healthcare services below.

### Medicine finder

- Search and category chips.
- Product name, category, price, and prescription requirement.
- Empty state with a useful next action.
- Backend connection status is small and non-blocking.

### Orders and care

- Status uses both text and colour; colour is never the only signal.
- Prescription review shows reference, date, and next action.
- Reminders show medicine, time, frequency, and completion state.

## Accessibility and content rules

- Minimum touch target: 48dp.
- Keep body text readable on small screens.
- Do not use colour alone to communicate status.
- Use plain language and South African Rand (`R`) for prices.
- Never display passwords, payment credentials, or medical files in logs.
