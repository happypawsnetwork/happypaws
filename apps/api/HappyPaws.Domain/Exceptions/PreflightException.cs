namespace HappyPaws.Domain.Exceptions;

public sealed class PreflightException : Exception
{
    public PreflightException(string message) : base(message)
    {
    }

    public PreflightException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
