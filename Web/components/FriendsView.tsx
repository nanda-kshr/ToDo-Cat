"use client";

import { useEffect, useState, useCallback, useRef } from "react";

interface FriendUser {
  _id: string;
  name?: string;
  email: string;
  avatar?: string;
  isProfilePublic?: boolean;
}

interface FriendItem {
  friendshipId: string;
  user: FriendUser;
  since?: string;
}

interface PendingRequest {
  friendshipId: string;
  user: FriendUser;
  createdAt?: string;
}

interface SearchUserResult {
  _id: string;
  name?: string;
  email: string;
  avatar?: string;
  friendshipStatus: "none" | "accepted" | "pending_sent" | "pending_received";
  friendshipId?: string;
}

interface FriendsViewProps {
  authFetch: (url: string, options?: RequestInit) => Promise<Response>;
  onCountUpdate?: (count: number) => void;
}

export default function FriendsView({ authFetch, onCountUpdate }: FriendsViewProps) {
  // State for accepted friends & lazy loading
  const [friends, setFriends] = useState<FriendItem[]>([]);
  const [totalFriends, setTotalFriends] = useState(0);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [loadingFriends, setLoadingFriends] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  // State for pending requests
  const [pendingIncoming, setPendingIncoming] = useState<PendingRequest[]>([]);
  const [loadingRequests, setLoadingRequests] = useState(false);

  // State for "Add Friend" modal & searching new friends
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addSearchEmail, setAddSearchEmail] = useState("");
  const [searchResults, setSearchResults] = useState<SearchUserResult[]>([]);
  const [isSearchingUsers, setIsSearchingUsers] = useState(false);
  const [modalFeedback, setModalFeedback] = useState<{ text: string; error?: boolean } | null>(null);

  // Debounce ref
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const addSearchTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Fetch friends list (handles search & pagination)
  const fetchFriends = useCallback(
    async (targetPage: number, query: string, append: boolean = false) => {
      if (append) {
        setLoadingMore(true);
      } else {
        setLoadingFriends(true);
      }

      try {
        const params = new URLSearchParams({
          page: targetPage.toString(),
          limit: "10",
        });
        if (query.trim()) {
          params.set("search", query.trim());
        }

        const res = await authFetch(`/api/friends?${params.toString()}`);
        if (res.ok) {
          const data = await res.json();
          const newFriends: FriendItem[] = data.friends || [];
          const incoming: PendingRequest[] = data.pendingIncoming || [];
          const pagination = data.pagination || {};

          setPendingIncoming(incoming);
          setTotalFriends(pagination.total ?? newFriends.length);
          setHasMore(Boolean(pagination.hasMore));
          setPage(targetPage);

          if (append) {
            setFriends((prev) => [...prev, ...newFriends]);
          } else {
            setFriends(newFriends);
          }

          onCountUpdate?.(pagination.total ?? newFriends.length);
        }
      } catch (err) {
        console.error("Error fetching friends:", err);
      } finally {
        setLoadingFriends(false);
        setLoadingMore(false);
      }
    },
    [authFetch, onCountUpdate]
  );

  // Initial load
  useEffect(() => {
    fetchFriends(1, "", false);
  }, [fetchFriends]);

  // Handle searching existing friends by email
  const handleExistingSearchChange = (val: string) => {
    setSearchQuery(val);
    if (searchTimeoutRef.current) {
      clearTimeout(searchTimeoutRef.current);
    }
    searchTimeoutRef.current = setTimeout(() => {
      fetchFriends(1, val, false);
    }, 300);
  };

  // Load more friends (lazy loading)
  const handleLoadMore = () => {
    if (!loadingMore && hasMore) {
      fetchFriends(page + 1, searchQuery, true);
    }
  };

  // Accept incoming friend request
  const handleAcceptRequest = async (friendshipId: string) => {
    try {
      const res = await authFetch(`/api/friends/${friendshipId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "accept" }),
      });
      if (res.ok) {
        fetchFriends(1, searchQuery, false);
      }
    } catch (err) {
      console.error("Failed to accept friend request:", err);
    }
  };

  // Decline incoming friend request
  const handleDeclineRequest = async (friendshipId: string) => {
    try {
      const res = await authFetch(`/api/friends/${friendshipId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "decline" }),
      });
      if (res.ok) {
        setPendingIncoming((prev) => prev.filter((r) => r.friendshipId !== friendshipId));
      }
    } catch (err) {
      console.error("Failed to decline friend request:", err);
    }
  };

  // Remove existing friend
  const handleRemoveFriend = async (friendshipId: string, name: string) => {
    if (!confirm(`Are you sure you want to remove ${name} from your friends?`)) return;
    try {
      const res = await authFetch(`/api/friends/${friendshipId}`, {
        method: "DELETE",
      });
      if (res.ok) {
        fetchFriends(1, searchQuery, false);
      }
    } catch (err) {
      console.error("Failed to remove friend:", err);
    }
  };

  // Search registered users to add a new friend
  const handleAddSearchChange = (val: string) => {
    setAddSearchEmail(val);
    setModalFeedback(null);
    if (addSearchTimeoutRef.current) {
      clearTimeout(addSearchTimeoutRef.current);
    }

    const trimmed = val.trim();
    if (trimmed.length < 2) {
      setSearchResults([]);
      setIsSearchingUsers(false);
      return;
    }

    addSearchTimeoutRef.current = setTimeout(async () => {
      setIsSearchingUsers(true);
      try {
        const res = await authFetch(`/api/friends/search?email=${encodeURIComponent(trimmed)}`);
        if (res.ok) {
          const data = await res.json();
          setSearchResults(data.users || []);
        }
      } catch (err) {
        console.error("Failed searching users:", err);
      } finally {
        setIsSearchingUsers(false);
      }
    }, 350);
  };

  // Send friend request
  const handleSendFriendRequest = async (email: string) => {
    setModalFeedback(null);
    try {
      const res = await authFetch("/api/friends", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (res.ok) {
        setModalFeedback({ text: data.message || "Request sent 🐾" });
        setSearchResults((prev) =>
          prev.map((u) => (u.email === email ? { ...u, friendshipStatus: "pending_sent" } : u))
        );
        fetchFriends(1, searchQuery, false);
      } else {
        setModalFeedback({ text: data.message || "Failed to send request", error: true });
      }
    } catch (err: any) {
      setModalFeedback({ text: err.message || "Network error", error: true });
    }
  };

  return (
    <div className="space-y-6 relative pb-12">
      {/* SECTION 1: Pending Friend Requests Card */}
      <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 shadow-sm">
        <div className="flex items-center justify-between pb-3 border-b border-neutral-800">
          <div className="flex items-center gap-2">
            <span className="text-amber-400">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
                />
              </svg>
            </span>
            <h3 className="text-sm font-semibold text-white">Pending Friend Requests</h3>
            <span className="text-xs px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/20 font-medium">
              {pendingIncoming.length}
            </span>
          </div>
        </div>

        <div className="pt-3">
          {pendingIncoming.length === 0 ? (
            <div className="text-xs text-neutral-500 py-3 text-center">
              No pending friend requests.
            </div>
          ) : (
            <div className="space-y-2.5">
              {pendingIncoming.map((req) => (
                <div
                  key={req.friendshipId}
                  className="flex items-center justify-between p-3 rounded-xl bg-neutral-950/60 border border-neutral-800/80 hover:border-neutral-700 transition"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-8 h-8 rounded-full bg-neutral-800 flex items-center justify-center text-xs font-bold text-neutral-200 shrink-0">
                      {req.user.avatar ? (
                        <img
                          src={req.user.avatar}
                          alt=""
                          className="w-full h-full rounded-full object-cover"
                        />
                      ) : (
                        (req.user.name?.[0] || req.user.email[0]).toUpperCase()
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-white truncate">
                        {req.user.name || req.user.email.split("@")[0]}
                      </p>
                      <p className="text-[11px] text-neutral-400 truncate">{req.user.email}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => handleAcceptRequest(req.friendshipId)}
                      className="bg-white hover:bg-neutral-200 text-neutral-950 px-3 py-1.5 rounded-lg text-xs font-semibold transition"
                    >
                      Accept
                    </button>
                    <button
                      onClick={() => handleDeclineRequest(req.friendshipId)}
                      className="bg-neutral-800 hover:bg-neutral-700 text-neutral-400 hover:text-white px-3 py-1.5 rounded-lg text-xs font-medium transition"
                    >
                      Decline
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* SECTION 2: Existing Friends Card with Search & Lazy Loading */}
      <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 shadow-sm space-y-4">
        {/* Header & Search */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-neutral-800">
          <div className="flex items-center gap-2">
            <span className="text-neutral-300">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
            </span>
            <h3 className="text-sm font-semibold text-white">Friends</h3>
            <span className="text-xs px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-300 font-medium">
              {totalFriends}
            </span>
          </div>

          {/* Search Existing Friends by Email */}
          <div className="relative w-full sm:w-64">
            <svg
              className="w-3.5 h-3.5 text-neutral-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              placeholder="Search friends by email..."
              value={searchQuery}
              onChange={(e) => handleExistingSearchChange(e.target.value)}
              className="w-full bg-neutral-950 border border-neutral-800 rounded-xl pl-8 pr-3 py-1.5 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
            />
            {searchQuery && (
              <button
                onClick={() => handleExistingSearchChange("")}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-neutral-500 hover:text-neutral-300"
              >
                ×
              </button>
            )}
          </div>
        </div>

        {/* Lazy Loading Friends List */}
        <div>
          {loadingFriends && friends.length === 0 ? (
            <div className="text-center py-8 text-xs text-neutral-500">Loading friends...</div>
          ) : friends.length === 0 ? (
            <div className="text-center py-10 bg-neutral-950/40 border border-dashed border-neutral-800 rounded-xl p-6">
              <p className="text-xs font-semibold text-neutral-300">
                {searchQuery ? "No friends match your search." : "No friends added yet!"}
              </p>
              <p className="text-[11px] text-neutral-500 mt-1">
                {searchQuery
                  ? "Try searching with a different email."
                  : "Click the + button at the bottom right to add a friend by email."}
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {friends.map((item) => {
                const displayName = item.user.name || item.user.email.split("@")[0];
                return (
                  <div
                    key={item.friendshipId}
                    className="flex items-center justify-between p-3 rounded-xl bg-neutral-950/40 border border-neutral-800/80 hover:border-neutral-700 transition"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-9 h-9 rounded-full bg-neutral-800 flex items-center justify-center text-xs font-bold text-white shrink-0">
                        {item.user.avatar ? (
                          <img
                            src={item.user.avatar}
                            alt=""
                            className="w-full h-full rounded-full object-cover"
                          />
                        ) : (
                          (item.user.name?.[0] || item.user.email[0]).toUpperCase()
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="text-xs font-semibold text-white truncate">{displayName}</p>
                          <span className="text-[10px] text-neutral-300 bg-neutral-800 border border-neutral-700/60 px-2 py-0.5 rounded-md font-medium">
                            Friend
                          </span>
                        </div>
                        <p className="text-[11px] text-neutral-400 truncate">{item.user.email}</p>
                      </div>
                    </div>

                    <button
                      onClick={() => handleRemoveFriend(item.friendshipId, displayName)}
                      title="Remove friend"
                      className="p-1.5 rounded-lg text-neutral-500 hover:text-rose-400 hover:bg-neutral-800 transition text-xs"
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6"
                        />
                      </svg>
                    </button>
                  </div>
                );
              })}

              {/* Lazy Loading More Indicator & Trigger */}
              {hasMore && (
                <div className="pt-3 text-center">
                  <button
                    onClick={handleLoadMore}
                    disabled={loadingMore}
                    className="px-4 py-1.5 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-xs font-medium text-neutral-300 hover:text-white transition disabled:opacity-50"
                  >
                    {loadingMore ? "Loading more friends..." : "Load More Friends"}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Floating Small + Button on bottom right (like add task) */}
      <button
        onClick={() => {
          setIsAddModalOpen(true);
          setModalFeedback(null);
          setAddSearchEmail("");
          setSearchResults([]);
        }}
        title="Add New Friend"
        aria-label="Add New Friend"
        className="fixed bottom-6 right-6 md:bottom-8 md:right-8 z-40 bg-white hover:bg-neutral-200 text-neutral-950 p-3.5 rounded-full shadow-2xl transition flex items-center justify-center border border-neutral-300"
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
        </svg>
      </button>

      {/* Add Friend Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-neutral-900 border border-neutral-800 rounded-2xl w-full max-w-md p-6 shadow-2xl relative">
            <div className="flex items-center justify-between pb-3 border-b border-neutral-800">
              <h3 className="text-sm font-bold text-white">Add New Friend</h3>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="text-neutral-500 hover:text-neutral-300 p-1 rounded-lg"
              >
                ✕
              </button>
            </div>

            <div className="mt-4 space-y-4">
              {modalFeedback && (
                <div
                  className={`p-2.5 rounded-xl text-xs flex items-center gap-2 ${
                    modalFeedback.error
                      ? "bg-rose-500/10 text-rose-400 border border-rose-500/20"
                      : "bg-neutral-800 text-neutral-200 border border-neutral-700"
                  }`}
                >
                  <span>{modalFeedback.error ? "⚠️" : "🐾"}</span>
                  <span>{modalFeedback.text}</span>
                </div>
              )}

              <div>
                <label className="block text-xs font-medium text-neutral-400 mb-1.5">
                  Search Registered User by Email
                </label>
                <div className="relative">
                  <input
                    type="email"
                    placeholder="friend@example.com"
                    value={addSearchEmail}
                    onChange={(e) => handleAddSearchChange(e.target.value)}
                    className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 transition"
                  />
                  {isSearchingUsers && (
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-neutral-500">
                      Searching...
                    </span>
                  )}
                </div>
              </div>

              {/* Results List */}
              <div className="space-y-2 max-h-60 overflow-y-auto">
                {searchResults.length > 0 ? (
                  searchResults.map((user) => (
                    <div
                      key={user._id}
                      className="flex items-center justify-between p-2.5 rounded-xl bg-neutral-950 border border-neutral-800 text-xs"
                    >
                      <div className="min-w-0 pr-2">
                        <p className="font-semibold text-white truncate">
                          {user.name || user.email.split("@")[0]}
                        </p>
                        <p className="text-[11px] text-neutral-400 truncate">{user.email}</p>
                      </div>

                      <div className="shrink-0">
                        {user.friendshipStatus === "accepted" ? (
                          <span className="text-[10px] text-neutral-300 bg-neutral-800 border border-neutral-700/60 px-2 py-0.5 rounded-md font-medium">
                            Friends 🐾
                          </span>
                        ) : user.friendshipStatus === "pending_sent" ? (
                          <span className="text-[10px] text-neutral-400 bg-neutral-800 px-2 py-0.5 rounded font-medium">
                            Request Sent
                          </span>
                        ) : (
                          <button
                            onClick={() => handleSendFriendRequest(user.email)}
                            className="bg-white hover:bg-neutral-200 text-neutral-950 px-3 py-1 rounded-lg text-xs font-medium transition"
                          >
                            + Add
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                ) : addSearchEmail.trim().length >= 2 && !isSearchingUsers ? (
                  <div className="text-center py-3 text-xs text-neutral-500">
                    No users found with that email.
                  </div>
                ) : null}
              </div>

              {/* Direct email fallback send */}
              {addSearchEmail.includes("@") && searchResults.length === 0 && !isSearchingUsers && (
                <div className="pt-2 border-t border-neutral-800 flex justify-end">
                  <button
                    onClick={() => handleSendFriendRequest(addSearchEmail.trim())}
                    className="bg-white hover:bg-neutral-200 text-neutral-950 px-4 py-1.5 rounded-xl text-xs font-medium transition"
                  >
                    Send Request to {addSearchEmail.trim()}
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}