using System.Net.Http;

namespace Shared.Backend;

public sealed class BackendReadinessChecker : IDisposable
{
    private readonly HttpClient _httpClient;

    public BackendReadinessChecker()
    {
        _httpClient = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(2)
        };
    }

    public async Task<bool> WaitForBackendAsync(
        string url,
        TimeSpan timeout,
        CancellationToken cancellationToken = default)
    {
        var startTime = DateTime.UtcNow;

        while (DateTime.UtcNow - startTime < timeout)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                using var response = await _httpClient.GetAsync(
                    url,
                    cancellationToken);

                if (response.IsSuccessStatusCode)
                {
                    return true;
                }
            }
            catch (HttpRequestException)
            {
                // Backend is not ready yet.
            }
            catch (TaskCanceledException)
                when (!cancellationToken.IsCancellationRequested)
            {
                // Individual request timed out. Keep checking.
            }

            await Task.Delay(
                TimeSpan.FromMilliseconds(250),
                cancellationToken);
        }

        return false;
    }

    public void Dispose()
    {
        _httpClient.Dispose();
    }
}