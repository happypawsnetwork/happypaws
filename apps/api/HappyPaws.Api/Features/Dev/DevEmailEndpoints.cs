using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Hosting;

namespace HappyPaws.Api.Features.Dev;

public sealed class DevEmailEndpoints : IEndpointGroup
{
    private sealed record SamplePreview(string TemplateFile, string Subject, object Model, string Description);

    private static readonly Dictionary<string, SamplePreview> SampleTemplates = new(StringComparer.OrdinalIgnoreCase)
    {
        ["otp-register"] = new(
            "otp-verification",
            "849201 is your verification code",
            new { OtpCode = "849201" },
            "User registration email verification"
        ),
        ["otp-password-reset"] = new(
            "otp-verification",
            "519342 is your password reset code",
            new { OtpCode = "519342" },
            "Password reset one-time verification code"
        ),
        ["otp-email-change"] = new(
            "otp-verification",
            "372819 is your new email verification code",
            new { OtpCode = "372819" },
            "Email update confirmation code"
        ),
        ["otp-admin-login"] = new(
            "otp-verification",
            "640192 is your admin verification code",
            new { OtpCode = "640192" },
            "Administrative 2FA sign-in verification"
        ),
        ["otp-verification"] = new(
            "otp-verification",
            "849201 is your verification code",
            new { OtpCode = "849201" },
            "Default verification template preview"
        ),
        ["admin-seeded"] = new(
            "admin-seeded",
            "Happy Paws - Administrator account provisioned",
            new
            {
                Email = "admin@happypaws.lk",
                Password = "SuperSecurePassword123!",
                WebDashboardUrl = "http://localhost:3000/admin"
            },
            "Initial setup administrator credentials"
        )
    };

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        // Only register development endpoints in development environment
        if (app is WebApplication webApp && !webApp.Environment.IsDevelopment())
        {
            return;
        }

        var group = app.MapGroup("/api/v1/dev/emails")
            .WithTags("Development")
            .AllowAnonymous();

        group.MapGet("/", ListTemplates)
            .WithName("ListEmailTemplates")
            .WithSummary("List available email templates for preview")
            .WithDescription("Returns an HTML directory of available email templates with preview links for local development.")
            .Produces(StatusCodes.Status200OK, contentType: "text/html");

        group.MapGet("/{templateName}", PreviewEmailTemplateAsync)
            .WithName("PreviewEmailTemplate")
            .WithSummary("Preview rendered email template with sample data")
            .WithDescription("Renders a Liquid email template with mock data and returns HTML directly for browser preview.")
            .Produces(StatusCodes.Status200OK, contentType: "text/html")
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static ContentHttpResult ListTemplates()
    {
        var items = string.Join("", SampleTemplates.Select(kv =>
            $$"""
            <a href="/api/v1/dev/emails/{{kv.Key}}" style="display: block; text-decoration: none; padding: 16px 20px; margin-bottom: 12px; background-color: #FFFFFF; border: 1px solid #E5E9EB; border-radius: 12px; transition: border-color 0.2s, box-shadow 0.2s; box-shadow: 0 1px 3px rgba(0,0,0,0.03);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                    <span style="color: #00827F; font-size: 15px; font-weight: 600;">{{kv.Key}}</span>
                    <span style="color: #64748B; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; font-weight: 500;">{{kv.Value.TemplateFile}}</span>
                </div>
                <div style="color: #131B26; font-size: 14px; font-weight: 500; margin-bottom: 4px;">{{kv.Value.Subject}}</div>
                <div style="color: #64748B; font-size: 13px;">{{kv.Value.Description}}</div>
            </a>
            """));

        var html = $$"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email templates preview</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, sans-serif;
                    background-color: #F4F6F8;
                    color: #131B26;
                    padding: 48px 20px;
                    display: flex;
                    justify-content: center;
                    margin: 0;
                }
                .container {
                    max-width: 600px;
                    width: 100%;
                    background-color: #FFFFFF;
                    border-radius: 16px;
                    padding: 36px 32px;
                    border: 1px solid #E5E9EB;
                    box-shadow: 0 4px 20px rgba(19, 27, 38, 0.05);
                    text-align: center;
                }
                .badge {
                    display: inline-block;
                    background-color: #E6F7F6;
                    border: 1px solid #B2E5E2;
                    border-radius: 9999px;
                    padding: 5px 14px;
                    font-size: 11px;
                    font-weight: 700;
                    letter-spacing: 0.08em;
                    text-transform: uppercase;
                    color: #00827F;
                    margin-bottom: 14px;
                }
                h1 { margin: 0 0 10px 0; font-size: 24px; font-weight: 700; letter-spacing: -0.02em; color: #131B26; }
                p { color: #5A6878; font-size: 14px; line-height: 1.6; margin: 0 0 28px 0; }
                .list { text-align: left; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="badge">Development preview</div>
                <h1>Email templates</h1>
                <p>Select an email template below to inspect its rendered layout with sample parameters:</p>
                <div class="list">
                    {{items}}
                </div>
            </div>
        </body>
        </html>
        """;

        return TypedResults.Content(html, "text/html");
    }

    private static async Task<Results<ContentHttpResult, NotFound<ProblemDetails>>> PreviewEmailTemplateAsync(
        string templateName,
        IEmailService emailService,
        CancellationToken cancellationToken)
    {
        var cleanName = Path.GetFileNameWithoutExtension(templateName);

        SampleTemplates.TryGetValue(cleanName, out var sample);
        var templateFile = sample?.TemplateFile ?? cleanName;
        var subject = sample?.Subject ?? "Email preview";
        var model = sample?.Model ?? new { };

        try
        {
            var html = await emailService.RenderTemplateAsync(templateFile, model, subject, cancellationToken);
            return TypedResults.Content(html, "text/html");
        }
        catch (FileNotFoundException)
        {
            return TypedResults.NotFound(new ProblemDetails
            {
                Title = "Template Not Found",
                Detail = $"The email template '{cleanName}.liquid' does not exist.",
                Status = StatusCodes.Status404NotFound
            });
        }
    }
}
