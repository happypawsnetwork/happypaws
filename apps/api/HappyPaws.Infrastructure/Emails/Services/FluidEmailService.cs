using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Fluid;
using HappyPaws.Application.Interfaces;
using HappyPaws.Infrastructure.Emails.Options;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HappyPaws.Infrastructure.Emails.Services;

public class FluidEmailService : IEmailService
{
    private readonly HttpClient _httpClient;
    private readonly EmailOptions _emailOptions;
    private readonly SystemOptions _systemOptions;
    private readonly ILogger<FluidEmailService> _logger;
    private readonly FluidParser _parser;
    private readonly string _templatesPath;
    private readonly IHostEnvironment _env;

    public FluidEmailService(
        HttpClient httpClient,
        IOptions<EmailOptions> emailOptions,
        IOptions<SystemOptions> systemOptions,
        ILogger<FluidEmailService> logger,
        IHostEnvironment env)
    {
        _httpClient = httpClient;
        _emailOptions = emailOptions.Value;
        _systemOptions = systemOptions.Value;
        _logger = logger;
        _env = env;
        _parser = new FluidParser();

        _templatesPath = Path.Combine(AppContext.BaseDirectory, "Emails", "Templates");
    }

    public async Task SendEmailAsync(string to, string subject, string templateName, object model, CancellationToken cancellationToken = default)
    {
        if (_env.IsDevelopment())
        {
            if (model is System.Collections.Generic.IDictionary<string, object> dict && dict.TryGetValue("OtpCode", out var code))
            {
                _logger.LogInformation("\n\n========================================\n[EMAIL MOCK] Verification Code: {Code}\n========================================\n\n", code);
            }
            else if (templateName == "admin-seeded")
            {
                var type = model.GetType();
                var email = type.GetProperty("Email")?.GetValue(model);
                var password = type.GetProperty("Password")?.GetValue(model);
                var url = type.GetProperty("WebDashboardUrl")?.GetValue(model);

                _logger.LogInformation("\n\n========================================\n[EMAIL MOCK] Administrator Account Provisioned\nEmail: {Email}\nPassword: {Password}\nURL: {Url}\n========================================\n\n", email, password, url);
            }
            return;
        }

        var layoutPath = Path.Combine(_templatesPath, "_layout.liquid");
        var templatePath = Path.Combine(_templatesPath, $"{templateName}.liquid");

        var layoutContent = await File.ReadAllTextAsync(layoutPath, cancellationToken);
        var templateContent = await File.ReadAllTextAsync(templatePath, cancellationToken);

        if (!_parser.TryParse(templateContent, out var parsedTemplate, out var error))
        {
            throw new InvalidOperationException($"Error parsing template {templateName}: {error}");
        }

        var context = new TemplateContext(model);
        context.SetValue("CdnBaseUrl", _systemOptions.CdnBaseUrl);
        var innerHtml = await parsedTemplate.RenderAsync(context);

        if (!_parser.TryParse(layoutContent, out var parsedLayout, out error))
        {
            throw new InvalidOperationException($"Error parsing _layout.liquid: {error}");
        }

        var layoutContext = new TemplateContext(new { content = innerHtml, subject });
        layoutContext.SetValue("CdnBaseUrl", _systemOptions.CdnBaseUrl);
        var finalHtml = await parsedLayout.RenderAsync(layoutContext);

        // Send via Resend HTTP API
        var requestBody = new
        {
            from = $"{_emailOptions.FromName} <{_emailOptions.FromAddress}>",
            to = new[] { to },
            subject = subject,
            html = finalHtml
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.resend.com/emails")
        {
            Headers = { Authorization = new AuthenticationHeaderValue("Bearer", _emailOptions.ApiKey) },
            Content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json")
        };

        var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var responseStr = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogError("[Email] Failed to send email to {To}. Status: {Status}, Error: {Error}", to, response.StatusCode, responseStr);
            throw new HappyPaws.Domain.Exceptions.EmailDeliveryException($"Failed to send email. Resend API returned {response.StatusCode}: {responseStr}");
        }

        _logger.LogInformation("[Email] Email sent successfully to {To} with subject {Subject}", to, subject);
    }
}
