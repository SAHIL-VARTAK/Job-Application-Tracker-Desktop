using Microsoft.UI.Xaml;
using Shared.Application;
using Shared.Backend;

namespace WinUI3;

public partial class App : Application
{
    private Window? _window;
    private BackendManager? _backendManager;

    public App()
    {
        InitializeComponent();
    }

    protected override async void OnLaunched(
        Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        try
        {
            var paths = new AppPaths();

            _window = new MainWindow(paths);

            _window.Closed += (_, _) =>
            {
                _backendManager?.Stop();
            };

            _window.Activate();

            var mainWindow = (MainWindow)_window;

            await mainWindow.InitializeWebViewAsync();

            mainWindow.ShowLoading();

#if DEBUG
            const bool production = false;
#else
            const bool production = true;
#endif

            _backendManager = new BackendManager(paths);

            _backendManager.Start(
                "file://",
                production);

            var backendReady =
                await _backendManager.WaitForBackendAsync(
                    TimeSpan.FromSeconds(30));

            if (!backendReady)
            {
                mainWindow.ShowError(
                    "Spring Boot backend did not become ready within 30 seconds.");

                return;
            }

            mainWindow.ShowApplication();
        }
        catch (Exception ex)
        {
            if (_window is MainWindow mainWindow)
            {
                mainWindow.ShowError(ex.Message);
            }
        }
    }
}