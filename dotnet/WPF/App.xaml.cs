using System.Windows;
using Shared.Application;
using Shared.Backend;

namespace WPF;

public partial class App : System.Windows.Application
{
    private BackendManager? _backendManager;
    private MainWindow? _mainWindow;

    protected override async void OnStartup(
        StartupEventArgs e)
    {
        base.OnStartup(e);

        try
        {
            var paths = new AppPaths();

            _mainWindow = new MainWindow(paths);

            MainWindow = _mainWindow;

            _mainWindow.Show();

            await _mainWindow.InitializeWebViewAsync();

            _mainWindow.ShowLoading();

            _backendManager =
                new BackendManager(paths);

            #if DEBUG
                const bool production = false;
            #else
                const bool production = true;
            #endif

            _backendManager.Start(
                "file://",
                production);

            var backendReady =
                await _backendManager.WaitForBackendAsync(
                    TimeSpan.FromSeconds(30));

            if (!backendReady)
            {
                _mainWindow.ShowError(
                    "Spring Boot backend did not become ready within 30 seconds.");

                return;
            }

            _mainWindow.ShowApplication();
        }
        catch (Exception ex)
        {
            _mainWindow?.ShowError(ex.Message);
        }
    }

    protected override void OnExit(
        ExitEventArgs e)
    {
        _backendManager?.Stop();

        base.OnExit(e);
    }
}