---
type: Playbook
title: TodoCat Agent Protocol & OKF Specification
description: Operational rules for AI agents working on TodoCat, enforcing Google Open Knowledge Format (OKF) documentation.
tags: [agent, protocol, okf, documentation]
updated_at: 2026-10-27T16:45:00Z
---

# Agent Playbook & Google OKF Protocol

Every AI agent working on the **TodoCat** codebase MUST strictly follow these rules:

---

## 1. Google Open Knowledge Format (OKF) Maintenance

Whenever any feature is **created**, **modified**, or **deprecated**, the agent **MUST** update or create the corresponding OKF concept markdown file under `features/`.

### OKF File Requirements
Each feature document must conform to the Google Open Knowledge Format specification:
1. **YAML Frontmatter**:
   ```yaml
   ---
   type: Feature # or API, Architecture, Workflow
   title: Human & Agent Readable Feature Name
   description: 1-2 sentence concise summary of what this feature does.
   tags: [keyword1, keyword2]
   status: active # active, in-progress, or deprecated
   last_updated: YYYY-MM-DD
   ---
   ```
2. **Body Structure**:
   - **Overview**: Core behavior and user story.
   - **Architecture & Components**: Impacted frontend/backend files and models.
   - **API Contracts**: Endpoints, request/response formats.
   - **Data Schema**: Fields and persistence details.
   - **Edge Cases & Offline Behavior**: Offline handling, sync, failure states.

---

## 2. Feature Catalog (OKF Index)

| Feature | Concept Document | Type | Status |
| :--- | :--- | :--- | :--- |
| **Authentication & Profile** | [auth.md](features/auth.md) | `Feature` | `active` |
| **Task Management** | [task-management.md](features/task-management.md) | `Feature` | `active` |
| **Task Search & Filtering** | [search-filtering.md](features/search-filtering.md) | `Feature` | `active` |
| **Offline Sync & Caching** | [offline-sync.md](features/offline-sync.md) | `Feature` | `active` |
| **Push Notifications (FCM)** | [push-notifications.md](features/push-notifications.md) | `Feature` | `active` |
| **Friends & Social Tasks** | [friends.md](features/friends.md) | `Feature` | `active` |
| **Analytics & Velocity** | [analytics.md](features/analytics.md) | `Feature` | `active` |
| **Cat Companion & Overlay** | [cat-companion.md](features/cat-companion.md) | `Feature` | `active` |
| **Android Home Widgets** | [home-widgets.md](features/home-widgets.md) | `Feature` | `active` |
| **Theme & UI Styling** | [theming.md](features/theming.md) | `Feature` | `active` |
| **Web Dashboard & Landing** | [web-experience.md](features/web-experience.md) | `Feature` | `active` |
| **Account & Legal Compliance** | [account-legal.md](features/account-legal.md) | `Feature` | `active` |
| **Architectural Decisions** | [decision.md](features/decision.md) | `DecisionLog` | `active` |

---

## 3. Core Coding Rules
1. **Concise explanations**: Keep all user communications short and to the point.
2. **Follow existing coding patterns**: Match Flutter and Next.js styles already established in the codebase.
3. **No duplicate functions**: Re-use existing utilities and services.
4. **Don't overdo it**: Implement strictly what is requested without bloated abstractions.
5. **No assumptions**: Ask the user whenever clarification is required.
6. **Production error sanitization**: Never display raw system logs, socket errors, DNS failures, or stack traces in the UI. All exceptions must be sanitized to user-friendly messages.
7. **Optimistic UI with Rollback**: Fast-path interactions (checkboxes, friend actions, task moves) must update the UI immediately without waiting for network responses, rolling back gracefully upon API failure.
8. **Zero Emojis Policy**: Do not use emojis in user-facing UI, notifications, toasts, or email templates unless explicitly requested. Use clean typography and SVG/vector icons.

---

## 4. User Workflow & Planning Preferences
1. **Concise In-Chat Plans Only**: Never generate standalone markdown plan files (e.g. `.md` artifacts or plan documents). Always present proposals and implementation plans as concise, bulleted summaries directly in the chat response.
2. **Feature Docs Only Upon Approval**: Create or update concept markdown files under `features/*.md` (Google OKF) **strictly after** the user approves and the feature is implemented, never for preliminary plans.
