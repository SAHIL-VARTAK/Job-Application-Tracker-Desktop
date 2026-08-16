namespace Shared.Application;

public sealed class BackendConfiguration
{
    public const string Host = "127.0.0.1";
    public const int Port = 8080;

    public string BaseUrl =>
        $"http://{Host}:{Port}";

    public string FrontendUrl { get; }

    public BackendConfiguration(string frontendUrl)
    {
        FrontendUrl = frontendUrl;
    }

    public string ReadinessUrl =>
        $"{BaseUrl}/api/applications";
}