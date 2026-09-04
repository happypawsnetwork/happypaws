using System;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using HappyPaws.Infrastructure.Data;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Extensions;

public static class DatabaseExtensions
{
    public static async Task ApplyMigrationsAndSeedAsync(this WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var services = scope.ServiceProvider;
        var logger = services.GetRequiredService<ILogger<ApplicationDbContext>>();
        var context = services.GetRequiredService<ApplicationDbContext>();
        var configuration = services.GetRequiredService<IConfiguration>();
        var emailService = services.GetRequiredService<IEmailService>();

        try
        {
            logger.LogInformation("Applying EF Core migrations...");
            await context.Database.MigrateAsync();
            logger.LogInformation("Migrations applied successfully.");

            var domain = configuration["System:Domain"] ?? "happypawsnetwork.com";

            // Check if admin exists
            var existingAdmin = await context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.Roles.Any(r => r.RoleName == RoleName.Administrator));

            if (existingAdmin == null)
            {
                logger.LogInformation("[Database] No administrator account found. Seeding initial admin...");

                var adminEmail = $"admin@{domain}";
                var isDev = app.Environment.IsDevelopment();
                var plainPassword = isDev ? "admin123" : GenerateSecurePassword(24);
                var webUrl = configuration.GetValue<string>("Cors:AllowedOrigins")?.Split(',').FirstOrDefault() ?? "http://localhost:3000";

                await using var transaction = await context.Database.BeginTransactionAsync();

                var user = new User
                {
                    Email = adminEmail,
                    FirstName = "Happy",
                    LastName = "Paws",
                    PasswordHash = string.Empty // will be set next
                };

                user.AddRole(RoleName.Administrator);

                var passwordHasher = new PasswordHasher<User>();
                user.PasswordHash = passwordHasher.HashPassword(user, plainPassword);

                context.Users.Add(user);
                await context.SaveChangesAsync();

                if (isDev)
                {
                    await transaction.CommitAsync();
                    logger.LogInformation("[Database] Administrator account created with email: {Email} and password: {Password} in development mode", adminEmail, plainPassword);
                }
                else
                {
                    // Attempt to send email on production
                    try
                    {
                        await emailService.SendEmailAsync(
                            to: adminEmail,
                            subject: "Happy Paws - Administrator Account Provisioned",
                            templateName: "admin-seeded",
                            model: new { Email = adminEmail, Password = plainPassword, WebDashboardUrl = webUrl }
                        );

                        await transaction.CommitAsync();
                        logger.LogInformation("[Database] Administrator account created with email: {Email} and credentials emailed successfully.", adminEmail);
                    }
                    catch (Exception ex)
                    {
                        await transaction.RollbackAsync();
                        logger.LogError(ex, "[Database] Failed to email administrator credentials. Admin account creation rolled back.");
                    }
                }
            }
            else if (app.Environment.IsDevelopment() && existingAdmin.FirstName == "System" && existingAdmin.LastName == "Administrator")
            {
                existingAdmin.FirstName = "Happy";
                existingAdmin.LastName = "Paws";
                var passwordHasher = new PasswordHasher<User>();
                existingAdmin.PasswordHash = passwordHasher.HashPassword(existingAdmin, "admin123");
                await context.SaveChangesAsync();
                logger.LogInformation("[Database] Updated existing development administrator name to Happy Paws and password to admin123");
            }

            if (app.Environment.IsDevelopment())
            {
                await SeedDevelopmentUsersAsync(context, domain, logger);

                var storageService = services.GetRequiredService<IStorageService>();
                await CommunitySeeder.SeedCommunityPostsAsync(context, storageService, logger);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "An error occurred during database migration or seeding.");
            throw;
        }
    }

    private static async Task SeedDevelopmentUsersAsync(
        ApplicationDbContext context,
        string domain,
        ILogger logger)
    {
        var devAccounts = new (RoleName Role, string Prefix, string Username, string FirstName, string LastName, string Tagline)[]
        {
            (RoleName.Adopter, "adopter", "adopter", "Adopter", "User", "Development test adopter account"),
            (RoleName.Foster, "foster", "foster", "Foster", "User", "Development test foster account"),
            (RoleName.Transporter, "transporter", "transporter", "Transporter", "User", "Development test transporter account"),
            (RoleName.Veterinarian, "vet", "vet", "Veterinarian", "User", "Development test veterinarian account"),
            (RoleName.Sponsor, "sponsor", "sponsor", "Sponsor", "User", "Development test sponsor account")
        };

        var passwordHasher = new PasswordHasher<User>();
        var anyAdded = false;

        foreach (var account in devAccounts)
        {
            var email = $"{account.Prefix}@{domain}".ToLowerInvariant();

            var exists = await context.Users.AnyAsync(u => u.Email == email || u.Username == account.Username);
            if (!exists)
            {
                var user = new User
                {
                    Email = email,
                    Username = account.Username,
                    FirstName = account.FirstName,
                    LastName = account.LastName,
                    Tagline = account.Tagline,
                    PasswordHash = string.Empty,
                    IsActive = true,
                    IsDeleted = false
                };

                user.PasswordHash = passwordHasher.HashPassword(user, "123");
                user.AddRole(account.Role, isVerified: true);

                context.Users.Add(user);
                anyAdded = true;
                logger.LogInformation("[Database] Seeding development account {Email} for role {Role}", email, account.Role);
            }
        }

        if (anyAdded)
        {
            await context.SaveChangesAsync();
            logger.LogInformation("[Database] Development seed accounts created successfully.");
        }
    }

    private static string GenerateSecurePassword(int length)
    {
        const string validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*";
        var res = new char[length];
        using var rng = RandomNumberGenerator.Create();
        var uintBuffer = new byte[sizeof(uint)];

        for (int i = 0; i < length; i++)
        {
            rng.GetBytes(uintBuffer);
            var num = BitConverter.ToUInt32(uintBuffer, 0);
            res[i] = validChars[(int)(num % (uint)validChars.Length)];
        }

        return new string(res);
    }
}
