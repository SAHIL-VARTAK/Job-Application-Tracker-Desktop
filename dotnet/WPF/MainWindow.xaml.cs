using System.IO;
using System.Windows;
using Shared.Application;

namespace WPF;

public partial class MainWindow : Window
{
    private readonly AppPaths _paths;

    public MainWindow(AppPaths paths)
    {
        InitializeComponent();

        _paths = paths;

        Loaded += MainWindow_Loaded;
    }

    private async void MainWindow_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        try
        {
            var indexPath = Path.Combine(
                _paths.FrontendDistPath,
                "index.html");

            if (!File.Exists(indexPath))
            {
                throw new FileNotFoundException(
                    "Frontend was not found.",
                    indexPath);
            }

            var options =
                new Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions();

            options.AdditionalBrowserArguments =
                "--allow-file-access-from-files";

            var environment =
                await Microsoft.Web.WebView2.Core.CoreWebView2Environment
                    .CreateAsync(
                        null,
                        null,
                        options);

            await WebView.EnsureCoreWebView2Async(environment);

            WebView.CoreWebView2.Navigate(
                new Uri(indexPath).AbsoluteUri);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                ex.ToString(),
                "WebView2 Startup Error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            Close();
        }
    }
}