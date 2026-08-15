namespace Shared.Application;

public sealed class AppPaths
{
    public string BaseDirectory { get; }

    public string ResourcesDirectory =>
        Path.Combine(BaseDirectory, "resources");

    public string BackendDirectory =>
        Path.Combine(ResourcesDirectory, "backend");

    public string RuntimeDirectory =>
        Path.Combine(ResourcesDirectory, "runtime");

    public string FrontendDirectory =>
        Path.Combine(ResourcesDirectory, "frontend");

    public string SplashDirectory =>
        Path.Combine(ResourcesDirectory, "splash");

    public string LoadingPagePath =>
        Path.Combine(SplashDirectory, "loading.html");

    public string ErrorPagePath =>
        Path.Combine(SplashDirectory, "error.html");

    public string BackendJarPath =>
        Path.Combine(
            BackendDirectory,
            "job-application-tracker-1.0.0.jar");

    public string JavaPath =>
        Path.Combine(
            RuntimeDirectory,
            "bin",
            "java.exe");

    public string JavawPath =>
        Path.Combine(
            RuntimeDirectory,
            "bin",
            "javaw.exe");

    public string FrontendDistPath =>
        Path.Combine(
            FrontendDirectory,
            "dist");

    public string DatabaseDirectory { get; }

    public string DatabasePath =>
        Path.Combine(
            DatabaseDirectory,
            "job_tracker.db");

    public AppPaths()
    {
        BaseDirectory = AppContext.BaseDirectory;

        DatabaseDirectory = Path.Combine(
            Environment.GetFolderPath(
                Environment.SpecialFolder.ApplicationData),
            "JobApplicationTracker",
            "data");
    }

    public void EnsureDatabaseDirectory()
    {
        Directory.CreateDirectory(DatabaseDirectory);
    }
}