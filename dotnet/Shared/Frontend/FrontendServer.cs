using System.Net;
using System.Net.Http;
using System.Net.Sockets;

namespace Shared.Frontend;

public sealed class FrontendServer : IDisposable
{
    private readonly string _frontendDirectory;
    private readonly string _backendBaseUrl;

    private readonly HttpClient _httpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    private HttpListener? _listener;
    private CancellationTokenSource? _cancellationTokenSource;

    public int Port { get; private set; }

    public string BaseUrl =>
        $"http://127.0.0.1:{Port}";

    public FrontendServer(
        string frontendDirectory,
        string backendBaseUrl)
    {
        _frontendDirectory = frontendDirectory.TrimEnd(
            Path.DirectorySeparatorChar,
            Path.AltDirectorySeparatorChar);

        _backendBaseUrl = backendBaseUrl.TrimEnd('/');
    }

    public void Start()
    {
        if (_listener is not null)
        {
            return;
        }

        if (!Directory.Exists(_frontendDirectory))
        {
            throw new DirectoryNotFoundException(
                $"Frontend directory was not found: {_frontendDirectory}");
        }

        Port = GetAvailablePort();

        _listener = new HttpListener();

        _listener.Prefixes.Add(
            $"{BaseUrl}/");

        _listener.Start();

        _cancellationTokenSource =
            new CancellationTokenSource();

        _ = ListenAsync(
            _cancellationTokenSource.Token);
    }

    private async Task ListenAsync(
        CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            HttpListenerContext context;

            try
            {
                context = await _listener!
                    .GetContextAsync();
            }
            catch (HttpListenerException)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }

            _ = Task.Run(
                () => HandleRequestAsync(context),
                cancellationToken);
        }
    }

    private async Task HandleRequestAsync(
        HttpListenerContext context)
    {
        try
        {
            var request = context.Request;

            if (request.Url is null)
            {
                context.Response.StatusCode = 400;
                context.Response.Close();
                return;
            }

            var path = request.Url.AbsolutePath;

            if (path.StartsWith(
                    "/api/",
                    StringComparison.OrdinalIgnoreCase) ||
                path.Equals(
                    "/api",
                    StringComparison.OrdinalIgnoreCase))
            {
                await ProxyApiRequestAsync(context);
                return;
            }

            await ServeFrontendAsync(context);
        }
        catch (Exception ex)
        {
            try
            {
                context.Response.StatusCode = 500;

                var message =
                    $"Frontend server error: {ex.Message}";

                var bytes =
                    System.Text.Encoding.UTF8.GetBytes(message);

                context.Response.ContentType =
                    "text/plain; charset=utf-8";

                context.Response.ContentLength64 =
                    bytes.Length;

                await context.Response.OutputStream.WriteAsync(
                    bytes);

                context.Response.Close();
            }
            catch
            {
                // Ignore errors while returning an error response.
            }
        }
    }

    private async Task ServeFrontendAsync(
        HttpListenerContext context)
    {
        var request = context.Request;
        var response = context.Response;

        var relativePath =
            Uri.UnescapeDataString(
                request.Url!.AbsolutePath.TrimStart('/'));

        if (string.IsNullOrWhiteSpace(relativePath))
        {
            relativePath = "index.html";
        }

        var requestedFile = Path.GetFullPath(
            Path.Combine(
                _frontendDirectory,
                relativePath.Replace(
                    '/',
                    Path.DirectorySeparatorChar)));

        var frontendRoot = Path.GetFullPath(
            _frontendDirectory)
            .TrimEnd(
                Path.DirectorySeparatorChar)
            + Path.DirectorySeparatorChar;

        if (!requestedFile.StartsWith(
                frontendRoot,
                StringComparison.OrdinalIgnoreCase))
        {
            response.StatusCode = 403;
            response.Close();
            return;
        }

        if (File.Exists(requestedFile))
        {
            await SendFileAsync(
                response,
                requestedFile);

            return;
        }

        // React BrowserRouter route:
        // /applications
        // /applications/new
        // /statistics
        //
        // These should all receive index.html.
        var extension =
            Path.GetExtension(requestedFile);

        if (string.IsNullOrEmpty(extension))
        {
            var indexPath =
                Path.Combine(
                    _frontendDirectory,
                    "index.html");

            if (File.Exists(indexPath))
            {
                await SendFileAsync(
                    response,
                    indexPath);

                return;
            }
        }

        response.StatusCode = 404;
        response.Close();
    }

    private async Task SendFileAsync(
        HttpListenerResponse response,
        string filePath)
    {
        var bytes = await File.ReadAllBytesAsync(filePath);

        response.StatusCode = 200;
        response.ContentType =
            GetContentType(filePath);

        response.ContentLength64 = bytes.Length;

        await response.OutputStream.WriteAsync(bytes);

        response.Close();
    }

    private async Task ProxyApiRequestAsync(
        HttpListenerContext context)
    {
        var request = context.Request;
        var response = context.Response;

        var targetUri =
            _backendBaseUrl +
            request.Url!.AbsolutePath +
            request.Url.Query;

        using var backendRequest =
            new HttpRequestMessage(
                new HttpMethod(request.HttpMethod),
                targetUri);

        // Forward request headers
        foreach (string headerName in request.Headers)
        {
            if (headerName.Equals(
                    "Host",
                    StringComparison.OrdinalIgnoreCase) ||
                headerName.Equals(
                    "Content-Length",
                    StringComparison.OrdinalIgnoreCase) ||
                headerName.Equals(
                    "Connection",
                    StringComparison.OrdinalIgnoreCase) ||
                headerName.Equals(
                    "Transfer-Encoding",
                    StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var headerValue = request.Headers[headerName];

            if (!backendRequest.Headers.TryAddWithoutValidation(
                    headerName,
                    headerValue))
            {
                backendRequest.Content ??=
                    new ByteArrayContent([]);

                backendRequest.Content.Headers
                    .TryAddWithoutValidation(
                        headerName,
                        headerValue);
            }
        }

        // Forward request body
        if (request.HasEntityBody)
        {
            using var memoryStream = new MemoryStream();

            await request.InputStream.CopyToAsync(
                memoryStream);

            backendRequest.Content =
                new ByteArrayContent(
                    memoryStream.ToArray());

            if (!string.IsNullOrWhiteSpace(
                    request.ContentType))
            {
                backendRequest.Content.Headers.ContentType =
                    System.Net.Http.Headers.MediaTypeHeaderValue
                        .Parse(request.ContentType);
            }
        }

        using var backendResponse =
            await _httpClient.SendAsync(
                backendRequest,
                HttpCompletionOption.ResponseHeadersRead);

        response.StatusCode =
            (int)backendResponse.StatusCode;

        // Only copy safe response headers.
        if (backendResponse.Content.Headers.ContentType is not null)
        {
            response.ContentType =
                backendResponse.Content.Headers
                    .ContentType
                    .ToString();
        }

        if (backendResponse.Headers.TryGetValues(
                "Cache-Control",
                out var cacheControl))
        {
            response.Headers["Cache-Control"] =
                string.Join(", ", cacheControl);
        }

        if (backendResponse.Headers.TryGetValues(
                "Location",
                out var location))
        {
            response.RedirectLocation =
                string.Join(", ", location);
        }

        var responseBytes =
            await backendResponse.Content
                .ReadAsByteArrayAsync();

        response.ContentLength64 =
            responseBytes.Length;

        await response.OutputStream.WriteAsync(
            responseBytes);

        response.Close();
    }

    private static string GetContentType(
        string filePath)
    {
        return Path.GetExtension(filePath)
            .ToLowerInvariant() switch
        {
            ".html" => "text/html; charset=utf-8",
            ".css" => "text/css; charset=utf-8",
            ".js" => "application/javascript",
            ".json" => "application/json",
            ".svg" => "image/svg+xml",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif" => "image/gif",
            ".ico" => "image/x-icon",
            ".woff" => "font/woff",
            ".woff2" => "font/woff2",
            ".ttf" => "font/ttf",
            _ => "application/octet-stream"
        };
    }

    private static int GetAvailablePort()
    {
        using var listener =
            new TcpListener(
                IPAddress.Loopback,
                0);

        listener.Start();

        return ((IPEndPoint)listener.LocalEndpoint)
            .Port;
    }

    public void Stop()
    {
        if (_listener is null)
        {
            return;
        }

        _cancellationTokenSource?.Cancel();

        _listener.Stop();
        _listener.Close();

        _listener = null;

        _cancellationTokenSource?.Dispose();
        _cancellationTokenSource = null;
    }

    public void Dispose()
    {
        Stop();
        _httpClient.Dispose();
    }
}