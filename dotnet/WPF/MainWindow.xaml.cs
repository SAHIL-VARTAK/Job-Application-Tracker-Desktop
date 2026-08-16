using System.IO;
using System.Windows;
using Microsoft.Web.WebView2.Core;
using Shared.Application;

namespace WPF;

public partial class MainWindow : Window
{
    private readonly AppPaths _paths;

    public MainWindow(AppPaths paths)
    {
        InitializeComponent();
        _paths = paths;
    }

    public async Task InitializeWebViewAsync()
    {
        var options = new CoreWebView2EnvironmentOptions
        {
            AdditionalBrowserArguments =
                "--allow-file-access-from-files"
        };

        var environment =
            await CoreWebView2Environment.CreateAsync(
                null,
                null,
                options);

        await WebView.EnsureCoreWebView2Async(environment);
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
        if (!File.Exists(_paths.ErrorPagePath))
        {
            MessageBox.Show(
                message,
                "Startup Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        var errorUrl =
            $"{new Uri(_paths.ErrorPagePath).AbsoluteUri}" +
            $"?message={Uri.EscapeDataString(message)}";

        WebView.CoreWebView2.Navigate(errorUrl);
    }

    private void NavigateToFile(string path)
    {
        if (!File.Exists(path))
        {
            MessageBox.Show(
                $"Page was not found:\n{path}",
                "Startup Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        WebView.CoreWebView2.Navigate(
            new Uri(path).AbsoluteUri);
    }
}