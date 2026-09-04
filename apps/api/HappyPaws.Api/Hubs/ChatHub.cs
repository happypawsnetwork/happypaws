using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace HappyPaws.Api.Hubs;

[Authorize]
public class ChatHub : Hub
{
    private readonly IApplicationDbContext _context;

    public ChatHub(IApplicationDbContext context)
    {
        _context = context;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"User_{userId}");
        }
        await base.OnConnectedAsync();
    }

    public async Task SendDirectMessage(long recipientId, string content, string? messageType = "Text", double? latitude = null, double? longitude = null)
    {
        var senderIdStr = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(senderIdStr) || !long.TryParse(senderIdStr, out var senderId))
        {
            throw new HubException("Unauthorized");
        }

        var sender = await _context.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == senderId);
        var recipient = await _context.Users.FirstOrDefaultAsync(u => u.Id == recipientId);

        if (sender == null || recipient == null)
        {
            throw new HubException("User not found");
        }

        bool isSelf = senderId == recipientId;

        if (!isSelf)
        {
            // First check if either user has blocked the other
            bool iBlocked = await _context.CanMessages
                .AnyAsync(c => c.FromUserId == recipientId && c.ToUserId == senderId && !c.IsAllowed, Context.ConnectionAborted);
            if (iBlocked)
            {
                throw new HubException("You have blocked this user. Unblock to send messages.");
            }

            bool theyBlocked = await _context.CanMessages
                .AnyAsync(c => c.FromUserId == senderId && c.ToUserId == recipientId && !c.IsAllowed, Context.ConnectionAborted);
            if (theyBlocked)
            {
                throw new HubException("You are blocked from messaging this user.");
            }

            bool isAdmin = sender.Roles.Any(r => r.RoleName == RoleName.Administrator);

            if (!isAdmin)
            {
                bool recipientIsAdmin = await _context.UserRoles.AnyAsync(r => r.UserId == recipientId && r.RoleName == RoleName.Administrator, Context.ConnectionAborted);
                if (recipientIsAdmin)
                {
                    // Users cannot message admins unless admin messaged them first
                    var adminMessagedFirst = await _context.CanMessages
                        .AnyAsync(c => c.FromUserId == senderId && c.ToUserId == recipientId && c.IsAllowed, Context.ConnectionAborted);

                    if (!adminMessagedFirst)
                    {
                        throw new HubException("You cannot initiate a conversation with an administrator.");
                    }
                }
                else
                {
                    if (!recipient.ReceiveMessages)
                    {
                        var whitelisted = await _context.CanMessages
                            .AnyAsync(c => c.FromUserId == senderId && c.ToUserId == recipientId && c.IsAllowed, Context.ConnectionAborted);

                        if (!whitelisted)
                        {
                            throw new HubException("This user is not accepting direct messages.");
                        }
                    }
                }
            }

            // Whitelist recipient so they can message the sender back even if sender has ReceiveMessages = false
            var replyPermission = await _context.CanMessages
                .FirstOrDefaultAsync(c => c.FromUserId == recipientId && c.ToUserId == senderId, Context.ConnectionAborted);

            if (replyPermission == null)
            {
                _context.CanMessages.Add(new CanMessage
                {
                    FromUserId = recipientId,
                    ToUserId = senderId,
                    IsAllowed = true
                });
            }
        }

        // Find or create thread
        ChatThread? thread = null;
        if (isSelf)
        {
            thread = await _context.ChatThreads
                .Include(t => t.Participants)
                .Where(t => t.IsDirectMessage && t.Participants.Count == 1 && t.Participants.Any(p => p.UserId == senderId))
                .FirstOrDefaultAsync();

            if (thread == null)
            {
                thread = new ChatThread { IsDirectMessage = true };
                thread.AddParticipant(new ChatParticipant { UserId = senderId });
                _context.ChatThreads.Add(thread);
                await _context.SaveChangesAsync(Context.ConnectionAborted);
            }
        }
        else
        {
            thread = await _context.ChatThreads
                .Include(t => t.Participants)
                .Where(t => t.IsDirectMessage && t.Participants.Count == 2 && t.Participants.Any(p => p.UserId == senderId) && t.Participants.Any(p => p.UserId == recipientId))
                .FirstOrDefaultAsync();

            if (thread == null)
            {
                thread = new ChatThread { IsDirectMessage = true };
                thread.AddParticipant(new ChatParticipant { UserId = senderId });
                thread.AddParticipant(new ChatParticipant { UserId = recipientId });
                _context.ChatThreads.Add(thread);
                await _context.SaveChangesAsync(Context.ConnectionAborted);
            }
        }

        var parsedType = Enum.TryParse<MessageType>(messageType, true, out var type) ? type : MessageType.Text;
        if (parsedType != MessageType.Location || latitude == 0 && longitude == 0)
        {
            latitude = null;
            longitude = null;
        }

        var message = new Message
        {
            ThreadId = thread.Id,
            SenderId = senderId,
            MessageType = parsedType,
            Content = content,
            Latitude = latitude,
            Longitude = longitude,
            SentAt = DateTimeOffset.UtcNow,
            DeliveredAt = isSelf ? DateTimeOffset.UtcNow : null,
            SeenAt = isSelf ? DateTimeOffset.UtcNow : null
        };

        _context.Messages.Add(message);

        thread.UpdatedAt = DateTimeOffset.UtcNow;
        await _context.SaveChangesAsync(Context.ConnectionAborted);

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
            // Only notify sender once for self-messages
            await Clients.Group($"User_{senderId}").SendAsync("ReceiveMessage", messageDto);
        }
        else
        {
            // Notify recipient
            await Clients.Group($"User_{recipientId}").SendAsync("ReceiveMessage", messageDto);

            // Notify sender's other clients (if any)
            await Clients.Group($"User_{senderId}").SendAsync("ReceiveMessage", messageDto);

            var recipientUnreadCount = await _context.Messages
                .CountAsync(m => m.SenderId != recipientId && m.SeenAt == null && !m.IsDeleted &&
                    _context.ChatParticipants.Any(p => p.ThreadId == m.ThreadId && p.UserId == recipientId &&
                        (p.ClearedAt == null || m.SentAt > p.ClearedAt.Value)), Context.ConnectionAborted);
            await Clients.Group($"User_{recipientId}").SendAsync("UnreadCountChanged", recipientUnreadCount);
        }
    }

    public async Task MarkMessageAsSeen(long messageId)
    {
        var userIdStr = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId)) return;

        var message = await _context.Messages.FirstOrDefaultAsync(m => m.Id == messageId);
        if (message != null && message.SenderId != userId && message.SeenAt == null)
        {
            message.SeenAt = DateTimeOffset.UtcNow;

            var participant = await _context.ChatParticipants.FirstOrDefaultAsync(p => p.ThreadId == message.ThreadId && p.UserId == userId);
            if (participant != null)
            {
                participant.LastReadAt = DateTimeOffset.UtcNow;
            }

            await _context.SaveChangesAsync(Context.ConnectionAborted);

            await Clients.Group($"User_{message.SenderId}").SendAsync("MessageSeen", message.Id, message.SeenAt);

            var userUnreadCount = await _context.Messages
                .CountAsync(m => m.SenderId != userId && m.SeenAt == null && !m.IsDeleted &&
                    _context.ChatParticipants.Any(p => p.ThreadId == m.ThreadId && p.UserId == userId &&
                        (p.ClearedAt == null || m.SentAt > p.ClearedAt.Value)), Context.ConnectionAborted);
            await Clients.Group($"User_{userId}").SendAsync("UnreadCountChanged", userUnreadCount);
        }
    }
}
