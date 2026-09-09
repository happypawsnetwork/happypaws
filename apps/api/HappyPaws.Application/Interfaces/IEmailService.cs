using System.Threading;
using System.Threading.Tasks;

namespace HappyPaws.Application.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string templateName, object model, CancellationToken cancellationToken = default);

    Task<string> RenderTemplateAsync(string templateName, object model, string subject = "Email preview", CancellationToken cancellationToken = default);
}
