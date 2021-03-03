import Capacitor
import Foundation

@objc(HttpPlugin) public class HttpPlugin: CAPPlugin {
    var cookieManager: CapacitorCookieManager? = nil
    var capConfig: InstanceConfiguration? = nil
    
    private func getServerUrl(_ call: CAPPluginCall) -> URL? {
        guard let url = capConfig?.serverURL else {
            call.reject("Invalid URL. Check that \"server\" is set correctly in your capacitor.config.json file")
            return nil
        }
        
        return url;
    }
    
    @objc override public func load() {
        cookieManager = CapacitorCookieManager()
        capConfig = bridge?.config
    }
    
    @objc func request(_ call: CAPPluginCall) {
        // Protect against bad values from JS before calling request
        guard let u = call.getString("url") else { return call.reject("Must provide a URL"); }
        guard let _ = call.getString("method") else { return call.reject("Must provide an HTTP Method"); }
        guard var _ = URL(string: u) else { return call.reject("Invalid URL"); }
    
        do {
            try HttpRequestHandler.request(call)
        } catch let e {
            call.reject(e.localizedDescription)
        }
    }

    @objc func downloadFile(_ call: CAPPluginCall) {
        guard let urlValue = call.getString("url") else {
          return call.reject("Must provide a URL")
        }
        guard let filePath = call.getString("filePath") else {
          return call.reject("Must provide a file path to download the file to")
        }

        let fileDirectory = call.getString("fileDirectory") ?? "DOCUMENTS"

        guard let url = URL(string: urlValue) else {
          return call.reject("Invalid URL")
        }

        let task = URLSession.shared.downloadTask(with: url) { (downloadLocation, response, error) in
          if error != nil {
            CAPLog.print("Error on download file", downloadLocation, response, error)
            call.reject("Error", "DOWNLOAD", error, [:])
            return
          }

          guard let location = downloadLocation else {
            call.reject("Unable to get file after downloading")
            return
          }

          // TODO: Move to abstracted FS operations
          let fileManager = FileManager.default

          let foundDir = FilesystemUtils.getDirectory(directory: fileDirectory)
          let dir = fileManager.urls(for: foundDir, in: .userDomainMask).first

          do {
            let dest = dir!.appendingPathComponent(filePath)
            print("File Dest", dest.absoluteString)

            try FilesystemUtils.createDirectoryForFile(dest, true)

            try fileManager.moveItem(at: location, to: dest)
            call.resolve([
              "path": dest.absoluteString
            ])
          } catch let e {
            call.reject("Unable to download file", "DOWNLOAD", e)
            return
          }


          CAPLog.print("Downloaded file", location)
          call.resolve()
        }

        task.resume()
    }

    @objc func uploadFile(_ call: CAPPluginCall) {
        // Protect against bad values from JS before calling request
        let fd = call.getString("fileDirectory") ?? "DOCUMENTS"
        guard let u = call.getString("url") else { return call.reject("Must provide a URL") }
        guard let fp = call.getString("filePath") else { return call.reject("Must provide a file path to download the file to") }
        guard let _ = URL(string: u) else { return call.reject("Invalid URL") }
        guard let _ = FilesystemUtils.getFileUrl(fp, fd) else { return call.reject("Unable to get file URL") }
    
        do {
            try HttpRequestHandler.upload(call)
        } catch let e {
            call.reject(e.localizedDescription)
        }
    }

    @objc func setCookie(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else { return call.reject("Must provide key") }
        guard let value = call.getString("value") else { return call.reject("Must provide value") }
    
        let url = getServerUrl(call)
        if url != nil {
            cookieManager!.setCookie(url!, key, cookieManager!.encode(value))
            call.resolve()
        }
    }

    @objc func getCookies(_ call: CAPPluginCall) {
        let url = getServerUrl(call)
        if url != nil {
            let cookies = cookieManager!.getCookies(url!)
            let output = cookies.map { (cookie: HTTPCookie) -> [String: String] in
                return [
                    "key": cookie.name,
                    "value": cookie.value,
                ]
            }
            call.resolve([
                "cookies": output
            ])
        }
    }
    
    @objc func getCookie(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else { return call.reject("Must provide key") }
        let url = getServerUrl(call)
        if url != nil {
            let cookie = cookieManager!.getCookie(url!, key)
            call.resolve([
                "key": cookie.name,
                "value": cookieManager!.decode(cookie.value)
            ])
        }
    }

    @objc func deleteCookie(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else { return call.reject("Must provide key") }
        let url = getServerUrl(call)
        if url != nil {
            let jar = HTTPCookieStorage.shared

            let cookie = jar.cookies(for: url!)?.first(where: { (cookie) -> Bool in
                return cookie.name == key
            })

            if cookie != nil {
                jar.deleteCookie(cookie!)
            }

            call.resolve()
        }
    }

    @objc func clearCookies(_ call: CAPPluginCall) {
        let url = getServerUrl(call)
        if url != nil {
            let jar = HTTPCookieStorage.shared
            jar.cookies(for: url!)?.forEach({ (cookie) in jar.deleteCookie(cookie) })
            call.resolve()
        }
    }
}
