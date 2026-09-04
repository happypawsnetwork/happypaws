using System.Threading;
using System.Threading.Tasks;

namespace HappyPaws.Application.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string to, string subject, string templateName, object model, CancellationToken cancellationToken = default);
}
