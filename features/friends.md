---
type: Feature
title: Friends & Collaborative Tasks
description: Social task sharing with friend management by email, dual-completion confirmation, and SMTP transactional emails.
tags: [friends, collaboration, shared-tasks, social, smtp, email]
status: active
last_updated: 2026-10-26
---

# Friends & Collaborative Tasks

## Overview
Enables collaborative task management between friends:
- **Two Vertical Sections Layout**:
  - **Pending Requests Card**: Displays all incoming pending friend requests with custom handwritten bold **tick** (accept) and **cross** (decline) SVGs matching the playful Sniglet font aesthetic, with neutral dark/cream color styling.
  - **Existing Friends Card (Lazy Loading)**: Displays the user's accepted friends list with pagination/lazy loading on scroll, badge counts, and removal options.
- **Existing Friend Search**: Search input specifically searches and filters existing accepted friends by email or name.
- **Friend Stats Viewing**: Clicking on a friend in the accepted friends list inspects their public stats:
  - If their stats are **Public**, opens a modal sheet displaying their full productivity stats and period breakdown.
  - Public indicator badges and globe icons use theme-governed subtle whitish green (`#D4E7DC` in dark mode, `#476251` in light mode) without harsh bright or neon tints.
  - If their stats are **Private**, informs the user that the friend has chosen to keep their stats private.
- **Add Friend FAB**: Bottom-right floating `+` button (styled like the Add Task button) opening an "Add Friend" modal to search registered users across the system by email and send friend requests. Upon sending, the modal automatically closes and displays an animated `Request sent to {email}` notification floating at the top of the view for 4 seconds.
- **Real-Time In-App Friend Request Notifications**: Displays an animated floating notification banner at the top of the screen when an incoming friend request is received (via FCM foreground event or real-time polling fallback), with a 'View' action that jumps directly to the Friends tab, accompanied by a pending count badge on the Friends navigation icon.
- **Shared Tasks & Dual Completion**:
  - **Progress Badge**: Displays `x/y completed the task` directly on the task card whenever a task is shared.
  - **Strict Pending State**: Even if one participant has not completed the task, the task remains in the pending/active list (across today, tomorrow, etc.). If the current user completed their part, their checkbox displays the completed tick mark, but the task stays in the active/pending list until all participants complete.
  - **Participant Breakdown Modal**: Clicking a shared task opens a modal detailing all participants (creator and shared friends) with their individual completion status (`Completed ✓` or `Pending ⏳`).
- **Transactional SMTP Emails**: HTML emails sent via Gmail SMTP for friend requests, request acceptances, and shared tasks.
- **Abuse & Rate Limiting**:
  - `POST /api/friends`: Max 15 requests per hour per user, and max 1 request per minute to the same recipient (protects FCM and SMTP quotas).
  - `GET /api/friends/search`: Max 30 lookups per minute per user.
  - `GET /api/friends`: Max 90 requests per minute per user.
  - `POST /api/tasks` (shared): Max 20 shared tasks per hour per user.

## Components & Architecture
- **Web Backend & API**:
  - `Web/lib/email.ts` - Nodemailer SMTP integration with professional HTML templates (hosting the official TodoCat logo, zero emojis) for friend requests, acceptances, and shared tasks.
  - `Web/models/Friendship.ts` - Friendship schema with unique compound index on `(requester, recipient)`.
  - `Web/models/Task.ts` - `sharedWith` and `completedBy` fields.
  - `Web/app/api/tasks/route.ts` - Supports `sharedWith` querying and populates `userId`, `sharedWith`, and `completedBy`.
  - `Web/app/api/tasks/[id]/route.ts` - Handles individual participant toggling and enforces task completion only when all participants finish.
  - `Web/app/api/friends/route.ts` - `GET` supports searching existing friends by email/name (`search`, `email`), pagination (`page`, `limit`), and returns pending requests alongside paginated friends; `POST` creates friend requests.
  - `Web/app/api/friends/[id]/route.ts` - Request accept/decline and friendship removal.
  - `Web/app/api/friends/search/route.ts` - Strict registered user search for adding friends. Rejects partial searches to prevent email scraping; requires a full email address with valid domain and returns an exact match only.
- **Web Frontend (Next.js)**:
  - `Web/app/dashboard/page.tsx` - Added "Friends" view tab, shared task `x/y completed the task` badges, and shared task participants breakdown modal.
  - `Web/components/FriendsView.tsx` - Two-card layout (pending requests + lazy-loading friends with existing friends search) and "Add New Friend" modal without unverified fallback dispatch buttons.
- **Mobile (Flutter)**:
  - `app/lib/models/friend.dart` - `FriendUser`, `FriendItem`, `PendingFriendRequest`, `FriendsData` with pagination support (`total`, `hasMore`, `page`).
  - `app/lib/models/task.dart` - `creator`, `sharedWith`, `completedBy`, `allParticipants`, `dualProgressText` (`x/y completed the task`).
  - `app/lib/services/api_service.dart` - `fetchFriends({int? page, int? limit, String? search})` with query parameters.
  - `app/lib/presentation/screens/home/widgets/task_card_tile.dart` - Renders `x/y completed the task` badge for shared tasks.
  - `app/lib/presentation/screens/home/widgets/task_details_modal.dart` - Displays all participants with individual `Completed ✓` and `Pending ⏳` status badges.
  - `app/lib/presentation/screens/home/widgets/friends_view.dart` - Two-card vertical layout (pending requests card + lazy loading friends card with existing friends email search) and `_AddFriendBottomSheet` strictly sending to verified registered user search results.
  - `app/lib/presentation/screens/home_screen.dart` - Handles shared task completion toggling per participant and floating `+` button.
