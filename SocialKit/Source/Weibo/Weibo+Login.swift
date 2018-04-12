import Foundation

import JacKit
fileprivate let jack = Jack.with(levelOfThisFile: .verbose)

public class WeiboLoginResult: BaseLoginResult, LoginResultType {

  public var nickname: String? {
    return userInfo["screen_name"] as? String
  }

  public var gender: Gender? {
    if let text = userInfo["gender"] as? String {
      switch text {
      case "m": return .male
      case "f": return .female
      default: return nil
      }
    } else {
      return nil
    }
  }

  public var avatarURL: URL? {
    for key in ["avatar_large", "profile_image_url"] {
      if let urlString = userInfo[key] as? String, let url = URL(string: urlString) {
        return url
      }
    }
    return nil
  }

  public var location: String? {
    return userInfo["location"] as? String
  }

}

extension Weibo {

  public static func login(completion: @escaping LoginCompletion) {
    Weibo.shared._login(completion: completion)
  }

  private func _login(completion: @escaping LoginCompletion) {
    begin(.login(completion: completion))

    let request = WBAuthorizeRequest()
    request.redirectURI = "https://api.weibo.com/oauth2/default.html"
    request.scope = "all"
    request.shouldShowWebViewForAuthIfCannotSSO = false // disable H5 login
    request.shouldOpenWeiboAppInstallPageIfNotInstalled = true

    WeiboSDK.send(request)
  }

  func _getUserInfo(accessToken: String, userID: String, completion block: @escaping ([String: Any]?, SocialError?) -> ()) {

    let baseURLString = "https://api.weibo.com/2/users/show.json"
    guard var urlcmp = URLComponents(string: baseURLString) else {
      end(with: .login(result: nil, error: .api(reason: "Creating URLComponents from url string (\(baseURLString)) failed")))
      return
    }

    urlcmp.queryItems = [
      URLQueryItem(name: "access_token", value: accessToken),
      URLQueryItem(name: "uid", value: userID),
    ]
    guard let url = urlcmp.url else {
      end(with: .login(result: nil, error: .api(reason: "Appending query itesms to base URL string failed")))
      return
    }

    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    let task = session.dataTask(with: url) { data, response, error in
      guard error == nil else {
        block(nil, SocialError.send(reason: "network error, \(error!)"))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        block(nil, SocialError.send(reason: "URL loading error, casting to HTTPURLResponse failed"))
        return
      }

      guard 200..<300 ~= httpResponse.statusCode else {
        let code = httpResponse.statusCode
        let text = HTTPURLResponse.localizedString(forStatusCode: code)
        block(nil, SocialError.send(reason: "URL loading error, unexpected status code \(code) - \(text)"))
        return
      }

      guard let data = data else {
        block(nil, SocialError.send(reason: "URL loading error, no data received"))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          block(json, nil)
        } else {
          block(nil, SocialError.api(reason: "casting deserialized object to `[String: Any]` failed."))
        }
      } catch {
        let e = SocialError.api(reason: "deserializing response JSON data failed, \(error)")
        block(nil, e)
      }
    }
    
    task.resume()
  }

}
