using Shared.Application;
using System.Diagnostics;

namespace Shared.Backend;

public sealed class BackendManager : IDisposable
{
    private readonly AppPaths _paths;
    private Process? _process;
    private readonly BackendReadinessChecker _readinessChecker;

    public bool IsRunning => _process is { HasExited: false };

    public BackendManager(AppPaths paths)
    {
        _paths = paths;
        _readinessChecker = new BackendReadinessChecker();
    }

    public void Start(string frontendUrl, bool production = false)
    {
        if (IsRunning)
        {
            return;
        }

        var javaPath = production
            ? _paths.JavawPath
            : _paths.JavaPath;

        if (!File.Exists(javaPath))
        {
            throw new FileNotFoundException(
                "Java runtime was not found.",
                javaPath);
        }

        if (!File.Exists(_paths.BackendJarPath))
        {
            throw new FileNotFoundException(
                "Spring Boot JAR was not found.",
                _paths.BackendJarPath);
        }

        _paths.EnsureDatabaseDirectory();

        var startInfo = new ProcessStartInfo
        {
            FileName = javaPath,
            UseShellExecute = false,
            CreateNoWindow = production
        };

        startInfo.ArgumentList.Add("-jar");
        startInfo.ArgumentList.Add(_paths.BackendJarPath);

        startInfo.ArgumentList.Add(
            $"--spring.datasource.url=jdbc:sqlite:{_paths.DatabasePath}");

        startInfo.ArgumentList.Add(
            $"--app.frontend.url={frontendUrl}");

        _process = new Process
        {
            StartInfo = startInfo,
            EnableRaisingEvents = true
        };

        if (!_process.Start())
        {
            _process.Dispose();
            _process = null;

            throw new InvalidOperationException(
                "Failed to start the Spring Boot backend.");
        }
    }

    public void Stop()
    {
        if (_process is null)
        {
            return;
        }

        try
        {
            if (!_process.HasExited)
            {
                _process.Kill(entireProcessTree: true);
                _process.WaitForExit();
            }
        }
        finally
        {
            _process.Dispose();
            _process = null;
        }
    }

    public async Task<bool> WaitForBackendAsync(
        TimeSpan timeout,
        CancellationToken cancellationToken = default)
    {
        return await _readinessChecker.WaitForBackendAsync(
            "http://127.0.0.1:8080/api/applications",
            timeout,
            cancellationToken);
    }

    public void Dispose()
    {
        Stop();
        _readinessChecker.Dispose();
    }
}