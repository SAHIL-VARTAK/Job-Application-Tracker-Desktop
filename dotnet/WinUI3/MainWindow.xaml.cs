using System.IO;
using Microsoft.UI.Xaml;
using Microsoft.Web.WebView2.Core;
using Shared.Application;

namespace WinUI3;

public sealed partial class MainWindow : Window
{
    private readonly AppPaths _paths;

    public MainWindow(AppPaths paths)
    {
        InitializeComponent();

        _paths = paths;

        AppWindow.SetIcon("Assets/AppIcon.ico");
    }

    public async Task InitializeWebViewAsync()
    {
        var options = new CoreWebView2EnvironmentOptions
        {
            AdditionalBrowserArguments =
                "--allow-file-access-from-files"
        };

        var environment =
            await CoreWebView2Environment.CreateWithOptionsAsync(
                null,
                null,
                options);

        await WebView.EnsureCoreWebView2Async(
            environment);
    }

    public void ShowLoading()
    {
        NavigateToFile(_paths.LoadingPagePath);
    }

    public void ShowApplication()
    {
        NavigateToFile(
            Path.Combine(
                _paths.FrontendDistPath,
                "index.html"));
    }

    public void ShowError(string message)
    {
        var errorUrl =
            $"{new Uri(_paths.ErrorPagePath).AbsoluteUri}" +
            $"?message={Uri.EscapeDataString(message)}";

        NavigateToFile(errorUrl);
    }

    private void NavigateToFile(string path)
    {
        if (!File.Exists(path))
        {
            return;
        }

        WebView.CoreWebView2.Navigate(
            new Uri(path).AbsoluteUri);
    }
}
