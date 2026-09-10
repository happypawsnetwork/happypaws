using HappyPaws.Api.Extensions;
using HappyPaws.Api.Hubs;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Linq;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Api.Features.Messaging;

public sealed class MessagingEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/messaging")
            .WithTags("Messaging")
            .RequireAuthorization();

        group.MapGet("/threads", GetThreadsAsync)
            .WithName("GetChatThreads");

        group.MapPost("/threads/direct/{targetUserId:long}", FindOrCreateDirectThreadAsync)
            .WithName("FindOrCreateDirectThread");

        group.MapPost("/threads/direct/{targetUserId:long}/messages", SendDirectMessageHttpAsync)
            .WithName("SendDirectMessageHttp");

        group.MapGet("/threads/{id:long}/messages", GetMessagesAsync)
            .WithName("GetChatMessages");

        group.MapDelete("/threads/{id:long}", DeleteThreadAsync)
            .WithName("DeleteChatThread");

        group.MapGet("/can-message/{targetUserId:long}", CanMessageUserAsync)
            .WithName("CheckCanMessageUser");

        group.MapPost("/block/{targetUserId:long}", BlockUserAsync)
            .WithName("BlockUser");

        group.MapPost("/unblock/{targetUserId:long}", UnblockUserAsync)
            .WithName("UnblockUser");

        group.MapGet("/blocked", GetBlockedUsersAsync)
            .WithName("GetBlockedUsers");

        group.MapGet("/unread-count", GetUnreadCountAsync)
            .WithName("GetUnreadMessagesCount");
    }

    private static async Task<IResult> GetUnreadCountAsync(IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var unreadCount = await db.Messages
            .CountAsync(m => m.SenderId != userId && m.SeenAt == null && !m.IsDeleted &&
                db.ChatParticipants.Any(p => p.ThreadId == m.ThreadId && p.UserId == userId &&
                    (p.ClearedAt == null || m.SentAt > p.ClearedAt.Value)), context.RequestAborted);

        return Results.Ok(new { UnreadCount = unreadCount });
    }

    private static async Task<IResult> GetThreadsAsync(IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        // Only return threads that contain at least one message visible to this user
        var threads = await db.ChatThreads
            .Where(t => t.Participants.Any(p => p.UserId == userId &&
                t.Messages.Any(m => !m.IsDeleted && (p.ClearedAt == null || m.SentAt > p.ClearedAt))))
            .OrderByDescending(t => t.UpdatedAt)
            .Select(t => new
            {
                t.Id,
                t.IsDirectMessage,
                t.UpdatedAt,
                IsSelf = t.IsDirectMessage && t.Participants.Count == 1 && t.Participants.Any(p => p.UserId == userId),
                OtherParticipant = t.Participants
                    .Where(p => t.Participants.Count == 1 ? p.UserId == userId : p.UserId != userId)
                    .Select(p => new
                    {
                        p.UserId,
                        p.User.FirstName,
                        p.User.LastName,
                        p.User.AvatarUrl,
                        p.User.Email,
                        IsSelf = t.Participants.Count == 1 && p.UserId == userId,
                        IsVerified = p.User.Roles.Any(r => r.IsVerified)
                    })
                    .FirstOrDefault(),
                LastMessage = t.Messages
                    .Where(m => !m.IsDeleted && !t.Participants.Any(p => p.UserId == userId && p.ClearedAt != null && m.SentAt <= p.ClearedAt))
                    .OrderByDescending(m => m.SentAt)
                    .Select(m => new { m.Id, m.ThreadId, m.Content, m.MessageType, m.SentAt, m.DeliveredAt, m.SeenAt, m.SenderId })
                    .FirstOrDefault(),
                UnreadCount = t.Messages.Count(m => m.SenderId != userId && m.SeenAt == null && !m.IsDeleted &&
                    !t.Participants.Any(p => p.UserId == userId && p.ClearedAt != null && m.SentAt <= p.ClearedAt))
            })
            .ToListAsync(context.RequestAborted);

        return Results.Ok(threads);
    }

    private static async Task<IResult> GetMessagesAsync(long id, IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var participant = await db.ChatParticipants
            .FirstOrDefaultAsync(p => p.ThreadId == id && p.UserId == userId, context.RequestAborted);

        if (participant == null)
            return Results.Forbid();

        var query = db.Messages.Where(m => m.ThreadId == id && !m.IsDeleted);
        if (participant.ClearedAt.HasValue)
        {
            query = query.Where(m => m.SentAt > participant.ClearedAt.Value);
        }

        var messages = await query
            .OrderBy(m => m.SentAt)
            .Select(m => new
            {
                m.Id,
                m.ThreadId,
                m.SenderId,
                m.MessageType,
                m.Content,
                m.Latitude,
                m.Longitude,
                m.SentAt,
                m.DeliveredAt,
                m.SeenAt
            })
            .ToListAsync(context.RequestAborted);

        return Results.Ok(messages);
    }

    private static async Task<IResult> DeleteThreadAsync(long id, IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var participant = await db.ChatParticipants
            .FirstOrDefaultAsync(p => p.ThreadId == id && p.UserId == userId, context.RequestAborted);

        if (participant == null)
            return Results.NotFound();

        participant.ClearedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(context.RequestAborted);

        return Results.NoContent();
    }

    private static async Task<IResult> FindOrCreateDirectThreadAsync(long targetUserId, IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var otherUser = await db.Users
            .Where(u => u.Id == targetUserId)
            .Select(u => new
            {
                UserId = u.Id,
                u.FirstName,
                u.LastName,
                u.AvatarUrl,
                u.Email
            })
            .FirstOrDefaultAsync(context.RequestAborted);

        if (otherUser == null)
            return Results.NotFound(new { error = "User not found." });

        bool isSelf = userId == targetUserId;

        if (isSelf)
        {
            var selfThread = await db.ChatThreads
                .Where(t => t.IsDirectMessage && t.Participants.Count == 1 && t.Participants.Any(p => p.UserId == userId))
                .Select(t => new { t.Id })
                .FirstOrDefaultAsync(context.RequestAborted);

            if (selfThread != null)
            {
                return Results.Ok(new
                {
                    ThreadId = selfThread.Id,
                    IsSelf = true,
                    OtherParticipant = new
                    {
                        otherUser.UserId,
                        otherUser.FirstName,
                        otherUser.LastName,
                        otherUser.AvatarUrl,
                        otherUser.Email,
                        IsSelf = true
                    }
                });
            }

            var newSelfThread = new HappyPaws.Domain.Entities.ChatThread { IsDirectMessage = true };
            newSelfThread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = userId });
            db.ChatThreads.Add(newSelfThread);
            await db.SaveChangesAsync(context.RequestAborted);

            return Results.Ok(new
            {
                ThreadId = newSelfThread.Id,
                IsSelf = true,
                OtherParticipant = new
                {
                    otherUser.UserId,
                    otherUser.FirstName,
                    otherUser.LastName,
                    otherUser.AvatarUrl,
                    otherUser.Email,
                    IsSelf = true
                }
            });
        }

        // Check admin permissions
        var caller = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == userId, context.RequestAborted);
        bool isCallerAdmin = caller?.Roles.Any(r => r.RoleName == RoleName.Administrator) == true;

        if (!isCallerAdmin)
        {
            bool isTargetAdmin = await db.UserRoles.AnyAsync(r => r.UserId == targetUserId && r.RoleName == RoleName.Administrator, context.RequestAborted);
            if (isTargetAdmin)
            {
                bool adminMessagedFirst = await db.CanMessages.AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && c.IsAllowed, context.RequestAborted);
                if (!adminMessagedFirst)
                {
                    return Results.Problem(statusCode: 403, title: "Forbidden", detail: "You cannot initiate a conversation with an administrator.");
                }
            }
        }

        var thread = await db.ChatThreads
            .Where(t => t.IsDirectMessage && t.Participants.Count == 2 && t.Participants.Any(p => p.UserId == userId) && t.Participants.Any(p => p.UserId == targetUserId))
            .Select(t => new { t.Id })
            .FirstOrDefaultAsync(context.RequestAborted);

        if (thread != null)
        {
            return Results.Ok(new
            {
                ThreadId = thread.Id,
                IsSelf = false,
                OtherParticipant = otherUser
            });
        }

        var newThread = new HappyPaws.Domain.Entities.ChatThread { IsDirectMessage = true };
        newThread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = userId });
        newThread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = targetUserId });

        db.ChatThreads.Add(newThread);
        await db.SaveChangesAsync(context.RequestAborted);

        return Results.Ok(new
        {
            ThreadId = newThread.Id,
            IsSelf = false,
            OtherParticipant = otherUser
        });
    }

    private static async Task<IResult> CanMessageUserAsync(long targetUserId, IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        if (userId == targetUserId)
            return Results.Ok(new { CanMessage = true, Reason = (string?)null, IBlocked = false, TheyBlocked = false });

        var caller = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == userId, context.RequestAborted);
        var target = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == targetUserId, context.RequestAborted);

        if (caller == null || target == null)
            return Results.NotFound(new { Message = "User not found" });

        // Check blocking in both directions
        bool iBlocked = await db.CanMessages
            .AnyAsync(c => c.FromUserId == targetUserId && c.ToUserId == userId && !c.IsAllowed, context.RequestAborted);

        bool theyBlocked = await db.CanMessages
            .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && !c.IsAllowed, context.RequestAborted);

        if (iBlocked)
        {
            return Results.Ok(new
            {
                CanMessage = false,
                Reason = "You have blocked this user.",
                IBlocked = true,
                TheyBlocked = theyBlocked
            });
        }

        if (theyBlocked)
        {
            return Results.Ok(new
            {
                CanMessage = false,
                Reason = "You cannot send or receive messages from this user.",
                IBlocked = false,
                TheyBlocked = true
            });
        }

        bool isCallerAdmin = caller.Roles.Any(r => r.RoleName == HappyPaws.Domain.Enums.RoleName.Administrator);
        if (isCallerAdmin)
        {
            return Results.Ok(new { CanMessage = true, Reason = (string?)null, IBlocked = false, TheyBlocked = false });
        }

        bool isTargetAdmin = target.Roles.Any(r => r.RoleName == HappyPaws.Domain.Enums.RoleName.Administrator);
        if (isTargetAdmin)
        {
            bool adminMessagedFirst = await db.CanMessages
                .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && c.IsAllowed, context.RequestAborted);

            if (!adminMessagedFirst)
            {
                return Results.Ok(new { CanMessage = false, Reason = "You cannot initiate a conversation with an administrator.", IBlocked = false, TheyBlocked = false });
            }
            return Results.Ok(new { CanMessage = true, Reason = (string?)null, IBlocked = false, TheyBlocked = false });
        }

        if (!target.ReceiveMessages)
        {
            bool isWhitelisted = await db.CanMessages
                .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && c.IsAllowed, context.RequestAborted);

            if (!isWhitelisted)
            {
                return Results.Ok(new { CanMessage = false, Reason = "This user does not accept direct messages.", IBlocked = false, TheyBlocked = false });
            }
        }

        return Results.Ok(new { CanMessage = true, Reason = (string?)null, IBlocked = false, TheyBlocked = false });
    }

    private static async Task<IResult> BlockUserAsync(
        long targetUserId,
        IApplicationDbContext db,
        IHubContext<ChatHub> hubContext,
        HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        if (userId == targetUserId)
            return Results.BadRequest(new { Message = "You cannot block yourself." });

        // Record that target cannot message caller: FromUserId = targetUserId, ToUserId = userId, IsAllowed = false
        var existing = await db.CanMessages
            .FirstOrDefaultAsync(c => c.FromUserId == targetUserId && c.ToUserId == userId, context.RequestAborted);

        if (existing == null)
        {
            db.CanMessages.Add(new HappyPaws.Domain.Entities.CanMessage
            {
                FromUserId = targetUserId,
                ToUserId = userId,
                IsAllowed = false
            });
        }
        else
        {
            existing.IsAllowed = false;
        }

        await db.SaveChangesAsync(context.RequestAborted);

        // Notify both parties in real time via SignalR
        bool targetBlocksCaller = await db.CanMessages
            .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && !c.IsAllowed, context.RequestAborted);

        await hubContext.Clients.Group($"User_{userId}").SendAsync("UserBlockStatusChanged", new
        {
            TargetUserId = targetUserId,
            IBlocked = true,
            TheyBlocked = targetBlocksCaller
        }, context.RequestAborted);

        await hubContext.Clients.Group($"User_{targetUserId}").SendAsync("UserBlockStatusChanged", new
        {
            TargetUserId = userId,
            IBlocked = targetBlocksCaller,
            TheyBlocked = true
        }, context.RequestAborted);

        return Results.Ok(new { Message = "User blocked successfully" });
    }

    private static async Task<IResult> UnblockUserAsync(
        long targetUserId,
        IApplicationDbContext db,
        IHubContext<ChatHub> hubContext,
        HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var existing = await db.CanMessages
            .FirstOrDefaultAsync(c => c.FromUserId == targetUserId && c.ToUserId == userId, context.RequestAborted);

        if (existing != null)
        {
            db.CanMessages.Remove(existing);
            await db.SaveChangesAsync(context.RequestAborted);
        }

        // Notify both parties in real time via SignalR
        bool targetBlocksCaller = await db.CanMessages
            .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && !c.IsAllowed, context.RequestAborted);

        await hubContext.Clients.Group($"User_{userId}").SendAsync("UserBlockStatusChanged", new
        {
            TargetUserId = targetUserId,
            IBlocked = false,
            TheyBlocked = targetBlocksCaller
        }, context.RequestAborted);

        await hubContext.Clients.Group($"User_{targetUserId}").SendAsync("UserBlockStatusChanged", new
        {
            TargetUserId = userId,
            IBlocked = targetBlocksCaller,
            TheyBlocked = false
        }, context.RequestAborted);

        return Results.Ok(new { Message = "User unblocked successfully" });
    }

    private static async Task<IResult> GetBlockedUsersAsync(IApplicationDbContext db, HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var blockedUsers = await db.CanMessages
            .Where(c => c.ToUserId == userId && !c.IsAllowed)
            .Include(c => c.FromUser)
            .Select(c => new
            {
                c.FromUserId,
                c.FromUser.FirstName,
                c.FromUser.LastName,
                c.FromUser.Username,
                c.FromUser.AvatarUrl,
                BlockedAt = c.UpdatedAt
            })
            .ToListAsync();

        return Results.Ok(blockedUsers);
    }

    private static async Task<IResult> SendDirectMessageHttpAsync(
        long targetUserId,
        SendMessageDto request,
        IApplicationDbContext db,
        IHubContext<ChatHub> hubContext,
        HttpContext context)
    {
        var userIdStr = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
            return Results.Unauthorized();

        var sender = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == userId, context.RequestAborted);
        var recipient = await db.Users.FirstOrDefaultAsync(u => u.Id == targetUserId, context.RequestAborted);

        if (sender == null || recipient == null)
            return Results.NotFound(new { error = "User not found" });

        bool isSelf = userId == targetUserId;

        if (!isSelf)
        {
            // First check if either user has blocked the other
            bool iBlocked = await db.CanMessages
                .AnyAsync(c => c.FromUserId == targetUserId && c.ToUserId == userId && !c.IsAllowed, context.RequestAborted);
            if (iBlocked)
            {
                return Results.Problem(statusCode: 403, title: "Forbidden", detail: "You have blocked this user. Unblock to send messages.");
            }

            bool theyBlocked = await db.CanMessages
                .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && !c.IsAllowed, context.RequestAborted);
            if (theyBlocked)
            {
                return Results.Problem(statusCode: 403, title: "Forbidden", detail: "You cannot message this user.");
            }

            bool isAdmin = sender.Roles.Any(r => r.RoleName == RoleName.Administrator);
            if (!isAdmin)
            {
                bool recipientIsAdmin = await db.UserRoles.AnyAsync(r => r.UserId == targetUserId && r.RoleName == RoleName.Administrator, context.RequestAborted);
                if (recipientIsAdmin)
                {
                    bool adminMessagedFirst = await db.CanMessages
                        .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && c.IsAllowed, context.RequestAborted);
                    if (!adminMessagedFirst)
                    {
                        return Results.Problem(statusCode: 403, title: "Forbidden", detail: "You cannot initiate a conversation with an administrator.");
                    }
                }
                else
                {
                    if (!recipient.ReceiveMessages)
                    {
                        bool whitelisted = await db.CanMessages
                            .AnyAsync(c => c.FromUserId == userId && c.ToUserId == targetUserId && c.IsAllowed, context.RequestAborted);
                        if (!whitelisted)
                        {
                            return Results.Problem(statusCode: 403, title: "Forbidden", detail: "This user is not accepting direct messages.");
                        }
                    }
                }
            }

            var replyPermission = await db.CanMessages
                .FirstOrDefaultAsync(c => c.FromUserId == targetUserId && c.ToUserId == userId, context.RequestAborted);
            if (replyPermission == null)
            {
                db.CanMessages.Add(new HappyPaws.Domain.Entities.CanMessage
                {
                    FromUserId = targetUserId,
                    ToUserId = userId,
                    IsAllowed = true
                });
            }
        }

        HappyPaws.Domain.Entities.ChatThread? thread = null;
        if (isSelf)
        {
            thread = await db.ChatThreads
                .Include(t => t.Participants)
                .Where(t => t.IsDirectMessage && t.Participants.Count == 1 && t.Participants.Any(p => p.UserId == userId))
                .FirstOrDefaultAsync(context.RequestAborted);

            if (thread == null)
            {
                thread = new HappyPaws.Domain.Entities.ChatThread { IsDirectMessage = true };
                thread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = userId });
                db.ChatThreads.Add(thread);
                await db.SaveChangesAsync(context.RequestAborted);
            }
        }
        else
        {
            thread = await db.ChatThreads
                .Include(t => t.Participants)
                .Where(t => t.IsDirectMessage && t.Participants.Count == 2 && t.Participants.Any(p => p.UserId == userId) && t.Participants.Any(p => p.UserId == targetUserId))
                .FirstOrDefaultAsync(context.RequestAborted);

            if (thread == null)
            {
                thread = new HappyPaws.Domain.Entities.ChatThread { IsDirectMessage = true };
                thread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = userId });
                thread.AddParticipant(new HappyPaws.Domain.Entities.ChatParticipant { UserId = targetUserId });
                db.ChatThreads.Add(thread);
                await db.SaveChangesAsync(context.RequestAborted);
            }
        }

        var parsedType = Enum.TryParse<MessageType>(request.MessageType, true, out var type) ? type : MessageType.Text;
        double? lat = request.Latitude;
        double? lng = request.Longitude;
        if (parsedType != MessageType.Location || (lat == 0 && lng == 0))
        {
            lat = null;
            lng = null;
        }

        var message = new HappyPaws.Domain.Entities.Message
        {
            ThreadId = thread.Id,
            SenderId = userId,
            MessageType = parsedType,
            Content = request.Content,
            Latitude = lat,
            Longitude = lng,
            SentAt = DateTimeOffset.UtcNow,
            DeliveredAt = isSelf ? DateTimeOffset.UtcNow : null,
            SeenAt = isSelf ? DateTimeOffset.UtcNow : null
        };

        db.Messages.Add(message);
        thread.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(context.RequestAborted);

        var messageDto = new
        {
            message.Id,
            message.ThreadId,
            message.SenderId,
            SenderName = $"{sender.FirstName} {sender.LastName}",
            SenderAvatarUrl = sender.AvatarUrl,
            message.MessageType,
            message.Content,
            message.Latitude,
            message.Longitude,
            message.SentAt,
            message.DeliveredAt,
            message.SeenAt
        };

        if (isSelf)
        {
            await hubContext.Clients.Group($"User_{userId}").SendAsync("ReceiveMessage", messageDto, context.RequestAborted);
        }
        else
        {
            await hubContext.Clients.Group($"User_{targetUserId}").SendAsync("ReceiveMessage", messageDto, context.RequestAborted);
            await hubContext.Clients.Group($"User_{userId}").SendAsync("ReceiveMessage", messageDto, context.RequestAborted);

            var recipientUnreadCount = await db.Messages
                .CountAsync(m => m.SenderId != targetUserId && m.SeenAt == null && !m.IsDeleted &&
                    db.ChatParticipants.Any(p => p.ThreadId == m.ThreadId && p.UserId == targetUserId &&
                        (p.ClearedAt == null || m.SentAt > p.ClearedAt.Value)), context.RequestAborted);
            await hubContext.Clients.Group($"User_{targetUserId}").SendAsync("UnreadCountChanged", recipientUnreadCount, context.RequestAborted);
        }

        return Results.Ok(messageDto);
    }
}

public sealed record SendMessageDto(string Content, string? MessageType = "Text", double? Latitude = null, double? Longitude = null);
