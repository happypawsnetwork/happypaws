using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.Commands;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using HappyPaws.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Extensions;

public static class CommunitySeeder
{
    private static Guid? _seededRescuePostId;

    public static async Task SeedCommunityPostsAsync(
        ApplicationDbContext db,
        IStorageService storage,
        ILogger logger)
    {
        logger.LogInformation("[CommunitySeeder] Checking if community data seeding is required...");

        try
        {
            var pendingNonSponsors = await db.Posts
                .Where(p => p.Status == PostStatus.PendingApproval && p.Type != PostType.SponsorshipRequest)
                .ToListAsync();
            if (pendingNonSponsors.Any())
            {
                foreach (var p in pendingNonSponsors)
                {
                    p.Status = PostStatus.Active;
                }
                await db.SaveChangesAsync();
                logger.LogInformation("[CommunitySeeder] Activated {Count} existing pending posts.", pendingNonSponsors.Count);
            }

            if (await db.Posts.AnyAsync())
            {
                logger.LogInformation("[CommunitySeeder] Posts already exist in the database. Skipping seeding process.");
                return;
            }

            var contentRoot = Directory.GetCurrentDirectory();
            var testDataDir = Path.Combine(contentRoot, "test-data", "community");

            if (!Directory.Exists(testDataDir))
            {
                var current = new DirectoryInfo(contentRoot);
                while (current != null && !Directory.Exists(Path.Combine(current.FullName, "test-data", "community")))
                {
                    current = current.Parent;
                }

                if (current != null)
                {
                    testDataDir = Path.Combine(current.FullName, "test-data", "community");
                }
                else
                {
                    logger.LogWarning("[CommunitySeeder] Could not locate 'test-data/community' directory in the project structure. Seeding aborted.");
                    return;
                }
            }

            logger.LogInformation("[CommunitySeeder] Found community test data at: {Path}", testDataDir);

            var adopterUser = await db.Users.FirstOrDefaultAsync(u => u.Username == "adopter");
            var fosterUser = await db.Users.FirstOrDefaultAsync(u => u.Username == "foster");

            if (adopterUser == null || fosterUser == null)
            {
                logger.LogWarning("[CommunitySeeder] Required default users ('adopter', 'foster') not found in the database. Seeding aborted.");
                return;
            }

            logger.LogInformation("[CommunitySeeder] Seeding rescue post for Adopter (User ID: {UserId})...", adopterUser.Id);
            _seededRescuePostId = await SeedPostAsync(db, storage, logger, Path.Combine(testDataDir, "rescue"), adopterUser.Id);

            logger.LogInformation("[CommunitySeeder] Seeding find-home post for Foster (User ID: {UserId})...", fosterUser.Id);
            await SeedPostAsync(db, storage, logger, Path.Combine(testDataDir, "find-home"), fosterUser.Id);

            logger.LogInformation("[CommunitySeeder] Community post seeding completed successfully.");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "[CommunitySeeder] A critical error occurred during the community seeding workflow.");
        }
    }

    private static async Task<Guid?> SeedPostAsync(
        ApplicationDbContext db,
        IStorageService storage,
        ILogger logger,
        string folderPath,
        long authorId)
    {
        if (!Directory.Exists(folderPath))
        {
            logger.LogWarning("[CommunitySeeder] Target seeding folder does not exist: {FolderPath}", folderPath);
            return null;
        }

        var postFile = Path.Combine(folderPath, "post.md");
        if (!File.Exists(postFile))
        {
            logger.LogWarning("[CommunitySeeder] Missing metadata file 'post.md' in: {FolderPath}", folderPath);
            return null;
        }

        var photos = new List<FileUploadData>();
        var proofs = new List<FileUploadData>();

        try
        {
            var lines = await File.ReadAllLinesAsync(postFile);
            var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            foreach (var line in lines)
            {
                if (line.StartsWith("- **") && line.Contains("**: "))
                {
                    var keyStart = line.IndexOf("**") + 2;
                    var keyEnd = line.IndexOf("**", keyStart);
                    if (keyEnd > keyStart)
                    {
                        var key = line.Substring(keyStart, keyEnd - keyStart).Trim();
                        var valueStart = line.IndexOf("**: ") + 4;
                        var value = line.Substring(valueStart).Trim();
                        dict[key] = value;
                    }
                }
            }

            if (!dict.Any())
            {
                logger.LogWarning("[CommunitySeeder] Parsed metadata dictionary is empty for {FolderPath}. Ensure post.md is correctly formatted.", folderPath);
                return null;
            }

            var request = BuildCreatePostRequest(dict);

            var imageDir = Path.Combine(folderPath, "images");
            if (Directory.Exists(imageDir))
            {
                var files = Directory.GetFiles(imageDir);
                logger.LogDebug("[CommunitySeeder] Found {Count} asset files in {ImageDir}", files.Length, imageDir);

                foreach (var imgPath in files)
                {
                    var stream = File.OpenRead(imgPath);
                    var ext = Path.GetExtension(imgPath).ToLowerInvariant();
                    var mime = ext switch
                    {
                        ".png" => "image/png",
                        ".webp" => "image/webp",
                        ".heic" => "image/heic",
                        ".pdf" => "application/pdf",
                        _ => "image/jpeg"
                    };

                    var fileData = new FileUploadData(stream, Path.GetFileName(imgPath), mime, stream.Length);

                    if (request.Type == "SponsorshipRequest" && mime == "application/pdf")
                    {
                        proofs.Add(fileData);
                    }
                    else
                    {
                        if (request.Type == "SponsorshipRequest") proofs.Add(fileData);
                        else photos.Add(fileData);
                    }
                }
            }
            else
            {
                logger.LogDebug("[CommunitySeeder] No images folder found in {FolderPath}", folderPath);
            }

            logger.LogInformation("[CommunitySeeder] Executing CreatePost handler for type '{PostType}'...", request.Type);
            var postId = await CreatePost.HandleAsync(
                db,
                storage,
                request,
                photos,
                proofs,
                authorId,
                CancellationToken.None);

            logger.LogInformation("[CommunitySeeder] Successfully created post {PostId} from {FolderPath}", postId, folderPath);
            return postId;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "[CommunitySeeder] Exception encountered while processing or saving post from {FolderPath}", folderPath);
            return null;
        }
        finally
        {
            foreach (var p in photos) p.Stream?.Dispose();
            foreach (var p in proofs) p.Stream?.Dispose();
        }
    }

    private static CreatePostRequest BuildCreatePostRequest(Dictionary<string, string> dict)
    {
        var rawType = dict.GetValueOrDefault("Type", "Rescue");
        var postType = MapPostType(rawType);

        var request = new CreatePostRequest
        {
            Type = postType,
            Title = dict.GetValueOrDefault("Title", "Untitled"),
            Body = dict.GetValueOrDefault("Body", "No content")
        };

        // Parse ParentPostId if it exists and has been replaced or needs replacing
        if (dict.TryGetValue("ParentPostId", out var parentPostStr))
        {
            if (parentPostStr.Contains("[REPLACE_WITH_RESCUE_POST_ID]") && _seededRescuePostId.HasValue)
            {
                request = request with { ParentPostId = _seededRescuePostId.Value };
            }
            else if (Guid.TryParse(parentPostStr, out var parsedGuid))
            {
                request = request with { ParentPostId = parsedGuid };
            }
        }

        switch (postType)
        {
            case "RescueAlert":
                request = request with
                {
                    Latitude = 7.116359,
                    Longitude = 80.007599,
                    LocationLabel = dict.GetValueOrDefault("LocationLabel"),
                    AnimalSpecies = dict.GetValueOrDefault("AnimalSpecies"),
                    AnimalName = dict.GetValueOrDefault("AnimalName"),
                    AnimalDescription = dict.GetValueOrDefault("AnimalDescription"),
                    UrgencyLevel = dict.GetValueOrDefault("UrgencyLevel", "High"),
                    AiTriageReason = dict.GetValueOrDefault("AiTriageReason", "Assessed automatically during seeding.")
                };
                break;

            case "AdoptionListing":
                request = request with
                {
                    Latitude = 7.116359,
                    Longitude = 80.007599,
                    LocationLabel = dict.GetValueOrDefault("LocationLabel"),
                    AnimalSpecies = dict.GetValueOrDefault("AnimalSpecies"),
                    AnimalName = dict.GetValueOrDefault("AnimalName"),
                    AnimalDescription = dict.GetValueOrDefault("AnimalDescription"),
                    LifestyleHomeSize = dict.GetValueOrDefault("LifestyleHomeSize"),
                    LifestyleRequiresEnclosedYard = ParseBool(dict.GetValueOrDefault("LifestyleRequiresEnclosedYard")),
                    LifestyleGoodWithChildren = ParseBool(dict.GetValueOrDefault("LifestyleGoodWithChildren")),
                    LifestyleActivityTempo = dict.GetValueOrDefault("LifestyleActivityTempo")
                };
                break;

            case "Highlight":
                request = request with
                {
                    AnimalSpecies = dict.GetValueOrDefault("AnimalSpecies"),
                    AnimalName = dict.GetValueOrDefault("AnimalName"),
                    AnimalDescription = dict.GetValueOrDefault("AnimalDescription")
                };
                break;

            case "SponsorshipRequest":
                request = request with
                {
                    SponsorGoalDescription = dict.GetValueOrDefault("SponsorshipGoalDescription"),
                    SponsorEstimatedAmountLkr = ParseDecimal(dict.GetValueOrDefault("SponsorshipEstimatedAmountLkr"))
                };
                break;

            case "TransportRequest":
                request = request with
                {
                    Latitude = 7.116359,
                    Longitude = 80.007599,
                    LocationLabel = dict.GetValueOrDefault("LocationLabel")
                };
                break;

            case "VetRequest":
                request = request with
                {
                    VetReasonForVisit = dict.GetValueOrDefault("VetReasonForVisit"),
                    VetClinicName = dict.GetValueOrDefault("VetClinicName"),
                    VetAppointmentDate = ParseDateTimeOffset(dict.GetValueOrDefault("VetAppointmentDate")),
                    VetTransportNeeded = ParseBool(dict.GetValueOrDefault("VetTransportNeeded")) ?? false
                };
                break;

            case "FosterUpdate":
                // Basic fields (Title, Body, ParentPostId) are already mapped
                break;
        }

        return request;
    }

    private static string MapPostType(string typeString)
    {
        return typeString.ToLowerInvariant().Trim() switch
        {
            "find home" => "AdoptionListing",
            "rescue" => "RescueAlert",
            "sponsor" => "SponsorshipRequest",
            "transport" => "TransportRequest",
            "treatment" => "VetRequest",
            "update" => "FosterUpdate",
            "highlight" => "Highlight",
            _ => typeString
        };
    }

    private static bool? ParseBool(string? value)
    {
        if (bool.TryParse(value, out var result)) return result;
        return null;
    }

    private static decimal? ParseDecimal(string? value)
    {
        if (decimal.TryParse(value, out var result)) return result;
        return null;
    }

    private static DateTimeOffset? ParseDateTimeOffset(string? value)
    {
        if (DateTimeOffset.TryParse(value, out var result)) return result;
        return null;
    }
}
