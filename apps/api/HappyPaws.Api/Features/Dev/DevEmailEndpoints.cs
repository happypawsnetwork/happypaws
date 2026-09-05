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
    private static readonly Dictionary<string, (string Subject, object Model)> SampleTemplates = new(StringComparer.OrdinalIgnoreCase)
    {
        ["otp-verification"] = (
            "Web Admin Verification",
            new { OtpCode = "849201" }
        ),
        ["admin-seeded"] = (
            "Administrator Account Provisioned",
            new
            {
                Email = "admin@happypaws.lk",
                Password = "SuperSecurePassword123!",
                WebDashboardUrl = "http://localhost:3000/admin"
            }
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
        var items = string.Join("", SampleTemplates.Keys.Select(name =>
            $"<li style=\"margin: 12px 0;\"><a href=\"/api/v1/dev/emails/{name}\" style=\"color: #4CE5E5; font-size: 16px; text-decoration: none;\"><strong>{name}</strong></a> - <span style=\"color: #A0A0AB;\">{SampleTemplates[name].Subject}</span></li>"));

        var html = $$"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Email templates preview</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background-color: #1E1E24;
                    color: #FFFFFF;
                    padding: 40px 20px;
                    display: flex;
                    justify-content: center;
                }
                .container {
                    max-width: 600px;
                    width: 100%;
                    background-color: #2B2B36;
                    border-radius: 12px;
                    padding: 32px;
                    border: 1px solid #3A3A4A;
                }
                h1 { margin-top: 0; font-size: 22px; color: #FFFFFF; }
                p { color: #A0A0AB; font-size: 14px; line-height: 1.6; }
                ul { list-style-type: none; padding-left: 0; margin-top: 24px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Email templates preview</h1>
                <p>Select an email template below to preview its rendered HTML with sample data:</p>
                <ul>
                    {{items}}
                </ul>
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
        var subject = sample.Subject ?? "Email preview";
        var model = sample.Model ?? new { };

        try
        {
            var html = await emailService.RenderTemplateAsync(cleanName, model, subject, cancellationToken);
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
