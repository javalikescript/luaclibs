if type(package.resource) == 'table' then
  local wp = package.preload['webview']
  local wr = package.resource['WebView2Loader.dll']
  if type(wp) == 'function' and type(wr) == 'function' then
    package.preload['webview'] = function(name)
      local wv = wp(name)
      local wl = wr('WebView2Loader.dll')
      if wl and wv and wv.loadWebView2Dll then
        wv.loadWebView2Dll(wl)
      end
      return wv
    end
  end
end
