import Foundation

import Result

import JacKit
fileprivate let jack = Jack.fileScopeInstance().setLevel(.verbose)


extension Weibo {
  
  public class SignInResult: BaseSignInResult, SignInResultType {

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

  // used in login and constructing sharing request
  var authorizationRequest: WBAuthorizeRequest {
    let request = WBAuthorizeRequest()
    request.redirectURI = "https://api.weibo.com/oauth2/default.html"
    request.scope = "all"
    request.shouldShowWebViewForAuthIfCannotSSO = true // disable H5 signIn
    request.shouldOpenWeiboAppInstallPageIfNotInstalled = true
    return request
  }

  public static func signIn(completion: @escaping SignInCompletion) {
    Weibo.shared._signIn(completion: completion)
  }

  private func _signIn(completion: @escaping SignInCompletion) {
    begin(.login(completion: completion))
    WeiboSDK.send(authorizationRequest)
  }

  func _getUserInfo(accessToken: String, userID: String, completion block: @escaping ([String: Any]?, SocialKitError?) -> ()) {

    let baseURLString = "https://api.weibo.com/2/users/show.json"
    guard var urlcmp = URLComponents(string: baseURLString) else {
      end(with: .signIn(result: nil, error: .api(reason: "Creating URLComponents from url string (\(baseURLString)) failed")))
      return
    }

    urlcmp.queryItems = [
      URLQueryItem(name: "access_token", value: accessToken),
      URLQueryItem(name: "uid", value: userID),
    ]
    guard let url = urlcmp.url else {
      end(with: .signIn(result: nil, error: .api(reason: "Appending query itesms to base URL string failed")))
      return
    }

    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    let task = session.dataTask(with: url) { data, response, error in
      guard error == nil else {
        block(nil, SocialKitError.send(reason: "network error, \(error!)"))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        block(nil, SocialKitError.send(reason: "URL loading error, casting to HTTPURLResponse failed"))
        return
      }

      guard 200..<300 ~= httpResponse.statusCode else {
        let code = httpResponse.statusCode
        let text = HTTPURLResponse.localizedString(forStatusCode: code)
        block(nil, SocialKitError.send(reason: "URL loading error, unexpected status code \(code) - \(text)"))
        return
      }

      guard let data = data else {
        block(nil, SocialKitError.send(reason: "URL loading error, no data received"))
        return
      }

      do {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
          block(json, nil)
        } else {
          block(nil, SocialKitError.api(reason: "casting deserialized object to `[String: Any]` failed."))
        }
      } catch {
        let e = SocialKitError.api(reason: "deserializing response JSON data failed, \(error)")
        block(nil, e)
      }
    }

    task.resume()
  }

}
