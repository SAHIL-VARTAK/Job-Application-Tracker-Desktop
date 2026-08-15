using System.Windows;
using Shared.Application;
using Shared.Backend;

namespace WPF;

public partial class App : System.Windows.Application
{
    private BackendManager? _backendManager;

    protected override async void OnStartup(StartupEventArgs e)
    {
        try
        {
            base.OnStartup(e);

            var paths = new AppPaths();

            _backendManager = new BackendManager(paths);

            _backendManager.Start(
                "file://",
                production: false);

            var backendReady =
                await _backendManager.WaitForBackendAsync(
                    TimeSpan.FromSeconds(30));

            if (!backendReady)
            {
                throw new InvalidOperationException(
                    "Spring Boot backend did not become ready within 30 seconds.");
            }

            var mainWindow = new MainWindow(paths);

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
        _backendManager?.Stop();

        base.OnExit(e);
    }
}