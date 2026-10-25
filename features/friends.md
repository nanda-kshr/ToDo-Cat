---
type: Feature
title: Friends & Collaborative Tasks
description: Social task sharing with friend management by email, dual-completion confirmation, and SMTP transactional emails.
tags: [friends, collaboration, shared-tasks, social, smtp, email]
status: active
last_updated: 2026-10-25
---

# Friends & Collaborative Tasks

## Overview
Enables collaborative task management between friends:
- **Friend Search & Management**: Search registered users by email, send/accept friend requests.
- **Transactional SMTP Emails**: Beautiful HTML emails sent via Gmail SMTP for friend requests, request acceptances, and newly shared tasks.
- **Friend List**: View active friends, count badges, and remove friends.
- **Pending Requests Banner**: Real-time incoming friend requests with Accept/Decline actions.
- **Shared Tasks**: Assign tasks to one or more friends in the task creation dialog.
- **Dual-Completion Logic**: Shared tasks require all assigned participants (creator + all friends) to check off before transitioning to the complete state. Both participants track progress (e.g. `1/2 completed`).

## Components & Architecture
- **Web Backend**:
  - `Web/lib/email.ts` - Nodemailer SMTP integration with templates for friend requests, acceptances, and shared tasks.
  - `Web/models/Friendship.ts` - Friendship schema with unique compound index on `(requester, recipient)`.
  - `Web/models/Task.ts` - `sharedWith` and `completedBy` fields.
  - `Web/app/api/tasks/route.ts` - Supports `sharedWith` querying and assignment, invalidating cache and notifying friends via email & FCM.
  - `Web/app/api/tasks/[id]/route.ts` - Dual completion logic toggling `completedBy` and resolving final `completed` state.
  - `Web/app/api/friends/route.ts` - Friends listing and request creation.
  - `Web/app/api/friends/[id]/route.ts` - Request accept/decline and friendship removal.
  - `Web/app/api/friends/search/route.ts` - Email-based user search.
- **Mobile (Flutter)**:
  - `app/lib/models/friend.dart` - `FriendUser`, `FriendItem`, `PendingFriendRequest`, `FriendsData`.
  - `app/lib/models/task.dart` - `sharedWith`, `completedBy`, `isShared`, `dualProgressText`.
  - `app/lib/presentation/screens/home/widgets/create_task_modal.dart` - "Share with Friend" picker dropdown and friend chips.
  - `app/lib/presentation/screens/home/widgets/task_card_tile.dart` - Shared indicator badge with `X/Y completed`.
  - `app/lib/presentation/screens/home/widgets/task_details_modal.dart` - Displays shared friend names and dual progress.
  - `app/lib/presentation/screens/home/widgets/friends_view.dart` - Friends tab with email search, pending requests, and friend cards.
  - `app/lib/presentation/screens/home/widgets/home_bottom_bar.dart` - 3rd tab for Friends.
