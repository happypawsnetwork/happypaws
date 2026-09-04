using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Features.Admin;

public sealed class AdminAnalyticsEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/analytics")
            .WithTags("Admin Analytics")
            .RequireAuthorization();

        group.MapGet("/user-growth", GetUserGrowthAnalyticsAsync)
            .WithName("GetUserGrowthAnalytics")
            .WithSummary("Get user growth analytics for admin dashboard")
            .WithDescription("Retrieves dual-axis user growth metrics including new registrations per interval, cumulative total user count, and timeframe and frequency aggregations based on real database records.")
            .Produces<UserGrowthAnalyticsResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("/roles-summary", GetRoleDistributionAsync)
            .WithName("GetRoleDistributionSummary")
            .WithSummary("Get user role distribution summary")
            .WithDescription("Retrieves the real count of users assigned to each system role across the platform.")
            .Produces<RoleDistributionResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);
    }

    private static async Task<Results<Ok<UserGrowthAnalyticsResponse>, UnauthorizedHttpResult>> GetUserGrowthAnalyticsAsync(
        string? timeframe,
        string? frequency,
        IApplicationDbContext db,
        ILogger<AdminAnalyticsEndpoints> logger,
        CancellationToken ct)
    {
        var selectedTimeframe = (timeframe?.ToLowerInvariant()) switch
        {
            "7d" => "7d",
            "90d" => "90d",
            "1y" => "1y",
            "all" => "all",
            _ => "30d"
        };

        var selectedFrequency = (frequency?.ToLowerInvariant()) switch
        {
            "weekly" => "weekly",
            "monthly" => "monthly",
            _ => "daily"
        };

        logger.LogInformation("[AdminAnalytics] Fetching real user growth metrics for timeframe {Timeframe} and frequency {Frequency}", selectedTimeframe, selectedFrequency);

        var now = DateTimeOffset.UtcNow;

        // Retrieve real users from database with AsNoTracking to minimize memory overhead
        var allUsers = await db.Users
            .AsNoTracking()
            .Where(u => !u.IsDeleted)
            .OrderBy(u => u.CreatedAt)
            .ToListAsync(ct);

        int totalUsers = allUsers.Count;
        int activeUsers = allUsers.Count(u => u.IsActive);

        var startDate = selectedTimeframe switch
        {
            "7d" => now.AddDays(-7),
            "30d" => now.AddDays(-30),
            "90d" => now.AddDays(-90),
            "1y" => now.AddYears(-1),
            "all" => allUsers.Count > 0 ? allUsers.First().CreatedAt : now.AddDays(-30),
            _ => now.AddDays(-30)
        };

        var usersInPeriod = selectedTimeframe == "all"
            ? allUsers
            : allUsers.Where(u => u.CreatedAt >= startDate).ToList();

        var grouped = usersInPeriod
            .GroupBy(u => GetBucketKey(u.CreatedAt.UtcDateTime, selectedFrequency))
            .ToDictionary(g => g.Key, g => g.Count());

        var startUtc = startDate.UtcDateTime;
        var bucketDates = GetBucketSequence(startUtc, now.UtcDateTime, selectedFrequency);

        var dataPoints = new List<UserGrowthDataPoint>();
        int cumulative = allUsers.Count(u => u.CreatedAt.UtcDateTime < bucketDates.FirstOrDefault());

        foreach (var dt in bucketDates)
        {
            var key = GetBucketKey(dt, selectedFrequency);
            int newRegs = grouped.TryGetValue(key, out var count) ? count : 0;
            cumulative += newRegs;

            dataPoints.Add(new UserGrowthDataPoint(
                Date: dt.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                Label: FormatBucketLabel(dt, selectedFrequency),
                NewRegistrations: newRegs,
                TotalUsers: cumulative
            ));
        }

        int newUsersInPeriod = dataPoints.Sum(d => d.NewRegistrations);
        int usersBeforePeriod = allUsers.Count(u => u.CreatedAt < startDate);

        double growthRate = usersBeforePeriod > 0
            ? Math.Round(((double)newUsersInPeriod / usersBeforePeriod) * 100, 1)
            : (newUsersInPeriod > 0 ? 100.0 : 0.0);

        var response = new UserGrowthAnalyticsResponse(
            TotalUsers: totalUsers,
            NewUsersInPeriod: newUsersInPeriod,
            ActiveUsersCount: activeUsers,
            GrowthRatePercentage: growthRate,
            Timeframe: selectedTimeframe,
            Frequency: selectedFrequency,
            DataPoints: dataPoints
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<RoleDistributionResponse>, UnauthorizedHttpResult>> GetRoleDistributionAsync(
        IApplicationDbContext db,
        ILogger<AdminAnalyticsEndpoints> logger,
        CancellationToken ct)
    {
        logger.LogInformation("[AdminAnalytics] Fetching role distribution summary");

        var roleCounts = await db.UserRoles
            .AsNoTracking()
            .GroupBy(r => r.RoleName)
            .Select(g => new { Role = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Role, x => x.Count, ct);

        var allRoles = Enum.GetValues<RoleName>();
        var items = new List<RoleCountDto>();

        foreach (var role in allRoles)
        {
            items.Add(new RoleCountDto(
                Role: role.ToString(),
                Count: roleCounts.TryGetValue(role, out var count) ? count : 0
            ));
        }

        int totalAssigned = items.Sum(i => i.Count);

        return TypedResults.Ok(new RoleDistributionResponse(
            TotalRolesAssigned: totalAssigned,
            Roles: items
        ));
    }

    private static string GetBucketKey(DateTime dt, string frequency)
    {
        return frequency switch
        {
            "weekly" => $"{dt.Year}-W{CultureInfo.InvariantCulture.Calendar.GetWeekOfYear(dt, CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday)}",
            "monthly" => dt.ToString("yyyy-MM", CultureInfo.InvariantCulture),
            _ => dt.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
        };
    }

    private static string FormatBucketLabel(DateTime dt, string frequency)
    {
        return frequency switch
        {
            "weekly" => $"Week of {dt:MMM dd}",
            "monthly" => dt.ToString("MMM yyyy", CultureInfo.InvariantCulture),
            _ => dt.ToString("MMM dd", CultureInfo.InvariantCulture)
        };
    }

    private static List<DateTime> GetBucketSequence(DateTime start, DateTime end, string frequency)
    {
        var list = new List<DateTime>();
        var curr = start.Date;

        while (curr <= end.Date)
        {
            list.Add(curr);
            curr = frequency switch
            {
                "weekly" => curr.AddDays(7),
                "monthly" => curr.AddMonths(1),
                _ => curr.AddDays(1)
            };
        }

        if (list.Count == 0)
        {
            list.Add(end.Date);
        }

        return list;
    }
}

/// <summary>
/// Individual data point for the user growth chart containing date, bucket label, new registrations, and running total.
/// </summary>
public sealed record UserGrowthDataPoint(
    string Date,
    string Label,
    int NewRegistrations,
    int TotalUsers);

/// <summary>
/// Response payload for user growth analytics.
/// </summary>
public sealed record UserGrowthAnalyticsResponse(
    int TotalUsers,
    int NewUsersInPeriod,
    int ActiveUsersCount,
    double GrowthRatePercentage,
    string Timeframe,
    string Frequency,
    IReadOnlyList<UserGrowthDataPoint> DataPoints);

/// <summary>
/// User count for a specific platform role.
/// </summary>
public sealed record RoleCountDto(
    string Role,
    int Count);

/// <summary>
/// Aggregated summary of user counts across all platform roles.
/// </summary>
public sealed record RoleDistributionResponse(
    int TotalRolesAssigned,
    IReadOnlyList<RoleCountDto> Roles);
