using System.Windows;
using Shared.Application;
using Shared.Backend;
using Shared.Frontend;

namespace WPF;

public partial class App : System.Windows.Application
{
    private BackendManager? _backendManager;
    private FrontendServer? _frontendServer;

    protected override void OnStartup(StartupEventArgs e)
    {
        try
        {
            base.OnStartup(e);

            var paths = new AppPaths();

            // Start frontend server first so we know its port.
            _frontendServer = new FrontendServer(
                paths.FrontendDistPath,
                "http://127.0.0.1:8080");

            _frontendServer.Start();

            var frontendUrl = _frontendServer.BaseUrl;

            // Start Spring Boot with the actual frontend origin.
            _backendManager = new BackendManager(paths);

            _backendManager.Start(
                frontendUrl,
                production: false);

            var mainWindow = new MainWindow(
                frontendUrl);

            MainWindow = mainWindow;
            mainWindow.Show();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                ex.ToString(),
                "Startup Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            Shutdown(1);
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _frontendServer?.Stop();
        _frontendServer?.Dispose();

        _backendManager?.Stop();

        base.OnExit(e);
    }
}