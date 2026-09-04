"use client";

import { useState } from "react";
import Image from "next/image";
import { AlertCircle, Image as ImageIcon } from "lucide-react";
import type { AdminCommunityPost } from "@/actions/community";
import { PostDetailModal } from "./PostDetailModal";

interface CommunityTableProps {
  posts: AdminCommunityPost[];
}

export function getTypeBadgeColor(type: string): string {
  switch (type) {
    case "RescueAlert":
    case "Rescue":
      return "bg-rose-50 text-rose-700 ring-rose-600/20";
    case "FosterUpdate":
    case "Update":
      return "bg-blue-50 text-blue-700 ring-blue-700/10";
    case "AdoptionListing":
    case "Find Home":
    case "Find home":
      return "bg-emerald-50 text-emerald-700 ring-emerald-600/20";
    case "Highlight":
      return "bg-amber-50 text-amber-700 ring-amber-600/20";
    case "TransportRequest":
    case "Transport":
      return "bg-indigo-50 text-indigo-700 ring-indigo-600/20";
    case "VetRequest":
    case "Treatment":
      return "bg-purple-50 text-purple-700 ring-purple-600/20";
    case "SponsorshipRequest":
    case "Sponsor":
      return "bg-teal-50 text-teal-700 ring-teal-600/20";
    default:
      return "bg-slate-50 text-slate-700 ring-slate-600/10";
  }
}

export function getTypeDisplayLabel(type: string): string {
  switch (type) {
    case "RescueAlert":
      return "Rescue";
    case "FosterUpdate":
      return "Update";
    case "AdoptionListing":
      return "Find home";
    case "Highlight":
      return "Highlight";
    case "TransportRequest":
      return "Transport";
    case "VetRequest":
      return "Treatment";
    case "SponsorshipRequest":
      return "Sponsor";
    default:
      return type;
  }
}

export function getStatusBadgeColor(status: string): string {
  switch (status) {
    case "Active":
      return "bg-emerald-50 text-emerald-700 ring-emerald-600/20";
    case "Fostered":
      return "bg-indigo-50 text-indigo-700 ring-indigo-600/20";
    case "Assigned":
      return "bg-blue-50 text-blue-700 ring-blue-700/10";
    case "Completed":
      return "bg-slate-100 text-slate-700 ring-slate-600/10";
    case "PendingApproval":
      return "bg-amber-50 text-amber-700 ring-amber-600/20";
    case "Funded":
      return "bg-teal-50 text-teal-700 ring-teal-600/20";
    case "Rejected":
    case "Deleted":
      return "bg-rose-50 text-rose-700 ring-rose-600/20";
    case "Cancelled":
      return "bg-slate-100 text-slate-500 ring-slate-500/10";
    default:
      return "bg-slate-100 text-slate-700 ring-slate-600/10";
  }
}

export function CommunityTable({ posts }: CommunityTableProps) {
  const [selectedPost, setSelectedPost] = useState<AdminCommunityPost | null>(
    null,
  );

  return (
    <>
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xs">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Post
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Type
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Author
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Animal
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Status
                </th>
                <th
                  scope="col"
                  className="px-5 py-3.5 font-semibold text-xs uppercase tracking-wider"
                >
                  Posted
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 text-slate-900">
              {posts.map((post) => (
                <tr
                  key={post.id}
                  onClick={() => setSelectedPost(post)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      setSelectedPost(post);
                    }
                  }}
                  tabIndex={0}
                  role="button"
                  aria-label={`View and moderate ${post.title}`}
                  className={`cursor-pointer transition-colors hover:bg-slate-50/75 focus-visible:outline-none focus-visible:bg-slate-50 ${
                    post.isDeleted ? "bg-rose-50/30" : ""
                  }`}
                >
                  {/* Post thumbnail and title */}
                  <td className="px-5 py-4 max-w-sm">
                    <div className="flex items-start gap-3">
                      <div className="relative h-12 w-12 shrink-0 overflow-hidden rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center">
                        {post.firstPhotoUrl ? (
                          <Image
                            src={post.firstPhotoUrl}
                            alt={`Thumbnail for ${post.title}`}
                            fill
                            unoptimized
                            sizes="48px"
                            className="object-cover"
                          />
                        ) : (
                          <ImageIcon className="w-5 h-5 text-slate-400" />
                        )}
                        {post.photoCount > 1 && (
                          <span className="absolute bottom-0 right-0 bg-slate-900/80 text-[10px] text-white px-1 py-0.2 rounded-tl">
                            +{post.photoCount - 1}
                          </span>
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="font-semibold text-slate-900 truncate">
                          {post.title}
                        </div>
                        <p className="text-xs text-slate-500 line-clamp-1 mt-0.5">
                          {post.body}
                        </p>
                        {post.locationLabel && (
                          <span className="text-[11px] text-slate-400 block truncate mt-0.5">
                            📍 {post.locationLabel}
                          </span>
                        )}
                      </div>
                    </div>
                  </td>

                  {/* Post Type Badge */}
                  <td className="px-5 py-4 whitespace-nowrap">
                    <span
                      className={`inline-flex items-center rounded-md px-2.5 py-1 text-xs font-semibold ring-1 ring-inset ${getTypeBadgeColor(
                        post.type,
                      )}`}
                    >
                      {getTypeDisplayLabel(post.type)}
                    </span>
                  </td>

                  {/* Author */}
                  <td className="px-5 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">
                      {post.authorDisplayName}
                    </div>
                    {post.authorEmail && (
                      <div className="text-xs text-slate-500">
                        {post.authorEmail}
                      </div>
                    )}
                  </td>

                  {/* Animal & Urgency */}
                  <td className="px-5 py-4 whitespace-nowrap">
                    {post.animalName ? (
                      <div>
                        <div className="font-medium text-slate-900">
                          {post.animalName}
                        </div>
                        <div className="text-xs text-slate-500">
                          {post.animalSpecies || "Species unspecified"}
                        </div>
                      </div>
                    ) : (
                      <span className="text-xs text-slate-400">-</span>
                    )}
                    {post.urgencyLevel && (
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-600 mt-0.5">
                        <AlertCircle className="w-3 h-3" />
                        {post.urgencyLevel}
                      </span>
                    )}
                  </td>

                  {/* Status badge */}
                  <td className="px-5 py-4 whitespace-nowrap">
                    {post.isDeleted ? (
                      <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset bg-rose-50 text-rose-700 ring-rose-600/20">
                        Deleted
                      </span>
                    ) : (
                      <span
                        className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset ${getStatusBadgeColor(
                          post.status,
                        )}`}
                      >
                        {post.status}
                      </span>
                    )}
                  </td>

                  {/* Date Created */}
                  <td className="px-5 py-4 whitespace-nowrap text-xs text-slate-500">
                    {new Date(post.createdAt).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {selectedPost && (
        <PostDetailModal
          post={selectedPost}
          isOpen={Boolean(selectedPost)}
          onClose={() => setSelectedPost(null)}
        />
      )}
    </>
  );
}
