import SKPhotoBrowser
import UIKit
import Fabric
import Crashlytics
import DrawerController
import SVProgressHUD
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var  star : BigBrotherWatchingYou!
    var window: UIWindow?
    var centerNav : V2EXNavigationController!
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        URLProtocol.registerClass(WebViewImageProtocol.self)
        self.window = UIWindow();
        self.window?.frame=UIScreen.main.bounds;
        self.window?.makeKeyAndVisible();
        let home = HomeViewController()
        centerNav = V2EXNavigationController(rootViewController: home);
        
        
        let leftViewController = LeftViewController();
        let rightViewController = RightViewController();
        let drawerController = Drawer(centerNav!, leftViewController, rightViewController)
        star = BigBrotherWatchingYou()
        star.centerNavigation = centerNav
        star.drawerController = drawerController
        star.centerViewController = home
        self.window?.rootViewController = drawerController;
        self.window?.thmemChangedHandler = {[weak self] (style) -> Void in
            self?.window?.backgroundColor = V2EXColor.colors.v2_backgroundColor;
            drawerController.view.backgroundColor = V2EXColor.colors.v2_backgroundColor
        }
        #if DEBUG
            let fpsLabel = V2FPSLabel(frame: CGRect(x: 15, y: SCREEN_HEIGHT-40,width: 55,height: 20));
            self.window?.addSubview(fpsLabel);
        #else
        #endif
        
        SVProgressHUD.setForegroundColor(UIColor(white: 1, alpha: 1))
        SVProgressHUD.setBackgroundColor(UIColor(white: 0.15, alpha: 0.85))
        SVProgressHUD.setDefaultMaskType(.none)
        
        /**
        DEBUG 模式下不统计任何信息，如果你需要使用Crashlytics ，请自行申请账号替换我的Key
        */
        #if DEBUG
        #else
            Fabric.with([Crashlytics.self])
        #endif

        return true
    }
}
class Drawer : DrawerController{
    init( _ centerViewController: UIViewController!, _ leftDrawerViewController: UIViewController, _ rightDrawerViewController: UIViewController) {
        super.init(centerViewController: centerViewController, leftDrawerViewController: leftDrawerViewController, rightDrawerViewController: rightDrawerViewController)
        let drawerController = self
        drawerController.maximumLeftDrawerWidth=230;
        drawerController.maximumRightDrawerWidth = (rightDrawerViewController as! RightViewController).maximumRightDrawerWidth()
        drawerController.openDrawerGestureModeMask=OpenDrawerGestureMode.panningCenterView
        drawerController.closeDrawerGestureModeMask=CloseDrawerGestureMode.all;

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class BigBrotherWatchingYou : UIResponder{
    var centerNavigation :V2EXNavigationController!
    var drawerController : DrawerController!
    var centerViewController : HomeViewController!
    override init() {
        super.init()
        let a : [String:Selector] = [
            "openTopicDetail1":#selector(openTopicDetail1),
            "openTopicDetail":#selector(openTopicDetail),
            "openLeftDrawer":#selector(openLeftDrawer),
            "openRightDrawer":#selector(openRightDrawer),
            "closeDrawer":#selector(closeDrawer),
            "openNodeTopicList":#selector(openNodeTopicList),
            "relevantComment":#selector(relevantComment),
            "replyComment":#selector(replyComment),
            "replyTopic":#selector(replyTopic),
            "openAccountsManager":#selector(openAccountsManager),
            "PanningGestureDisable":#selector(PanningGestureDisable),
            "PanningGestureEnable":#selector(PanningGestureEnable),
            "ChangeTab":#selector(ChangeTab),
            "presentTwoFAViewController":#selector(presentTwoFAViewController),
            "pushMemberViewController":#selector(pushMemberViewController),
            "presentLoginViewController":#selector(presentLoginViewController),
            "pushNotificationsViewController":#selector(pushNotificationsViewController),
            "pushFavoritesViewController":#selector(pushFavoritesViewController),
            "pushNodesViewController":#selector(pushNodesViewController),
            "pushMoreViewController":#selector(pushMoreViewController),
            "pushMyCenterViewController":#selector(pushMyCenterViewController),
            "pushSettingsTableViewController":#selector(pushSettingsTableViewController),
            "pushPodsTableViewController":#selector(pushPodsTableViewController),
//            "presentV2PhotoBrowser":#selector(presentV2PhotoBrowser),
            "pushV2WebViewViewController":#selector(pushV2WebViewViewController),
            "presentPhotoBrower":#selector(presentPhotoBrower),
        ]
        for (key, value) in  a {
//            NotificationCenter.default.addObserver(self, selector: value, name: Notification.Name(key), object: nil)
            Msg.observe(self, value, key)
        }
    }
    func presentPhotoBrower(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let url = arr[0] as! String
        var images = [SKPhoto]()
        let photo = SKPhoto.photoWithImageURL(url)// add some UIImage
        images.append(photo)
        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(0)
        self.centerNavigation.pushViewController(browser, animated: true)
    }
    func pushV2WebViewViewController(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let url = arr[0] as! String
        let controller = V2WebViewViewController(url: url)
        self.centerNavigation.pushViewController(controller, animated: true)
    }
//    func presentV2PhotoBrowser(_ obj : NSNotification){
//        let arr = obj.object as! NSArray
//        let vc = arr[0] as! TopicDetailWebViewContentCell
//        var index = 0
//        if arr.count == 2 {
//            index = arr[0] as! Int
//        }
//        let photoBrowser = V2PhotoBrowser(delegate: vc)
//        photoBrowser.currentPageIndex = index;
//        self.centerNavigation.present(photoBrowser, animated: true, completion: nil)
//    }
    func pushPodsTableViewController(_ obj : NSNotification){
        centerNavigation?.pushViewController(PodsTableViewController(), animated: true)
    }
    func pushSettingsTableViewController(_ obj : NSNotification){
        centerNavigation?.pushViewController(SettingsTableViewController(), animated: true)
    }
    func pushNotificationsViewController(_ obj : NSNotification){
        let notificationsViewController = NotificationsViewController()
        centerNavigation?.pushViewController(notificationsViewController, animated: true)
    }
    func pushFavoritesViewController(_ obj : NSNotification){
        let favoritesViewController = FavoritesViewController()
        centerNavigation?.pushViewController(favoritesViewController, animated: true)
    }
    func pushNodesViewController(_ obj : NSNotification){
        let nodesViewController = NodesViewController()
        centerNavigation?.pushViewController(nodesViewController, animated: true)
    }
    func pushMoreViewController(_ obj : NSNotification){
        let moreViewController = MoreViewController()
        centerNavigation?.pushViewController(moreViewController, animated: true)
    }
    func pushMyCenterViewController(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let username = arr[0] as! String
        let memberViewController = MyCenterViewController()
        memberViewController.username = username
        centerNavigation?.pushViewController(memberViewController, animated: true)
        Msg.send("closeDrawer")
    }
    func presentLoginViewController(_ obj : NSNotification){
        let loginViewController = LoginViewController()
        centerNavigation?.present(loginViewController, animated: true, completion: nil);
    }
    func pushMemberViewController(_ obj : NSNotification){
            let arr = obj.object as! NSArray
            let username = arr[0] as! String
            let memberViewController = MemberViewController()
            memberViewController.username = username
            centerNavigation?.pushViewController(memberViewController, animated: true)
    }
   
    
    func presentTwoFAViewController(_ obj : NSNotification){
        let twoFaViewController = TwoFAViewController()
        centerNavigation?.present(twoFaViewController, animated: true, completion: nil);
    }
    func ChangeTab(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let nodeTab = arr[0] as! String
        centerViewController.tab = nodeTab
        centerViewController.refreshPage()
    }
    func closeDrawer(_ obj : NSNotification){
        drawerController?.closeDrawer(animated: true, completion: nil)
    }
    func openTopicDetail(_ obj : NSNotification){
        print(obj)
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let c = arr[1] as! ((String) -> Void)
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        topicDetailController.ignoreTopicHandler = c
        self.centerNavigation?.pushViewController(topicDetailController, animated: true)
    }
    func openTopicDetail1(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let id = arr[0] as! String
        let topicDetailController = TopicDetailViewController();
        topicDetailController.topicId = id ;
        self.centerNavigation?.pushViewController(topicDetailController, animated: true)
    }
    func replyComment(_ obj : NSNotification) {
        let arr = obj.object as! NSArray
        // viewControler,username ,model
        let viewControler = arr[0] as! UIViewController
        let username = arr[1] as! String
        let model = arr[2] as! TopicDetailModel
        let replyViewController = ReplyingViewController()
        replyViewController.atSomeone = "@" + username + " "
        replyViewController.topicModel = model
        let nav = V2EXNavigationController(rootViewController:replyViewController)
        viewControler.navigationController?.present(nav, animated: true, completion:nil)
    }
    func openNodeTopicList(_ obj : NSNotification){
        let node = NodeModel()
        let arr = obj.object as! NSArray
        node.nodeId = arr[0] as? String
        node.nodeName = arr[1] as? String
        let controller = NodeTopicListViewController()
        controller.node = node
        self.centerNavigation?.pushViewController(controller, animated: true)
    }
    func openAccountsManager(_ obj : NSNotification){
        self.centerNavigation?.pushViewController(AccountsManagerViewController(), animated: true)
    }
    func relevantComment(_ obj : NSNotification){
        //UIViewController ,UIViewController, [TopicCommentModel]
        let arr = obj.object as! NSArray
//        let v1 = arr[0] as! UIViewController
        let tc = arr[1] as! [TopicCommentModel]
        let v2 = RelevantCommentsViewController()
        v2.commentsArray = tc 
//        v1.present(v2, animated: true, completion: nil)
        self.centerNavigation.pushViewController(v2, animated: true)
    }
    func replyTopic(_ obj : NSNotification){
        let arr = obj.object as! NSArray
        let model = arr[0] as! TopicDetailModel
        let n = arr[1] as! UINavigationController
        User.shared.ensureLoginWithHandler {
            let replyViewController = ReplyingViewController()
            replyViewController.topicModel = model
            let nav = V2EXNavigationController(rootViewController:replyViewController)
            n.present(nav, animated: true, completion:nil)
        }
    }
    func openLeftDrawer(_ obj : NSNotification){
        drawerController?.toggleLeftDrawerSide(animated: true, completion: nil)
    }
    func openRightDrawer(_ obj : NSNotification){
        drawerController?.toggleRightDrawerSide(animated: true, completion: nil)
    }
    func PanningGestureDisable(_ obj : NSNotification){
        drawerController?.openDrawerGestureModeMask = []
    }
    func PanningGestureEnable(_ obj : NSNotification){
        drawerController?.openDrawerGestureModeMask = .panningCenterView
    }
}
//
//  WebViewImageProtocol.swift
//  V2ex-Swift
//
//  Created by huangfeng on 16/10/25.
//  Copyright © 2016年 Fin. All rights reserved.
//

import UIKit
import Kingfisher
fileprivate let WebviewImageProtocolHandledKey = "WebviewImageProtocolHandledKey"

class WebViewImageProtocol: URLProtocol ,URLSessionDataDelegate {
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var imageData: Data?
    
    override class func canInit(with request: URLRequest) -> Bool{
        print( request.url)
        guard let pathExtension = request.url?.pathExtension else{
            return false
        }
        if ["jpg","jpeg","png","gif"].contains(pathExtension.lowercased()) {
            if let tag = self.property(forKey: WebviewImageProtocolHandledKey, in: request) as? Bool , tag == true {
                return false
            }
            return true
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest{
        return request
    }
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        let resource = ImageResource(downloadURL: self.request.url!)
        let data = try? Data(contentsOf:URL(fileURLWithPath: KingfisherManager.shared.cache.cachePath(forKey: resource.cacheKey)))
        if let data = data {
            //在磁盘上找到Kingfisher的缓存，则直接使用缓存
            var mimeType = data.contentTypeForImageData()
            mimeType.append(";charset=UTF-8")
            let header = ["Content-Type": mimeType
                ,"Content-Length": String(data.count)]
            let response = HTTPURLResponse(url: self.request.url!, statusCode: 200, httpVersion: "1.1", headerFields: header)!
            
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
        else{
            //没找到图片则下载
            guard let newRequest = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {return}
            WebViewImageProtocol.setProperty(true, forKey: WebviewImageProtocolHandledKey, in: newRequest)
            
            self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            self.dataTask = self.session?.dataTask(with:newRequest as URLRequest)
            self.dataTask?.resume()
        }
    }
    override func stopLoading() {
        self.dataTask?.cancel()
        self.dataTask = nil
        self.imageData = nil
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
        if self.imageData == nil {
            self.imageData = data
        }
        else{
            self.imageData!.append(data)
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.client?.urlProtocol(self, didFailWithError: error)
        }
        else{
            self.client?.urlProtocolDidFinishLoading(self)
            
            let resource = ImageResource(downloadURL: self.request.url!)
            guard let imageData = self.imageData else { return }
            //保存图片到Kingfisher
            guard  let image = DefaultCacheSerializer.default.image(with: imageData, options: nil) else { return }
            KingfisherManager.shared.cache.store(image, original: imageData, forKey: resource.cacheKey,  toDisk: true, completionHandler: nil)
        }
    }
}

fileprivate extension Data {
    func contentTypeForImageData() -> String {
        var c:UInt8 = 0
        self.copyBytes(to: &c, count: MemoryLayout<UInt8>.size * 1)
        switch c {
        case 0xFF:
            return "image/jpeg";
        case 0x89:
            return "image/png";
        case 0x47:
            return "image/gif";
        default:
            return ""
        }
    }
}
