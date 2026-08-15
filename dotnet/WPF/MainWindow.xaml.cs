using System.Windows;

namespace WPF;

public partial class MainWindow : Window
{
    private readonly string _frontendUrl;

    public MainWindow(string frontendUrl)
    {
        InitializeComponent();

        _frontendUrl = frontendUrl;

        Loaded += MainWindow_Loaded;
    }

    private async void MainWindow_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        try
        {
            await WebView.EnsureCoreWebView2Async();

            WebView.CoreWebView2.Navigate(
                _frontendUrl + "/");
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