"use client";

import React, { useState, useEffect, useTransition, useCallback } from "react";
import {
  UsersIcon,
  UsersRoundIcon,
  PlusIcon,
  SearchIcon,
  FilterIcon,
  RefreshCwIcon,
  ShieldAlertIcon,
  AwardIcon,
  MoreVerticalIcon,
  KeyIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  XIcon,
} from "../Icons";
import { RoleBadge } from "./RoleBadge";
import { StatusBadge } from "./StatusBadge";
import { UserDrawer } from "./UserDrawer";
import { AddUserModal } from "./AddUserModal";
import { AdjustReputationModal } from "./AdjustReputationModal";
import { ResetPasswordModal } from "./ResetPasswordModal";
import type { AdminUsersListResponse, AdminUserSummary } from "@/actions/users";
import { getUsersAction } from "@/actions/users";

interface UsersDirectoryProps {
  initialData?: AdminUsersListResponse;
}

const roleFilters = [
  { label: "All roles", value: "all" },
  { label: "Adopters", value: "Adopter" },
  { label: "Fosters", value: "Foster" },
  { label: "Transporters", value: "Transporter" },
  { label: "Vets", value: "Veterinarian" },
  { label: "Sponsors", value: "Sponsor" },
  { label: "Admins", value: "Administrator" },
];

const statusFilters = [
  { label: "All status", value: "all" },
  { label: "Active", value: "active" },
  { label: "Suspended", value: "suspended" },
  { label: "Deactivated", value: "deleted" },
];

const sortOptions = [
  { label: "Newest joined", value: "newest" },
  { label: "Oldest joined", value: "oldest" },
  { label: "Highest reputation", value: "reputation_desc" },
  { label: "Lowest reputation", value: "reputation_asc" },
  { label: "Name (A-Z)", value: "name_asc" },
  { label: "Name (Z-A)", value: "name_desc" },
];

export function UsersDirectory({ initialData }: UsersDirectoryProps) {
  const [data, setData] = useState<AdminUsersListResponse | undefined>(
    initialData,
  );
  const [search, setSearch] = useState("");
  const [selectedRole, setSelectedRole] = useState("all");
  const [selectedStatus, setSelectedStatus] = useState("all");
  const [sortBy, setSortBy] = useState("newest");
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [isPending, startTransition] = useTransition();

  // Drawer & Modal States
  const [selectedUser, setSelectedUser] = useState<AdminUserSummary | null>(
    null,
  );
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isReputationModalOpen, setIsReputationModalOpen] = useState(false);
  const [isResetPasswordModalOpen, setIsResetPasswordModalOpen] =
    useState(false);
  const [activeMenuUserId, setActiveMenuUserId] = useState<number | null>(null);

  const fetchUsers = useCallback(
    (
      s = search,
      r = selectedRole,
      st = selectedStatus,
      sb = sortBy,
      p = page,
      ps = pageSize,
    ) => {
      startTransition(async () => {
        try {
          const res = await getUsersAction({
            search: s.trim() || undefined,
            role: r !== "all" ? r : undefined,
            status: st !== "all" ? st : undefined,
            sortBy: sb,
            page: p,
            pageSize: ps,
          });
          setData(res);
        } catch (err) {
          console.error("Failed to load users directory:", err);
        }
      });
    },
    [search, selectedRole, selectedStatus, sortBy, page, pageSize],
  );

  useEffect(() => {
    if (!initialData) {
      fetchUsers();
    }
  }, [fetchUsers, initialData]);

  const handleSearchChange = (val: string) => {
    setSearch(val);
    setPage(1);
    fetchUsers(val, selectedRole, selectedStatus, sortBy, 1, pageSize);
  };

  const handleRoleChange = (role: string) => {
    setSelectedRole(role);
    setPage(1);
    fetchUsers(search, role, selectedStatus, sortBy, 1, pageSize);
  };

  const handleStatusChange = (status: string) => {
    setSelectedStatus(status);
    setPage(1);
    fetchUsers(search, selectedRole, status, sortBy, 1, pageSize);
  };

  const handleSortChange = (sb: string) => {
    setSortBy(sb);
    setPage(1);
    fetchUsers(search, selectedRole, selectedStatus, sb, 1, pageSize);
  };

  const handlePageChange = (newPage: number) => {
    setPage(newPage);
    fetchUsers(search, selectedRole, selectedStatus, sortBy, newPage, pageSize);
  };

  const handlePageSizeChange = (newPageSize: number) => {
    setPageSize(newPageSize);
    setPage(1);
    fetchUsers(search, selectedRole, selectedStatus, sortBy, 1, newPageSize);
  };

  const handleInspectUser = (user: AdminUserSummary) => {
    setSelectedUser(user);
    setIsDrawerOpen(true);
    setActiveMenuUserId(null);
  };

  const handleOpenReputation = (user: AdminUserSummary) => {
    setSelectedUser(user);
    setIsReputationModalOpen(true);
    setActiveMenuUserId(null);
  };

  const handleOpenResetPassword = (user: AdminUserSummary) => {
    setSelectedUser(user);
    setIsResetPasswordModalOpen(true);
    setActiveMenuUserId(null);
  };

  const totalUsers = data?.stats.totalUsers ?? 0;
  const activeUsers = data?.stats.activeUsers ?? 0;
  const suspendedUsers = data?.stats.suspendedUsers ?? 0;
  const deletedUsers = data?.stats.deletedUsers ?? 0;
  const totalPages = data?.totalPages ?? 1;
  const totalCount = data?.totalCount ?? 0;
  const items = data?.items ?? [];

  return (
    <div className="w-full max-w-7xl mx-auto space-y-8">
      {/* Top Header & Action */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 font-outfit">
            User management
          </h1>
          <p className="text-slate-500 mt-1 text-sm">
            Inspect directory records, oversee role privileges, and resolve
            disputes.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => fetchUsers()}
            disabled={isPending}
            className="p-2.5 bg-white border border-slate-200/80 hover:bg-slate-50 text-slate-600 rounded-xl shadow-xs transition-colors flex items-center gap-2 text-xs font-semibold cursor-pointer"
            title="Refresh list"
          >
            <RefreshCwIcon
              className={`w-4 h-4 ${isPending ? "animate-spin text-blue-600" : ""}`}
            />
          </button>

          <button
            type="button"
            onClick={() => setIsAddModalOpen(true)}
            className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 active:scale-[0.98] text-white rounded-xl shadow-xs transition-all flex items-center gap-2 text-xs font-semibold cursor-pointer"
          >
            <PlusIcon className="w-4 h-4" />
            <span>Create user</span>
          </button>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Total accounts
            </span>
            <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <UsersIcon className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-2xl font-bold text-slate-900 tracking-tight">
            {totalUsers.toLocaleString()}
          </p>
          <p className="mt-1 text-xs text-slate-500">
            Registered platform members
          </p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Active users
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <UsersRoundIcon className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-2xl font-bold text-slate-900 tracking-tight">
            {activeUsers.toLocaleString()}
          </p>
          <p className="mt-1 text-xs text-slate-500">In good standing</p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Suspended
            </span>
            <div className="w-9 h-9 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
              <ShieldAlertIcon className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-2xl font-bold text-slate-900 tracking-tight">
            {suspendedUsers.toLocaleString()}
          </p>
          <p className="mt-1 text-xs text-slate-500">
            Access temporarily restricted
          </p>
        </div>

        <div className="bg-white border border-slate-200/80 rounded-2xl p-5 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Deactivated
            </span>
            <div className="w-9 h-9 rounded-xl bg-slate-100 text-slate-600 flex items-center justify-center">
              <FilterIcon className="w-5 h-5" />
            </div>
          </div>
          <p className="mt-3 text-2xl font-bold text-slate-900 tracking-tight">
            {deletedUsers.toLocaleString()}
          </p>
          <p className="mt-1 text-xs text-slate-500">Deleted accounts</p>
        </div>
      </div>

      {/* Main Table Container Card */}
      <div className="bg-white border border-slate-200/80 rounded-2xl shadow-xs overflow-hidden">
        {/* Search & Filter Bar */}
        <div className="p-5 border-b border-slate-100 space-y-4">
          <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
            {/* Search input */}
            <div className="relative flex-1 max-w-md">
              <SearchIcon className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={search}
                onChange={(e) => handleSearchChange(e.target.value)}
                placeholder="Search by name, email, or phone..."
                className="w-full pl-9 pr-8 py-2 text-xs rounded-xl bg-slate-50 border border-slate-200/80 focus:bg-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all"
              />
              {search && (
                <button
                  type="button"
                  onClick={() => handleSearchChange("")}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <XIcon className="w-3.5 h-3.5" />
                </button>
              )}
            </div>

            {/* Sort Dropdown */}
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-slate-500 shrink-0">
                Sort:
              </span>
              <select
                value={sortBy}
                onChange={(e) => handleSortChange(e.target.value)}
                className="px-3 py-2 text-xs font-medium bg-slate-50 border border-slate-200/80 rounded-xl outline-none focus:border-blue-500 transition-colors cursor-pointer"
              >
                {sortOptions.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Role and Status Segmented Controls */}
          <div className="flex flex-wrap items-center justify-between gap-3 pt-1">
            {/* Role Pills */}
            <div className="flex flex-wrap items-center gap-1.5 bg-slate-100/70 p-1 rounded-xl border border-slate-200/50">
              {roleFilters.map((role) => (
                <button
                  key={role.value}
                  type="button"
                  onClick={() => handleRoleChange(role.value)}
                  className={`px-3 py-1 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                    selectedRole === role.value
                      ? "bg-white text-blue-900 shadow-xs border border-slate-200/80"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  {role.label}
                </button>
              ))}
            </div>

            {/* Status Pills */}
            <div className="flex items-center gap-1.5 bg-slate-100/70 p-1 rounded-xl border border-slate-200/50">
              {statusFilters.map((st) => (
                <button
                  key={st.value}
                  type="button"
                  onClick={() => handleStatusChange(st.value)}
                  className={`px-3 py-1 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                    selectedStatus === st.value
                      ? "bg-white text-blue-900 shadow-xs border border-slate-200/80"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  {st.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Interactive Users Data Table */}
        <div className="overflow-x-auto relative min-h-[300px]">
          {isPending && (
            <div className="absolute inset-0 bg-white/60 backdrop-blur-xs flex items-center justify-center z-10">
              <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-xl shadow-md border border-slate-200 text-xs font-semibold text-slate-700">
                <RefreshCwIcon className="w-4 h-4 animate-spin text-blue-600" />
                <span>Updating records...</span>
              </div>
            </div>
          )}

          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50/80 text-slate-500 font-semibold border-b border-slate-100 uppercase tracking-wider text-[11px]">
              <tr>
                <th className="py-3.5 px-5">User</th>
                <th className="py-3.5 px-4">Roles</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-center">Reputation</th>
                <th className="py-3.5 px-4">Registered</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100 text-slate-700">
              {items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-16 text-center text-slate-400">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <UsersIcon className="w-8 h-8 text-slate-300" />
                      <p className="text-sm font-semibold text-slate-600">
                        No matching user accounts found
                      </p>
                      <p className="text-xs text-slate-400">
                        Try adjusting your search terms or active filters.
                      </p>
                      {(search ||
                        selectedRole !== "all" ||
                        selectedStatus !== "all") && (
                        <button
                          type="button"
                          onClick={() => {
                            setSearch("");
                            setSelectedRole("all");
                            setSelectedStatus("all");
                            fetchUsers("", "all", "all", sortBy, 1, pageSize);
                          }}
                          className="mt-2 text-xs font-semibold text-blue-600 hover:underline cursor-pointer"
                        >
                          Clear all filters
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                items.map((u) => {
                  const formattedDate = new Date(
                    u.createdAt,
                  ).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    year: "numeric",
                  });

                  return (
                    <tr
                      key={u.id}
                      className="hover:bg-slate-50/80 transition-colors group cursor-pointer"
                      onClick={() => handleInspectUser(u)}
                    >
                      {/* User Avatar + Name + Email */}
                      <td className="py-3.5 px-5">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center overflow-hidden shrink-0 border border-blue-200/60 font-semibold text-xs">
                            {u.avatarUrl ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img
                                src={u.avatarUrl}
                                alt={`${u.firstName} ${u.lastName}`}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              `${u.firstName.charAt(0)}${u.lastName.charAt(0)}`
                            )}
                          </div>
                          <div className="min-w-0">
                            <p className="font-semibold text-slate-900 group-hover:text-blue-600 transition-colors truncate">
                              {u.firstName} {u.lastName}
                            </p>
                            <p className="text-[11px] text-slate-400 truncate">
                              {u.email}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Roles */}
                      <td className="py-3.5 px-4">
                        <div className="flex flex-wrap gap-1">
                          {u.roles.map((r) => (
                            <RoleBadge key={r} role={r} size="sm" />
                          ))}
                        </div>
                      </td>

                      {/* Status */}
                      <td className="py-3.5 px-4">
                        <StatusBadge
                          isActive={u.isActive}
                          isDeleted={u.isDeleted}
                        />
                      </td>

                      {/* Reputation */}
                      <td className="py-3.5 px-4 text-center">
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold font-mono bg-amber-50 text-amber-800 border border-amber-200/70">
                          <AwardIcon className="w-3 h-3 text-amber-500" />
                          {u.reputationPoints}
                        </span>
                      </td>

                      {/* Joined Date */}
                      <td className="py-3.5 px-4 text-slate-500 whitespace-nowrap">
                        {formattedDate}
                      </td>

                      {/* Action Menu */}
                      <td
                        className="py-3.5 px-5 text-right relative"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            type="button"
                            onClick={() => handleInspectUser(u)}
                            className="px-2.5 py-1 text-xs font-semibold bg-white hover:bg-slate-100 text-slate-700 rounded-lg border border-slate-200/80 shadow-xs transition-colors cursor-pointer"
                          >
                            Inspect
                          </button>

                          <div className="relative">
                            <button
                              type="button"
                              onClick={() =>
                                setActiveMenuUserId(
                                  activeMenuUserId === u.id ? null : u.id,
                                )
                              }
                              className="p-1 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
                            >
                              <MoreVerticalIcon className="w-4 h-4" />
                            </button>

                            {activeMenuUserId === u.id && (
                              <div className="absolute right-0 top-full mt-1 w-44 bg-white rounded-xl shadow-lg border border-slate-200 py-1 z-30 text-left">
                                <button
                                  type="button"
                                  onClick={() => handleOpenReputation(u)}
                                  className="w-full px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                >
                                  <AwardIcon className="w-3.5 h-3.5 text-amber-500" />
                                  <span>Adjust points</span>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleOpenResetPassword(u)}
                                  className="w-full px-3 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 flex items-center gap-2 cursor-pointer"
                                >
                                  <KeyIcon className="w-3.5 h-3.5 text-indigo-500" />
                                  <span>Reset password</span>
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Toolbar */}
        <div className="p-4 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-600 bg-slate-50/40">
          <div className="flex items-center gap-2">
            <span>
              Showing{" "}
              <span className="font-semibold text-slate-900">
                {items.length}
              </span>{" "}
              of{" "}
              <span className="font-semibold text-slate-900">{totalCount}</span>{" "}
              accounts
            </span>
            <span className="text-slate-300">•</span>
            <select
              value={pageSize}
              onChange={(e) =>
                handlePageSizeChange(parseInt(e.target.value, 10))
              }
              className="px-2 py-1 bg-white border border-slate-200 rounded-lg outline-none cursor-pointer"
            >
              <option value={10}>10 per page</option>
              <option value={25}>25 per page</option>
              <option value={50}>50 per page</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-slate-500">
              Page {page} of {totalPages}
            </span>
            <div className="flex items-center gap-1">
              <button
                type="button"
                disabled={page <= 1}
                onClick={() => handlePageChange(page - 1)}
                className="p-1.5 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer"
                aria-label="Previous page"
              >
                <ChevronLeftIcon className="w-4 h-4" />
              </button>
              <button
                type="button"
                disabled={page >= totalPages}
                onClick={() => handlePageChange(page + 1)}
                className="p-1.5 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors cursor-pointer"
                aria-label="Next page"
              >
                <ChevronRightIcon className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Inspector Slide-over Drawer */}
      <UserDrawer
        user={selectedUser}
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        onUserUpdated={() => fetchUsers()}
        onOpenReputationModal={handleOpenReputation}
        onOpenResetPasswordModal={handleOpenResetPassword}
      />

      {/* Add User Modal */}
      <AddUserModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onUserCreated={() => fetchUsers()}
      />

      {/* Adjust Reputation Modal */}
      <AdjustReputationModal
        user={selectedUser}
        isOpen={isReputationModalOpen}
        onClose={() => setIsReputationModalOpen(false)}
        onSuccess={() => fetchUsers()}
      />

      {/* Reset Password Modal */}
      <ResetPasswordModal
        user={selectedUser}
        isOpen={isResetPasswordModalOpen}
        onClose={() => setIsResetPasswordModalOpen(false)}
        onSuccess={() => fetchUsers()}
      />
    </div>
  );
}
