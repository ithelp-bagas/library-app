import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key, required this.token});

  final String token;

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? _webViewController;
  WebUri? url;
  double progress = 0;
  PullToRefreshController? pullToRefreshController;
  PullToRefreshSettings pullToRefreshSettings = PullToRefreshSettings(
    color: Colors.blue,
  );
  bool pullToRefreshEnabled = true;
  bool canPop = false;

  _pop() async {
    setState(() {
      canPop = true;
    });
    if(mounted) {
      Navigator.of(context).pop();
    }
  }


  @override
  void initState() {
    super.initState();
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
      settings: pullToRefreshSettings,
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          _webViewController?.loadUrl(
              urlRequest:
              URLRequest(url: await _webViewController?.getUrl(), headers: {
                "Authorization": "Bearer ${widget.token}"
              }));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if(didPop){
          return;
        }
        final controller = _webViewController;
        if (controller != null) {
          if (canPop == false) {
            final uri = await controller.getUrl();
            if (uri != null) {
              inspect(uri);
              final uriPath = extractPathSegment(uri.path);

              if (uriPath == '/home' || uriPath == '/login') {
                setState(() {
                  canPop = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Press back again to exit"),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
            }
            if (!await controller.canGoBack()) {
              setState(() {
                canPop = true;
              });

            } else {
              controller.goBack();
              return;
            }
          } else {
            return;
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: <Widget>[
            Container(
                padding: EdgeInsets.all(5.0),
                child: progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container()),
            Expanded(
              child: InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri("http://192.168.1.141/fingerspot-library/pwa/home"),
                  headers: {
                    "Authorization": "Bearer ${widget.token}"
                  }
                ),
                pullToRefreshController: pullToRefreshController,
                initialSettings: InAppWebViewSettings(
                  useOnDownloadStart: true,
                  isInspectable: kDebugMode,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllow: "camera; microphone",
                  iframeAllowFullscreen: true,
                  allowsBackForwardNavigationGestures: true,
                ),
                onWebViewCreated: (InAppWebViewController controller) {
                  _webViewController = controller;
                  controller.addJavaScriptHandler(
                    handlerName: "finishActivity",
                    callback: (args) {
                      _pop();
                    },
                  );
                },
                onAjaxProgress: (InAppWebViewController controller, AjaxRequest ajaxRequest) {
                  // Log the AJAX request URL
                  print('AJAX request URL: ${ajaxRequest.url}');

                  // Modify headers if necessary
                  final headers = ajaxRequest.headers;

                  // Return Future with the action to allow the request to proceed
                  return Future.value(AjaxRequestAction.PROCEED);
                },
                onJsBeforeUnload: (controller, jsBeforeUnloadRequest) async{
                  final url = jsBeforeUnloadRequest.url;

                  if(url.toString() != ''){
                    final modifiedUrl = URLRequest(
                      url: url,
                      headers:{
                        'Authorization': 'Bearer ${widget.token}'
                      }
                    );

                    await controller.loadUrl(urlRequest: modifiedUrl);
                  }
                  return JsBeforeUnloadResponse();
                },
                onLoadStart: (InAppWebViewController controller, WebUri? url) {
                  setState(() {
                    this.url = url;
                  });
                },
                onLoadStop: (InAppWebViewController controller, WebUri? url) async {
                  pullToRefreshController?.endRefreshing();
                  setState(() {
                    this.url = url;
                  });
                },
                onProgressChanged: (InAppWebViewController controller, int progress) {
                  setState(() {
                    this.progress = progress / 100;
                  });
                  if (progress == 100) {
                    pullToRefreshController?.endRefreshing();
                  }
                },
                shouldOverrideUrlLoading: (InAppWebViewController controller, NavigationAction navigationAction) async{
                  if(!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
                    final shouldPerformDownload = navigationAction.shouldPerformDownload ?? false;
                    final url = navigationAction.request.url;

                    if (navigationAction.request.url != null) {
                      if(shouldPerformDownload) {
                        await downloadFile(url.toString());
                        return NavigationActionPolicy.DOWNLOAD;
                      }

                      final modifiedRequest = URLRequest(
                        url: navigationAction.request.url,
                        headers: {
                          "Authorization": "Bearer ${widget.token}",
                        },
                      );

                      await controller.loadUrl(urlRequest: modifiedRequest);

                      return NavigationActionPolicy.CANCEL;
                    } else {
                      final modifiedRequest = URLRequest(
                        url: url,
                        headers: {
                          "Authorization": "Bearer ${widget.token}",
                        },
                      );
                      await controller.loadUrl(urlRequest: modifiedRequest);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onDownloadStartRequest: (InAppWebViewController controller, DownloadStartRequest download) async{
                  final headers = {
                    "Authorization": "Bearer ${widget.token}",
                  };
                    await downloadFile(download.url.toString(), download.suggestedFilename, headers);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your file is being downloaded")));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> downloadFile(String url, [String? filename,  Map<String, String>? headers]) async {
      if(await _requestPermission(Permission.manageExternalStorage)){
        final taskId = await FlutterDownloader.enqueue(
            url: url,
            headers:headers!,
            // optional: header send with url (auth token etc)
            savedDir: (await getTemporaryDirectory()).path,
            saveInPublicStorage: true,
            fileName: filename);
      } else {
        // Handle permission denied
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied'))
        );
      }
  }

  String extractPathSegment(String url) {
    final uri = Uri.parse(url); // Parse the URL
    final path = uri.path; // Get the path from the URL

    // Split the path into segments
    final segments = path.split('/');

    // Return the last segment, or the one you're interested in
    return segments.isNotEmpty ? '/${segments.last}' : '/';
  }

  Future<bool> _requestPermission(Permission permission) async {
    // await Permission.manageExternalStorage.request();

    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }
}
